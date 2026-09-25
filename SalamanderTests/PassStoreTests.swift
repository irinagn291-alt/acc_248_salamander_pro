import XCTest
@testable import Salamander

final class PassStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar { SalamanderGMT.calendar }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "slm.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    func test_roundTripReloadPreservesFiringWalkAndService() async throws {
        let now = SalamanderGMT.instant(2026, 9, 18, hour: 16)
        let store = makeStore()
        _ = try await store.saveRecipe(PassShelf.bundled[0], now: now, calendar: calendar)
        let saved = await store.snapshot()
        let itemID = try XCTUnwrap(saved.cookbookItems.first?.id)
        _ = try await store.openFromCookbook(itemID: itemID, now: now, calendar: calendar)
        let snap = await store.snapshot()
        let ticketID = try XCTUnwrap(snap.openTicket?.sheet.id)
        for bowl in snap.bowls.filter({ $0.ticketID == ticketID }) {
            _ = try await store.fileBowl(bowl.id, now: now, calendar: calendar)
        }
        _ = try await store.fileWalk(now: now, calendar: calendar)
        try await store.flush()

        let relaunched = makeStore()
        let loaded = await relaunched.load(now: now, calendar: calendar)
        XCTAssertNil(loaded.notice)
        XCTAssertEqual(loaded.document.openTicket?.phase, .firing)
        XCTAssertEqual(loaded.document.walkIndex(for: ticketID), 1)
        XCTAssertEqual(loaded.document.fireMarks.count, 1)
        XCTAssertTrue(loaded.document.holdsIdle)
        XCTAssertEqual(loaded.document.currentDaykey, 20260918)
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let now = SalamanderGMT.instant(2026, 9, 18)
        let store = makeStore()
        _ = try await store.saveRecipe(PassShelf.bundled[0], now: now, calendar: calendar)
        let saved = await store.snapshot()
        let itemID = try XCTUnwrap(saved.cookbookItems.first?.id)
        _ = try await store.openFromCookbook(itemID: itemID, now: now, calendar: calendar)
        if let good = defaults.data(forKey: PassKey.snapshot) {
            defaults.set(good, forKey: PassKey.backup)
        }
        let file = directory.appendingPathComponent("pass.json")
        let backup = directory.appendingPathComponent("pass.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: PassKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load(now: now, calendar: calendar)
        XCTAssertEqual(loaded.notice, .restored)
        XCTAssertEqual(loaded.document.cookbookItems.count, 1)
        XCTAssertEqual(loaded.document.tickets.count, 1)
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: PassKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("pass.json"))
        let loaded = await makeStore().load(now: SalamanderGMT.instant(2026, 9, 18), calendar: calendar)
        XCTAssertEqual(loaded.notice, .cleared)
        XCTAssertEqual(loaded.document.tickets, [])
        XCTAssertFalse(loaded.document.onboardingComplete)
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        let now = SalamanderGMT.instant(2026, 9, 18)
        _ = try await store.saveRecipe(PassShelf.bundled[0], now: now, calendar: calendar)
        try await store.resetAllData()
        let loaded = await store.load(now: now, calendar: calendar)
        XCTAssertEqual(loaded.document.tickets, [])
        XCTAssertNil(defaults.data(forKey: PassKey.snapshot))
        XCTAssertNil(defaults.data(forKey: PassKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        let loaded = await makeStore().load(now: SalamanderGMT.instant(2026, 9, 18), calendar: calendar)
        XCTAssertTrue(loaded.document.onboardingComplete)
    }

    func test_seedWritesOnceAndLeavesWalkEnabled() async throws {
        let store = makeStore()
        let now = SalamanderGMT.instant(2026, 9, 18, hour: 10)
        let denied = try await store.seedDemoIfNeeded(permit: false, now: now, calendar: calendar)
        XCTAssertNil(denied)

        let first = try await store.seedDemoIfNeeded(permit: true, now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(permit: true, now: now, calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.canWalk, true)
        XCTAssertEqual(first?.openTicket?.phase, .firing)
        XCTAssertGreaterThanOrEqual(first?.cookbookItems.count ?? 0, 4)
        XCTAssertGreaterThanOrEqual(first?.serviceMarks.count ?? 0, 1)
        XCTAssertTrue(defaults.bool(forKey: PassKey.demo))
        XCTAssertNotNil(defaults.data(forKey: PassKey.snapshot))
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: directory.appendingPathComponent("pass.json").path)
        )
    }

    func test_failedSearchFallsBackToShelf() async throws {
        let courier = ScriptedCourier(results: [
            .failure(URLError(.timedOut)),
            .failure(URLError(.timedOut)),
        ])
        let store = PassStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            client: PassClient(courier: courier),
            quietNanos: 0,
            seekNanos: 0
        )
        _ = try await store.saveRecipe(PassShelf.bundled[0], now: SalamanderGMT.instant(2026, 9, 18), calendar: calendar)
        let rows = await store.seek(query: "salt")
        XCTAssertEqual(rows.first?.id, "53001")
    }

    private func makeStore() -> PassStore {
        PassStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            quietNanos: 0,
            seekNanos: 0
        )
    }
}
