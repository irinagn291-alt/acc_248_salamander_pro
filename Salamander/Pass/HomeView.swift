import SwiftUI

/// Role: Pass. Home is tonight's ticket. Masthead, a column, a pull quote. Bowls and walks fuse here. Walk is the live verb.
struct HomeView: View {
    @Environment(PassDesk.self) private var desk
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            masthead
            if let fault = desk.homeFault {
                faultBanner(fault)
            }
            Group {
                if let ticket = desk.document.openTicket {
                    CookView(ticket: ticket)
                } else {
                    vacantPass
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            chrome
        }
        .background(PassInk.background.ignoresSafeArea())
        .animation(PassMotion.crossfade(reduceMotion), value: desk.document.openTicket?.phase)
        .animation(PassMotion.crossfade(reduceMotion), value: desk.document.openTicket?.sheet.id)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Image("slm_HeaderDecor")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: PassSpace.step(10), alignment: .leading)
                .accessibilityHidden(true)
            if let ticket = desk.document.openTicket {
                Text(ticket.sheet.name)
                    .font(PassType.font(.display, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(PassCopy.phase(ticket.phase))
                    .font(PassType.font(.caption, size: typeSize))
                    .foregroundStyle(PassInk.muted)
                Text(jobLine(for: ticket))
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let plated = desk.platedLine {
                Text("The pass is clear.")
                    .font(PassType.font(.display, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .lineLimit(2)
                Text(plated)
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Tonight's ticket")
                    .font(PassType.font(.display, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .lineLimit(2)
                Text("Open a cookbook recipe so mise bowls and fire walks can share this pass.")
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, PassSpace.outer)
        .padding(.top, PassSpace.inner)
        .padding(.bottom, PassSpace.card)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var vacantPass: some View {
        let art = desk.platedLine == nil ? "slm_EmptyHome" : "slm_SuccessMark"
        let headline = desk.platedLine == nil ? "The pass is waiting." : "Service is marked."
        let line = desk.platedLine
            ?? "Open a saved recipe onto tonight's ticket. Mise bowls file first. Then the walks stay awake."
        let verb = desk.platedLine == nil ? "Open cookbook" : "Open another recipe"
        PassVacant(
            art: art,
            headline: headline,
            line: line,
            verb: verb,
            action: { desk.present(.cookbook) }
        )
    }

    private var chrome: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            PassRule()
            HStack(alignment: .center, spacing: PassSpace.inner) {
                Button {
                    desk.present(.search)
                } label: {
                    Image(systemName: "magnifyingglass")
                        .frame(minWidth: PassSpace.hit, minHeight: PassSpace.hit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PassChipStyle())
                .accessibilityLabel("Search the catalog")

                Button("Cookbook") { desk.present(.cookbook) }
                    .buttonStyle(PassChipStyle())
                    .accessibilityLabel("Open the cookbook")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center, spacing: PassSpace.inner) {
                Button("Fire rule") { desk.presentFireRule() }
                    .buttonStyle(PassChipStyle())
                    .accessibilityLabel("Open mise then fire")

                Button {
                    desk.present(.settings)
                } label: {
                    Image(systemName: "gearshape")
                        .frame(minWidth: PassSpace.hit, minHeight: PassSpace.hit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PassChipStyle())
                .accessibilityLabel("Open settings")

                Text(platedCount)
                    .font(PassType.font(.caption, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .frame(maxWidth: .infinity, minHeight: PassSpace.hit, alignment: .trailing)
                    .accessibilityLabel(platedCount)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, PassSpace.outer)
        .padding(.top, PassSpace.inner)
        .padding(.bottom, PassSpace.card)
        .background(PassInk.background)
    }

    private var platedCount: String {
        let count = PassFigures.integer(desk.document.serviceMarks.count)
        return "\(count) plated"
    }

    private func faultBanner(_ line: String) -> some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            PassRule()
            Text(line)
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("Dismiss") { desk.clearCookFault() }
                .buttonStyle(PassQuietStyle())
        }
        .padding(.horizontal, PassSpace.outer)
        .padding(.bottom, PassSpace.card)
    }

    private func jobLine(for ticket: Ticket) -> String {
        switch ticket {
        case .mise:
            return "File every mise bowl. The last bowl writes a fire mark and the walks wake."
        case .firing:
            return "Tap Walk to file this fire line. The screen stays awake until the last walk."
        case .plated:
            return "This ticket has left the pass."
        }
    }
}
