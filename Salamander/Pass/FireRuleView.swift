import SwiftUI

/// Role: Pass. Twist screen for mise-then-fire. Own sheet plus a strip on Home. Idle is held only while Firing.
struct FireRuleView: View {
    @Environment(PassDesk.self) private var desk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        NavigationStack {
            Group {
                if let fault = desk.cookFault {
                    PassVacant(
                        art: "slm_TwistHero",
                        headline: "The iron refused that tap.",
                        line: fault,
                        verb: "Back to the ticket",
                        action: {
                            desk.clearCookFault()
                            desk.fireRuleOpen = false
                            dismiss()
                        }
                    )
                } else if desk.document.openTicket == nil, desk.document.fireMarks.isEmpty {
                    PassVacant(
                        art: "slm_TwistHero",
                        headline: "Mise, then fire.",
                        line: "Bowls file first. The last bowl writes a fire mark, flips the ticket to firing, and holds idle sleep. Walks file the fire. The last walk writes a service mark and sleep returns.",
                        verb: "Open cookbook",
                        action: {
                            desk.fireRuleOpen = false
                            desk.present(.cookbook)
                        }
                    )
                } else {
                    populated
                }
            }
            .background(PassInk.background.ignoresSafeArea())
            .navigationTitle("Mise then fire")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        desk.fireRuleOpen = false
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
        ScrollView {
            VStack(alignment: .leading, spacing: PassSpace.card) {
                Image("slm_TwistHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: PassSpace.step(20))
                    .accessibilityHidden(true)
                Text(headline)
                    .font(PassType.font(.display, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .lineLimit(3)
                Text("Bowls close mise. Walks close the fire. Idle sleep is a derived hold, never a stored switch.")
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                PassRule()
                figureRow("Fire marks", desk.document.fireMarks.count)
                figureRow("Walk marks on the open ticket", openWalkMarks)
                figureRow("Service marks", desk.document.serviceMarks.count)
                Text(idleSentence)
                    .font(PassType.font(.body, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Back to the ticket") {
                    desk.fireRuleOpen = false
                    dismiss()
                }
                .buttonStyle(PassFireStyle())
            }
            .padding(.horizontal, PassSpace.outer)
            .padding(.vertical, PassSpace.card)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(PassInk.background)
    }

    private var headline: String {
        guard let ticket = desk.document.openTicket else {
            return "The last service mark is on the spike."
        }
        switch ticket {
        case .mise:
            return "Mise is open. File bowls until the iron takes the ticket."
        case .firing:
            return "The iron is live. Walk the fire until service."
        case .plated:
            return "This ticket has plated."
        }
    }

    private var openWalkMarks: Int {
        guard let id = desk.document.openTicket?.sheet.id else { return 0 }
        return desk.document.walkIndex(for: id)
    }

    private var idleSentence: String {
        if desk.document.holdsIdle {
            return "The screen will not sleep while this ticket is firing."
        }
        return "The screen may sleep. Idle is held only while a ticket is firing."
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
    }
}
