import SwiftUI

/// Role: Pass. First-class Cook surface fused on Home. Mise bowls and numbered fire walks share one ticket. Not a pushed scene.
struct CookView: View {
    var ticket: Ticket
    @Environment(PassDesk.self) private var desk
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sheet: TicketSheet { ticket.sheet }
    private var ticketID: UUID { sheet.id }
    private var walkIndex: Int { desk.document.walkIndex(for: ticketID) }
    private var liveWalk: Walk? { desk.document.liveWalk(for: ticketID) }
    private var walkTotal: Int { sheet.walks.count }
    private var remaining: Int { desk.document.remainingWalks(for: ticketID) }
    private var nextBowl: Bowl? { sheet.unfiledBowls.first }
    private var listedBowls: [Bowl] {
        if ticket.phase == .mise, let live = nextBowl {
            return sheet.bowls.filter { $0.id != live.id }
        }
        return sheet.bowls
    }

    var body: some View {
        Group {
            if let fault = desk.cookFault {
                PassVacant(
                    art: "slm_EmptyHome",
                    headline: "That tap was refused.",
                    line: fault,
                    verb: "Back to the ticket",
                    action: { desk.clearCookFault() }
                )
            } else if sheet.bowls.isEmpty || sheet.walks.isEmpty {
                PassVacant(
                    art: "slm_EmptyHome",
                    headline: "This ticket has no fire.",
                    line: "The recipe is missing bowls or walks. Open another cookbook item.",
                    verb: "Open cookbook",
                    action: { desk.present(.cookbook) }
                )
            } else {
                populated
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PassInk.background)
    }

    private var fillsTicket: Bool { sizeClass == .regular }

    private var populated: some View {
        Group {
            if fillsTicket {
                GeometryReader { geo in
                    ScrollView {
                        ticketBoard
                            .padding(.horizontal, PassSpace.outer)
                            .padding(.bottom, PassSpace.card)
                            .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .topLeading)
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
            } else {
                ScrollView {
                    ticketBoard
                        .padding(.horizontal, PassSpace.outer)
                        .padding(.bottom, PassSpace.card)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(PassMotion.crossfade(reduceMotion), value: walkIndex)
        .animation(PassMotion.crossfade(reduceMotion), value: sheet.unfiledBowls.count)
    }

    @ViewBuilder
    private var ticketBoard: some View {
        if fillsTicket {
            HStack(alignment: .top, spacing: PassSpace.outer) {
                fireColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                miseColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(alignment: .leading, spacing: PassSpace.card) {
                fireColumn
                miseColumn
            }
        }
    }

    /// Pull quote plus the live Walk. This block is type-led, not a list of equal rows.
    @ViewBuilder
    private var fireColumn: some View {
        switch ticket {
        case .firing:
            VStack(alignment: .leading, spacing: PassSpace.card) {
                twistStrip
                fireHero
                walkControl
                retractControl
            }
            .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .leading)
        case .mise:
            VStack(alignment: .leading, spacing: PassSpace.card) {
                twistStrip
                nextBowlQuote
                waitingWalks
                retractControl
            }
            .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .leading)
        case .plated:
            Text("This ticket has plated.")
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
        }
    }

    /// Live walk copy uses leftover iPad height so Retract sits on the ticket, not above a void.
    private var fireHero: some View {
        VStack(alignment: .leading, spacing: PassSpace.card) {
            pullQuote
                .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .topLeading)
            remainingLine
            if fillsTicket {
                otherWalkRail
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .topLeading)
    }

    /// Mise as a rule list. Adjacent to the quote, never the same column of stacked cards.
    private var miseColumn: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text(miseHeading)
                .font(PassType.font(.headline, size: typeSize))
                .foregroundStyle(PassInk.ink)
            PassRule()
            ForEach(listedBowls) { bowl in
                bowlRow(bowl)
                    .frame(maxHeight: fillsTicket ? .infinity : nil, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .leading)
    }

    private var miseHeading: String {
        switch ticket {
        case .mise:
            let left = sheet.unfiledBowls.count
            return "Mise bowls. \(PassFigures.integer(left)) still open."
        case .firing:
            return "Mise is closed. \(PassFigures.integer(sheet.bowls.count)) bowls filed."
        case .plated:
            return "Mise is closed."
        }
    }

    private var twistStrip: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text(idleLine)
                .font(PassType.font(.caption, size: typeSize))
                .foregroundStyle(PassInk.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button("Mise then fire") { desk.presentFireRule() }
                .buttonStyle(PassChipStyle())
                .accessibilityLabel("Open the mise then fire rule")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var idleLine: String {
        if desk.document.holdsIdle {
            return "Idle sleep is held. The last bowl wrote a fire mark."
        }
        return "Idle sleep waits. File the last bowl to light the iron."
    }

    private var pullQuote: some View {
        HStack(alignment: .top, spacing: PassSpace.card) {
            Rectangle()
                .fill(PassInk.accent)
                .frame(width: PassSpace.hairline)
                .frame(maxHeight: .infinity)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: PassSpace.inner) {
                Text(walkCaption)
                    .font(PassType.font(.caption, size: typeSize))
                    .foregroundStyle(PassInk.muted)
                Text(liveWalk?.text ?? "The fire is quiet.")
                    .font(PassType.font(.display, size: typeSize))
                    .foregroundStyle(PassInk.ink)
                    .lineLimit(fillsTicket ? 8 : 4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .topLeading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Live walk. \(walkCaption). \(liveWalk?.text ?? "")")
    }

    private var otherWalkRail: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            ForEach(Array(sheet.walks.enumerated()), id: \.element.id) { index, walk in
                if index != walkIndex {
                    HStack(alignment: .firstTextBaseline, spacing: PassSpace.card) {
                        Text(PassFigures.integer(index + 1))
                            .font(PassType.font(.caption, size: typeSize))
                            .foregroundStyle(PassInk.muted)
                            .frame(minWidth: PassSpace.step(3), alignment: .leading)
                        Text(walk.text)
                            .font(PassType.font(.body, size: typeSize))
                            .foregroundStyle(index < walkIndex ? PassInk.ink : PassInk.muted)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(index < walkIndex ? "Filed" : "Waiting")
                            .font(PassType.font(.micro, size: typeSize))
                            .foregroundStyle(PassInk.muted)
                            .layoutPriority(1)
                    }
                    .frame(minHeight: PassSpace.hit, maxHeight: .infinity, alignment: .topLeading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Walk \(PassFigures.integer(index + 1)). \(walk.text). \(index < walkIndex ? "Filed" : "Waiting")")
                    PassRule()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var walkCaption: String {
        let current = min(walkIndex + 1, max(walkTotal, 1))
        return "Walk \(PassFigures.integer(current)) of \(PassFigures.integer(walkTotal))."
    }

    private var walkControl: some View {
        Button {
            Task { await desk.fileWalk() }
        } label: {
            HStack(spacing: PassSpace.card) {
                Image("slm_ControlFace")
                    .resizable()
                    .scaledToFit()
                    .frame(width: PassSpace.step(6), height: PassSpace.step(6))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PassSpace.inner) {
                    Text("Walk")
                        .font(PassType.font(.headline, size: typeSize))
                    Text("File this fire line.")
                        .font(PassType.font(.caption, size: typeSize))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PassFireStyle(isLoading: desk.walkLoading))
        .disabled(!desk.document.canWalk || desk.verbBusy)
        .accessibilityLabel("Walk the fire")
        .accessibilityValue(walkCaption)
        .accessibilityHint("Files the live walk on tonight's ticket.")
    }

    private var remainingLine: some View {
        Text(remainingSentence)
            .font(PassType.font(.body, size: typeSize))
            .foregroundStyle(PassInk.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var remainingSentence: String {
        if remaining == 0 {
            return "Every fire line is filed."
        }
        if remaining == 1 {
            return "One fire line remains after this tap."
        }
        return "\(PassFigures.integer(remaining)) fire lines remain, counting this one."
    }

    private var nextBowlQuote: some View {
        VStack(alignment: .leading, spacing: PassSpace.card) {
            HStack(alignment: .top, spacing: PassSpace.card) {
                Rectangle()
                    .fill(PassInk.muted)
                    .frame(width: PassSpace.hairline)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: PassSpace.inner) {
                    Text("Next bowl")
                        .font(PassType.font(.caption, size: typeSize))
                        .foregroundStyle(PassInk.muted)
                    Text(nextBowl?.name ?? "Every bowl is filed.")
                        .font(PassType.font(.title, size: typeSize))
                        .foregroundStyle(PassInk.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    if let measure = nextBowl?.measure, !measure.isEmpty {
                        Text(measure)
                            .font(PassType.font(.body, size: typeSize))
                            .foregroundStyle(PassInk.ink)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let bowl = nextBowl {
                Button {
                    Task { await desk.fileBowl(bowl.id) }
                } label: {
                    Text("File bowl")
                        .frame(maxWidth: .infinity, minHeight: PassSpace.hit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PassFileStyle(isLoading: desk.pendingBowl == bowl.id, isLive: true))
                .disabled(desk.verbBusy)
                .accessibilityLabel("File \(bowl.name)")
                .accessibilityHint("Files this mise bowl on tonight's ticket.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .leading)
    }

    private var waitingWalks: some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            Text("Fire walks wait.")
                .font(PassType.font(.headline, size: typeSize))
                .foregroundStyle(PassInk.ink)
            Text("They stay quiet until the last bowl files.")
                .font(PassType.font(.body, size: typeSize))
                .foregroundStyle(PassInk.ink)
            PassRule()
            ForEach(Array(sheet.walks.enumerated()), id: \.element.id) { index, walk in
                HStack(alignment: .firstTextBaseline, spacing: PassSpace.card) {
                    Text(PassFigures.integer(index + 1))
                        .font(PassType.font(.caption, size: typeSize))
                        .foregroundStyle(PassInk.muted)
                        .frame(minWidth: PassSpace.step(3), alignment: .leading)
                    Text(walk.text)
                        .font(PassType.font(.body, size: typeSize))
                        .foregroundStyle(PassInk.muted)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, PassSpace.inner)
                .frame(minHeight: PassSpace.hit, maxHeight: fillsTicket ? .infinity : nil, alignment: .topLeading)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .leading)
    }

    private var retractControl: some View {
        Button("Retract") {
            Task { await desk.retract() }
        }
        .buttonStyle(PassRetractStyle(isLoading: desk.retractLoading))
        .disabled(!desk.document.canRetract || desk.verbBusy)
        .accessibilityHint("Peels the last bowl or walk mark.")
    }

    @ViewBuilder
    private func bowlRow(_ bowl: Bowl) -> some View {
        VStack(alignment: .leading, spacing: PassSpace.inner) {
            if bowl.isFiled || ticket.phase != .mise {
                HStack(alignment: .firstTextBaseline, spacing: PassSpace.card) {
                    VStack(alignment: .leading, spacing: PassSpace.inner) {
                        Text(bowl.name)
                            .font(PassType.font(.body, size: typeSize))
                            .foregroundStyle(PassInk.ink)
                            .lineLimit(1)
                        Text(bowl.measure)
                            .font(PassType.font(.caption, size: typeSize))
                            .foregroundStyle(PassInk.muted)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(bowl.isFiled ? "Filed" : "Waiting")
                        .font(PassType.font(.micro, size: typeSize))
                        .foregroundStyle(PassInk.muted)
                        .layoutPriority(1)
                }
                .padding(.vertical, PassSpace.inner)
                .frame(minHeight: PassSpace.hit, maxHeight: .infinity, alignment: .topLeading)
                .accessibilityElement(children: .combine)
            } else {
                let live = bowl.id == nextBowl?.id
                Button {
                    Task { await desk.fileBowl(bowl.id) }
                } label: {
                    HStack(alignment: .center, spacing: PassSpace.card) {
                        VStack(alignment: .leading, spacing: PassSpace.inner) {
                            Text(bowl.name)
                                .lineLimit(1)
                            Text(live ? "File this bowl." : bowl.measure)
                                .font(PassType.font(.caption, size: typeSize))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Text(live ? "File" : "Next")
                            .layoutPriority(1)
                    }
                    .frame(minHeight: PassSpace.hit)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PassFileStyle(isLoading: desk.pendingBowl == bowl.id, isLive: live))
                .disabled(desk.verbBusy)
                .accessibilityLabel("File \(bowl.name)")
                .accessibilityValue(bowl.measure)
            }
            PassRule()
        }
        .frame(maxWidth: .infinity, maxHeight: fillsTicket ? .infinity : nil, alignment: .topLeading)
    }
}
