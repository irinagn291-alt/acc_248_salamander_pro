import SwiftUI

/// Role: Pass. Settings sheet. Catalog credit, contact URL, onboarding replay, marks, shelf counts, and a confirmed data reset.
struct SettingsView: View {
    @Environment(PassDesk.self) private var desk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Group {
                if desk.document.cookbookItems.isEmpty, desk.document.tickets.isEmpty, desk.settingsFault == nil {
                    emptyPlate
                } else {
                    populated
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PassInk.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        desk.dismissSheet()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(minWidth: PassSpace.hit, minHeight: PassSpace.hit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PassPressStyle())
                    .accessibilityLabel("Close")
                }
            }
            .confirmationDialog(
                "Reset the pass",
                isPresented: $confirmReset,
                titleVisibility: .visible
            ) {
                Button("Reset all data", role: .destructive) {
                    Task { await desk.resetAll() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes tonight's ticket, the cookbook, and service marks on this device.")
            }
        }
        .tint(PassInk.accent)
        .preferredColorScheme(.dark)
    }

    private var emptyPlate: some View {
        VStack(spacing: 0) {
            PassVacant(
                art: "slm_EmptyList",
                headline: "This device holds no tickets.",
                line: "Replay the pass notes or search the catalog. Reset stays available after you cook.",
                verb: "Search the catalog",
                action: { desk.present(.search) }
            )
            actions
                .padding(.horizontal, PassSpace.outer)
                .padding(.bottom, PassSpace.card)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(PassInk.background)
    }

    private var populated: some View {
        GeometryReader { geo in
            ScrollView {
                settingsBoard
                    .padding(.horizontal, PassSpace.outer)
                    .padding(.vertical, PassSpace.card)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassInk.background)
    }

    private var settingsBoard: some View {
        VStack(alignment: .leading, spacing: PassSpace.card) {
            Text("Pass notes")
                .font(PassType.font(.title, size: typeSize))
                .foregroundStyle(PassInk.ink)
            Text(statusLine)
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let fault = desk.settingsFault {
                VStack(alignment: .leading, spacing: PassSpace.inner) {
                    PassRule()
                    Text(fault)
                        .font(PassType.font(.body, size: typeSize))
                        .foregroundStyle(PassInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Try again") { Task { await desk.retryBoot() } }
                        .buttonStyle(PassQuietStyle())
                }
            }
            actions
            marksLedger
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Button("Replay the pass notes") {
                Task { await desk.replayOnboarding() }
            }
            .buttonStyle(PassQuietStyle())
            .accessibilityHint("Shows the opening pages again.")

            Button("TheMealDB catalog") {
                desk.openCatalog()
            }
            .buttonStyle(PassQuietStyle())
            .accessibilityHint("Opens the catalog source.")

            Text("Search dishes come from TheMealDB. That catalog is the source for names, bowls, and walks.")
                .font(PassType.font(.caption, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                desk.openContact()
            } label: {
                VStack(alignment: .leading, spacing: PassSpace.inner) {
                    Text("Contact the pass")
                    Text(verbatim: PassClient.contactURL.absoluteString)
                        .font(PassType.font(.caption, size: typeSize))
                        .foregroundStyle(PassInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PassQuietStyle())
            .accessibilityLabel("Contact the pass")
            .accessibilityValue(PassClient.contactURL.absoluteString)
            .accessibilityHint("Opens the contact page.")

            Button("Reset all data") {
                confirmReset = true
            }
            .buttonStyle(PassRetractStyle())
            .accessibilityHint("Removes tickets, cookbook recipes, and service marks after a confirmation.")
        }
    }

    /// Marks and shelf counts occupy leftover height so Settings is not a header plus void.
    private var marksLedger: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text("Marks on this pass")
                .font(PassType.font(.headline, size: typeSize))
                .foregroundStyle(PassInk.ink)
            figureRow("Recipes on the shelf", desk.document.cookbookItems.count)
            figureRow("Fire marks", desk.document.fireMarks.count)
            figureRow("Walk marks", desk.document.walkMarks.count)
            figureRow("Service marks", desk.document.serviceMarks.count)
            PassRule()
            shelfBlock
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            platedBlock
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var shelfBlock: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text("Cookbook shelf")
                .font(PassType.font(.headline, size: typeSize))
                .foregroundStyle(PassInk.ink)
            PassRule()
            if desk.document.cookbookItems.isEmpty {
                Text("The shelf has no saved recipes.")
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ForEach(desk.document.cookbookItems) { item in
                    HStack(alignment: .firstTextBaseline, spacing: PassSpace.card) {
                        Text(item.name)
                            .font(PassType.font(.body, size: typeSize))
                            .foregroundStyle(PassInk.ink)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(PassStamp.day(item.savedDaykey))
                            .font(PassType.font(.caption, size: typeSize))
                            .foregroundStyle(PassInk.muted)
                            .layoutPriority(1)
                    }
                    .frame(minHeight: PassSpace.hit, maxHeight: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    PassRule()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var platedBlock: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text("Plated dishes")
                .font(PassType.font(.headline, size: typeSize))
                .foregroundStyle(PassInk.ink)
            PassRule()
            if desk.document.serviceMarks.isEmpty {
                Text("No dishes have plated yet.")
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ForEach(desk.document.serviceMarks.reversed()) { mark in
                    HStack(alignment: .firstTextBaseline, spacing: PassSpace.card) {
                        Text(mark.name)
                            .font(PassType.font(.body, size: typeSize))
                            .foregroundStyle(PassInk.ink)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(PassStamp.day(mark.daykey))
                            .font(PassType.font(.caption, size: typeSize))
                            .foregroundStyle(PassInk.muted)
                            .layoutPriority(1)
                    }
                    .frame(minHeight: PassSpace.hit, maxHeight: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    PassRule()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var statusLine: String {
        let books = PassFigures.integer(desk.document.cookbookItems.count)
        let marks = PassFigures.integer(desk.document.serviceMarks.count)
        let fires = PassFigures.integer(desk.document.fireMarks.count)
        let walks = PassFigures.integer(desk.document.walkMarks.count)
        return "\(books) recipes on the shelf. \(marks) service marks. \(fires) fire marks. \(walks) walk marks."
    }

    private func figureRow(_ title: String, _ value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: PassSpace.card) {
            Text(title)
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(PassFigures.integer(value))
                .font(PassType.font(.headline, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .layoutPriority(1)
        }
        .frame(minHeight: PassSpace.hit, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
