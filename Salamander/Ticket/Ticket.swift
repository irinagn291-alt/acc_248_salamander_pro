import Foundation

/// Role: Ticket. The open sheet on the pass. Bowls and walks live here. Walk index is not a field.
struct TicketSheet: Equatable, Sendable {
    var id: UUID
    var mealID: String
    var name: String
    var bowls: [Bowl]
    var walks: [Walk]
    var openedDaykey: Int

    var unfiledBowls: [Bowl] { bowls.filter { !$0.isFiled } }
    var filedBowls: [Bowl] {
        bowls.filter(\.isFiled).sorted { lhs, rhs in
            (lhs.filedUnix ?? 0) < (rhs.filedUnix ?? 0)
        }
    }
}

/// Role: Ticket. Persisted row. Phase is stored. Walk index and idle sleep are not.
struct TicketRecord: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var mealID: String
    var name: String
    var phase: TicketPhase
    var openedDaykey: Int
}

/// Role: Ticket. ADT fold Mise | Firing | Plated. The pass keeps at most one open (Mise or Firing) ticket.
enum Ticket: Equatable, Sendable {
    case mise(TicketSheet)
    case firing(TicketSheet)
    case plated(TicketSheet)

    var sheet: TicketSheet {
        switch self {
        case .mise(let sheet), .firing(let sheet), .plated(let sheet):
            return sheet
        }
    }

    var phase: TicketPhase {
        switch self {
        case .mise: .mise
        case .firing: .firing
        case .plated: .plated
        }
    }

    /// Idle sleep is held only while Firing. Derived, never stored.
    var holdsIdle: Bool {
        if case .firing = self { return true }
        return false
    }

    var isOpen: Bool {
        switch self {
        case .mise, .firing: true
        case .plated: false
        }
    }

    static func fold(record: TicketRecord, bowls: [Bowl], walks: [Walk]) -> Ticket {
        let sheet = TicketSheet(
            id: record.id,
            mealID: record.mealID,
            name: record.name,
            bowls: bowls,
            walks: walks,
            openedDaykey: record.openedDaykey
        )
        switch record.phase {
        case .mise: return .mise(sheet)
        case .firing: return .firing(sheet)
        case .plated: return .plated(sheet)
        }
    }

    var record: TicketRecord {
        TicketRecord(
            id: sheet.id,
            mealID: sheet.mealID,
            name: sheet.name,
            phase: phase,
            openedDaykey: sheet.openedDaykey
        )
    }
}
