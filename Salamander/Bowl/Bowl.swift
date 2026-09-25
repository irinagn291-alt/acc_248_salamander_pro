import Foundation

/// Role: Bowl. One mise slot on a ticket. Filing the last unfiled bowl writes a FireMark.
struct Bowl: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var ticketID: UUID?
    var name: String
    var measure: String
    var filedUnix: Double?

    var isFiled: Bool { filedUnix != nil }

    static func template(name: String, measure: String, id: UUID = UUID()) -> Bowl {
        Bowl(id: id, ticketID: nil, name: name, measure: measure, filedUnix: nil)
    }

    func placed(on ticketID: UUID, id: UUID = UUID()) -> Bowl {
        Bowl(id: id, ticketID: ticketID, name: name, measure: measure, filedUnix: nil)
    }
}
