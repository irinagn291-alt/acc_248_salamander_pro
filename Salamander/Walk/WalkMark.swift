import Foundation

/// Role: Walk. A tap on the live fire line. Count of these marks is the walk index.
struct WalkMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var ticketID: UUID
    var walkID: UUID
    var daykey: Int
    var markedUnix: Double
}
