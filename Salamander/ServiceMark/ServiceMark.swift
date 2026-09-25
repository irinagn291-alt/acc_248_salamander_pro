import Foundation

/// Role: ServiceMark. Written when the last Walk files. Flips Firing to Plated and restores sleep. Cookbook counts these.
struct ServiceMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var ticketID: UUID
    var mealID: String
    var name: String
    var daykey: Int
    var markedUnix: Double
}
