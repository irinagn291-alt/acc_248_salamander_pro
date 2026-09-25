import Foundation

/// Role: Pass. A saved recipe on the cookbook shelf. Opening writes a Ticket as Mise when the pass is free.
struct CookbookItem: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var mealID: String
    var name: String
    var savedDaykey: Int
}
