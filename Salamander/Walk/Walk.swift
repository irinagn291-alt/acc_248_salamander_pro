import Foundation

/// Role: Walk. One numbered fire line. The live index is the WalkMark count, never a stored cursor.
struct Walk: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var ticketID: UUID?
    var text: String

    static func template(text: String, id: UUID = UUID()) -> Walk {
        Walk(id: id, ticketID: nil, text: text)
    }

    func placed(on ticketID: UUID, id: UUID = UUID()) -> Walk {
        Walk(id: id, ticketID: ticketID, text: text)
    }
}
