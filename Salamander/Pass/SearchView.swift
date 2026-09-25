import SwiftUI

/// Role: Pass. Search sheet. Queries TheMealDB, saves a Recipe into the Cookbook. Empty catalog falls back to the shelf.
struct SearchView: View {
    @Environment(PassDesk.self) private var desk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @FocusState private var fieldFocused: Bool

    var body: some View {
        @Bindable var desk = desk
        NavigationStack {
            Group {
                if desk.seekQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    emptyPlate
                } else if desk.seekBusy && desk.seekRows.isEmpty {
                    loadingPlate
                } else if !desk.seekRows.isEmpty {
                    results
                } else {
                    PassVacant(
                        art: "slm_EmptyList",
                        headline: "No dishes matched.",
                        line: desk.searchFault ?? "Try another name, or open the cookbook shelf.",
                        verb: "Try again",
                        action: { Task { await desk.retrySeek() } }
                    )
                }
            }
            .background(PassInk.background.ignoresSafeArea())
            .navigationTitle("Search")
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

    private var emptyPlate: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PassSpace.card) {
                searchField
                PassVacant(
                    art: "slm_EmptyList",
                    headline: "Name a dish.",
                    line: "Search maps onto TheMealDB. An empty catalog falls back to the local shelf.",
                    verb: "Open cookbook",
                    action: { desk.present(.cookbook) }
                )
                .frame(minHeight: PassSpace.step(40))
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollIndicators(.hidden)
        .background(PassInk.background)
    }

    private var loadingPlate: some View {
        VStack(alignment: .leading, spacing: PassSpace.card) {
            searchField
            VStack(alignment: .leading, spacing: PassSpace.inner) {
                ForEach(0 ..< 4, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous)
                        .fill(PassInk.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: PassRadius.card, style: .continuous)
                                .stroke(PassInk.muted, lineWidth: PassSpace.hairline)
                        )
                        .frame(height: PassSpace.hit)
                        .redacted(reason: .placeholder)
                }
            }
            .padding(.horizontal, PassSpace.outer)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassInk.background)
        .onTapGesture { fieldFocused = false }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchField
            if let fault = desk.searchFault {
                Text(fault)
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .padding(.horizontal, PassSpace.outer)
                    .padding(.bottom, PassSpace.card)
                    .fixedSize(horizontal: false, vertical: true)
            }
            List {
                ForEach(desk.seekRows) { recipe in
                    resultRow(recipe)
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(PassInk.background)
    }

    private var searchField: some View {
        @Bindable var desk = desk
        return TextField("Dish name", text: $desk.seekQuery)
            .font(PassType.font(.body, size: typeSize))
            .foregroundStyle(PassInk.ink)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .focused($fieldFocused)
            .padding(.horizontal, PassSpace.card)
            .frame(minHeight: PassSpace.hit)
            .passLift()
            .padding(.horizontal, PassSpace.outer)
            .padding(.vertical, PassSpace.card)
            .onChange(of: desk.seekQuery) { _, value in
                desk.reviseSeek(value)
            }
            .onSubmit {
                fieldFocused = false
                desk.reviseSeek(desk.seekQuery)
            }
            .accessibilityLabel("Dish name")
    }

    private func resultRow(_ recipe: Recipe) -> some View {
        HStack(alignment: .center, spacing: PassSpace.card) {
            VStack(alignment: .leading, spacing: PassSpace.inner) {
                Text(recipe.name)
                    .font(PassType.font(.headline, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .lineLimit(1)
                Text(meta(recipe))
                    .font(PassType.font(.caption, size: typeSize))
                    .foregroundStyle(PassInk.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button("Save") {
                Task { await desk.save(recipe) }
            }
            .buttonStyle(PassFileStyle(isLoading: desk.saveLoading, isLive: false))
            .fixedSize(horizontal: true, vertical: false)
            .disabled(desk.saveLoading)
            .accessibilityLabel("Save \(recipe.name) into the cookbook")
        }
        .frame(minHeight: PassSpace.hit)
    }

    private func meta(_ recipe: Recipe) -> String {
        let bowls = PassFigures.integer(recipe.bowls.count)
        let walks = PassFigures.integer(recipe.walks.count)
        var parts: [String] = []
        if !recipe.area.isEmpty { parts.append(recipe.area) }
        parts.append("\(bowls) bowls")
        parts.append("\(walks) walks")
        return parts.joined(separator: ", ")
    }
}
