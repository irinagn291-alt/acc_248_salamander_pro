import Foundation

/// Role: Ticket. Stored phases of tonight's pass. Idle sleep is never a fourth case.
enum TicketPhase: String, Codable, Sendable, Equatable {
    case mise
    case firing
    case plated
}
