import Observation
import SwiftUI
import UIKit

/// Role: Pass. Presentation fold over PassStore. Views call fileBowl, fileWalk, retract, save, and open. They never touch UserDefaults.
@Observable
@MainActor
final class PassDesk {
    var document: PassDocument = .empty
    var notice: PassNotice?
    var sheet: PassSheet?
    var fireRuleOpen = false
    var showOnboarding = false
    var isReady = false
    var bootFault: String?
    var homeFault: String?
    var searchFault: String?
    var bookFault: String?
    var settingsFault: String?
    var cookFault: String?
    var platedLine: String?
    var seekQuery = ""
    var seekRows: [Recipe] = []
    var seekFromShelf = false
    var seekBusy = false
    var verbBusy = false
    var walkLoading = false
    var retractLoading = false
    var saveLoading = false
    var pendingBowl: UUID?
    var commitFlash = false
    var now = Date()

    @ObservationIgnored private var store: PassStore?
    @ObservationIgnored private var latchConsumed = false
    @ObservationIgnored private var booted = false
    @ObservationIgnored private var seekGeneration = 0
    @ObservationIgnored private var spinnerTask: Task<Void, Never>?
    @ObservationIgnored private var flashTask: Task<Void, Never>?
    @ObservationIgnored private var seekListen: Task<Void, Never>?

    var calendar: Calendar { .current }

    func boot() async {
        if booted, store != nil {
            isReady = true
            applyIdle()
            return
        }
        bootFault = nil
        do {
            let folder = try PassStore.applicationSupportDirectory()
            let vault = PassStore(directory: folder)
            store = vault
            try await plantSeed(in: vault)
            let loaded = await vault.load(now: now, calendar: calendar)
            document = loaded.document
            notice = loaded.notice
            applyNotice(loaded.notice)
            booted = true
            isReady = true
            showOnboarding = !document.onboardingComplete
            applyIdle()
            if document.onboardingComplete {
                applyLatch()
            }
        } catch {
            bootFault = PassCopy.bootFailed()
            isReady = false
        }
    }

    func retryBoot() async {
        booted = false
        store = nil
        await boot()
    }

    func handle(phase: ScenePhase) async {
        switch phase {
        case .inactive, .background:
            UIApplication.shared.isIdleTimerDisabled = false
            await flushQuietly()
        case .active:
            now = Date()
            applyIdle()
        @unknown default:
            await flushQuietly()
        }
    }

    func tickDay() {
        now = Date()
    }

    func present(_ surface: PassSheet) {
        sheet = surface
    }

    func dismissSheet() {
        sheet = nil
    }

    func presentFireRule() {
        fireRuleOpen = true
    }

    func finishOnboarding() async {
        guard let store else { return }
        document = await store.setOnboardingComplete(true)
        await flushQuietly()
        showOnboarding = false
        applyIdle()
        applyLatch()
    }

    func replayOnboarding() async {
        guard let store else { return }
        sheet = nil
        fireRuleOpen = false
        document = await store.setOnboardingComplete(false)
        await flushQuietly()
        showOnboarding = true
    }

    func fileBowl(_ bowlID: UUID) async {
        guard let store, !verbBusy else { return }
        verbBusy = true
        pendingBowl = bowlID
        cookFault = nil
        do {
            document = try await store.fileBowl(bowlID, now: now, calendar: calendar)
            applyIdle()
            pulse()
            if document.openTicket?.phase == .firing {
                platedLine = nil
            }
        } catch let fault as PassFault {
            cookFault = PassCopy.fault(fault)
            homeFault = cookFault
        } catch {
            cookFault = PassCopy.saveFailed()
            homeFault = cookFault
        }
        pendingBowl = nil
        verbBusy = false
        await noteWriteError()
    }

    func fileWalk() async {
        guard let store, !verbBusy else { return }
        verbBusy = true
        let spin = armSpinner { self.walkLoading = true }
        cookFault = nil
        let wasOpen = document.openTicket?.sheet.id
        do {
            document = try await store.fileWalk(now: now, calendar: calendar)
            applyIdle()
            pulse()
            if document.openTicket == nil, wasOpen != nil {
                platedLine = "The dish is plated. Service is marked. Sleep is restored."
            }
        } catch let fault as PassFault {
            cookFault = PassCopy.fault(fault)
            homeFault = cookFault
        } catch {
            cookFault = PassCopy.saveFailed()
            homeFault = cookFault
        }
        spin.cancel()
        walkLoading = false
        verbBusy = false
        await noteWriteError()
    }

    func retract() async {
        guard let store, !verbBusy else { return }
        verbBusy = true
        let spin = armSpinner { self.retractLoading = true }
        cookFault = nil
        do {
            document = try await store.retract()
            applyIdle()
            platedLine = nil
            pulse()
        } catch let fault as PassFault {
            cookFault = PassCopy.fault(fault)
            homeFault = cookFault
        } catch {
            cookFault = PassCopy.saveFailed()
            homeFault = cookFault
        }
        spin.cancel()
        retractLoading = false
        verbBusy = false
        await noteWriteError()
    }

    func save(_ recipe: Recipe) async {
        guard let store, !saveLoading else { return }
        saveLoading = true
        searchFault = nil
        do {
            document = try await store.saveRecipe(recipe, now: now, calendar: calendar)
            pulse()
        } catch {
            searchFault = PassCopy.saveFailed()
        }
        saveLoading = false
        await noteWriteError()
    }

    func openBook(itemID: UUID) async {
        guard let store, !verbBusy else { return }
        verbBusy = true
        bookFault = nil
        do {
            document = try await store.openFromCookbook(itemID: itemID, now: now, calendar: calendar)
            sheet = nil
            platedLine = nil
            applyIdle()
            pulse()
        } catch let fault as PassFault {
            bookFault = PassCopy.fault(fault)
        } catch {
            bookFault = PassCopy.saveFailed()
        }
        verbBusy = false
        await noteWriteError()
    }

    func reviseSeek(_ query: String) {
        seekQuery = query
        seekGeneration += 1
        let generation = seekGeneration
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        seekListen?.cancel()
        seekListen = Task { await runSeek(trimmed, generation: generation) }
    }

    func retrySeek() async {
        seekGeneration += 1
        await runSeek(seekQuery.trimmingCharacters(in: .whitespacesAndNewlines), generation: seekGeneration)
    }

    func resetAll() async {
        guard let store else { return }
        do {
            try await store.resetAllData()
            document = .empty
            notice = nil
            homeFault = nil
            searchFault = nil
            bookFault = nil
            cookFault = nil
            platedLine = nil
            seekQuery = ""
            seekRows = []
            seekFromShelf = false
            settingsFault = nil
            applyIdle()
            showOnboarding = true
            sheet = nil
            fireRuleOpen = false
        } catch {
            settingsFault = PassCopy.saveFailed()
        }
    }

    func clearCookFault() {
        cookFault = nil
        homeFault = nil
    }

    func clearBookFault() {
        bookFault = nil
    }

    func clearSearchFault() {
        searchFault = nil
    }

    func openContact() {
        UIApplication.shared.open(PassClient.contactURL)
    }

    func openCatalog() {
        UIApplication.shared.open(PassClient.catalogHomeURL)
    }

    private func runSeek(_ query: String, generation: Int) async {
        guard let store else { return }
        if query.isEmpty {
            if generation == seekGeneration {
                seekRows = []
                seekFromShelf = false
                seekBusy = false
                searchFault = nil
            }
            return
        }
        let spin = armSpinner {
            if generation == self.seekGeneration {
                self.seekBusy = true
            }
        }
        searchFault = nil
        let rows = await store.seek(query: query, page: 1, pageSize: 20)
        spin.cancel()
        guard !Task.isCancelled, generation == seekGeneration else { return }
        document = await store.snapshot()
        seekBusy = false
        if rows.isEmpty {
            let local = document.localMatches(query: query, shelf: PassShelf.bundled)
            if local.isEmpty {
                seekRows = PassShelf.bundled
            } else {
                seekRows = local
            }
            seekFromShelf = true
            searchFault = "The catalog did not answer. These dishes are already on the shelf."
        } else {
            seekRows = rows
            seekFromShelf = false
        }
    }

    private func plantSeed(in store: PassStore) async throws {
        #if targetEnvironment(simulator)
        _ = try await store.seedDemoIfNeeded(permit: true, now: now, calendar: calendar)
        #else
        _ = try await store.seedDemoIfNeeded(permit: false, now: now, calendar: calendar)
        #endif
    }

    private func applyLatch() {
        guard document.onboardingComplete, !showOnboarding else { return }
        guard let pane = PassLatch.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboardingComplete: true,
            consumed: &latchConsumed
        ) else { return }
        sheet = PassSheet.from(pane.surface)
        fireRuleOpen = false
    }

    private func applyIdle() {
        UIApplication.shared.isIdleTimerDisabled = document.holdsIdle
    }

    private func applyNotice(_ value: PassNotice?) {
        guard let value else { return }
        let line = PassCopy.notice(value)
        homeFault = line
        settingsFault = line
    }

    private func pulse() {
        PassPulse.commit()
        commitFlash = true
        flashTask?.cancel()
        flashTask = Task { @MainActor in
            let nanos = UInt64(PassMotion.flashSeconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
            guard !Task.isCancelled else { return }
            commitFlash = false
        }
    }

    private func armSpinner(_ apply: @escaping @MainActor () -> Void) -> Task<Void, Never> {
        spinnerTask?.cancel()
        let task = Task { @MainActor in
            try? await Task.sleep(nanoseconds: PassMotion.spinnerNanos)
            guard !Task.isCancelled else { return }
            apply()
        }
        spinnerTask = task
        return task
    }

    private func flushQuietly() async {
        do {
            try await store?.flush()
        } catch {
            settingsFault = PassCopy.saveFailed()
            homeFault = PassCopy.saveFailed()
        }
        await noteWriteError()
    }

    private func noteWriteError() async {
        guard let store else { return }
        if await store.lastWriteError != nil {
            settingsFault = PassCopy.saveFailed()
        }
    }
}
