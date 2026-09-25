import SwiftUI

/// Role: Pass. Cookbook sheet. Saved recipes plus ServiceMark history. Opening writes a Ticket as Mise when the pass is free.
struct CookbookView: View {
    @Environment(PassDesk.self) private var desk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            Group {
                if let fault = desk.bookFault, desk.document.cookbookItems.isEmpty {
                    PassVacant(
                        art: "slm_EmptyList",
                        headline: "The cookbook could not open that recipe.",
                        line: fault,
                        verb: "Dismiss",
                        action: { desk.clearBookFault() }
                    )
                } else if desk.document.cookbookItems.isEmpty {
                    PassVacant(
                        art: "slm_EmptyList",
                        headline: "The cookbook is empty.",
                        line: "Search the catalog and save a dish. Opening a saved recipe writes tonight's ticket as mise.",
                        verb: "Search the catalog",
                        action: { desk.present(.search) }
                    )
                } else {
                    populated
                }
            }
            .background(PassInk.background.ignoresSafeArea())
            .navigationTitle("Cookbook")
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
        }
        .tint(PassInk.accent)
        .preferredColorScheme(.dark)
    }

    private var populated: some View {
        List {
            if let fault = desk.bookFault {
                Section {
                    VStack(alignment: .leading, spacing: PassSpace.inner) {
                        Text(fault)
                            .font(PassType.font(.body, size: typeSize))
                            .foregroundStyle(PassInk.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Button("Dismiss") { desk.clearBookFault() }
                            .buttonStyle(PassQuietStyle())
                    }
                    .listRowBackground(PassInk.surface)
                    .listRowSeparatorTint(PassInk.muted)
                }
            }
            Section {
                headerStrip
                    .listRowBackground(PassInk.background)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(
                            top: PassSpace.card,
                            leading: PassSpace.outer,
                            bottom: PassSpace.card,
                            trailing: PassSpace.outer
                        )
                    )
            }
            Section {
                ForEach(desk.document.cookbookItems) { item in
                    bookRow(item)
                        .listRowBackground(PassInk.surface)
                        .listRowSeparatorTint(PassInk.muted)
                        .listRowInsets(
                            EdgeInsets(
                                top: PassSpace.inner,
                                leading: PassSpace.outer,
                                bottom: PassSpace.inner,
                                trailing: PassSpace.outer
                            )
                        )
                }
            }
            Section {
                serviceBlock
                    .listRowBackground(PassInk.background)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        EdgeInsets(
                            top: PassSpace.card,
                            leading: PassSpace.outer,
                            bottom: PassSpace.card,
                            trailing: PassSpace.outer
                        )
                    )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(PassInk.background)
    }

    private var headerStrip: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text("Saved recipes.")
                .font(PassType.font(.title, size: typeSize))
                .foregroundStyle(PassInk.ink)
            Text(countLine)
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .fixedSize(horizontal: false, vertical: true)
            if !desk.document.canOpen {
                Text("Tonight's ticket is still firing. Plate it before opening another recipe.")
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var countLine: String {
        let books = PassFigures.integer(desk.document.cookbookItems.count)
        let plated = PassFigures.integer(desk.document.serviceMarks.count)
        return "\(books) saved. The book counts \(plated) service marks."
    }

    private func bookRow(_ item: CookbookItem) -> some View {
        let recipe = desk.document.recipe(for: item.mealID)
        let bowls = PassFigures.integer(recipe?.bowls.count ?? 0)
        let walks = PassFigures.integer(recipe?.walks.count ?? 0)
        return Button {
            Task { await desk.openBook(itemID: item.id) }
        } label: {
            HStack(alignment: .center, spacing: PassSpace.card) {
                VStack(alignment: .leading, spacing: PassSpace.inner) {
                    Text(item.name)
                        .font(PassType.font(.headline, size: typeSize))
                        .foregroundStyle(PassInk.ink)
                        .lineLimit(1)
                    Text("Saved \(PassStamp.day(item.savedDaykey)). \(bowls) bowls, \(walks) walks.")
                        .font(PassType.font(.caption, size: typeSize))
                        .foregroundStyle(PassInk.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(desk.document.canOpen ? "Open" : "Busy")
                    .font(PassType.font(.caption, size: typeSize))
                    .foregroundStyle(PassInk.muted)
                    .layoutPriority(1)
            }
            .frame(minHeight: PassSpace.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(PassPressStyle())
        .disabled(!desk.document.canOpen || desk.verbBusy)
        .accessibilityLabel("Open \(item.name) onto the pass")
        .accessibilityHint(desk.document.canOpen ? "Writes a ticket as mise." : "The pass is firing.")
    }

    private var serviceBlock: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text("Service marks")
                .font(PassType.font(.headline, size: typeSize))
                .foregroundStyle(PassInk.ink)
            PassRule()
            if desk.document.serviceMarks.isEmpty {
                Text("No dishes have plated yet.")
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
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
                    .frame(minHeight: PassSpace.hit, alignment: .leading)
                    PassRule()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
