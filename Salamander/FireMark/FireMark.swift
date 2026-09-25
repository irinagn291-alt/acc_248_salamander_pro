import Foundation

/// Role: FireMark. Written when the last Bowl files. Flips Mise to Firing and holds idle sleep.
struct FireMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var ticketID: UUID
    var daykey: Int
    var markedUnix: Double
}
