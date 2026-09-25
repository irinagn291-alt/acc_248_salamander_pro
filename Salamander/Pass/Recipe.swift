import Foundation

/// Role: Pass. A catalog recipe. Ingredient slots become Bowls. The instruction block becomes numbered Walks.
struct Recipe: Identifiable, Equatable, Sendable, Codable {
    var id: String
    var name: String
    var category: String
    var area: String
    var thumb: String
    var bowls: [Bowl]
    var walks: [Walk]
}
