import Foundation

/// Role: Pass. Bundled cookbook shelf. Empty or failed TheMealDB search hangs from here. Not a shop.
enum PassShelf {
    static let bundled: [Recipe] = [
        recipe(
            id: "53001",
            name: "Salt crust sea bass",
            category: "Seafood",
            area: "French",
            bowls: [
                ("Sea bass", "1 whole"),
                ("Coarse salt", "1 kg"),
                ("Egg whites", "2"),
                ("Lemon thyme", "1 bunch"),
            ],
            walks: [
                "Pat the bass dry and tuck thyme into the cavity.",
                "Pack a salt and white crust around the fish.",
                "Rest the crusted bass on a hot iron until the salt sets.",
                "Crack the crust at the table and lift the fillets clean.",
            ]
        ),
        recipe(
            id: "53002",
            name: "Charred lemon chicken",
            category: "Chicken",
            area: "Italian",
            bowls: [
                ("Chicken thighs", "4"),
                ("Lemons", "2"),
                ("Olive oil", "2 tbsp"),
                ("Garlic", "3 cloves"),
            ],
            walks: [
                "Season the thighs and oil the skin.",
                "Lay them on the iron until the skin takes colour.",
                "Turn once and squeeze lemon over the pan.",
                "Rest the meat and spoon the pan juices on top.",
            ]
        ),
        recipe(
            id: "53003",
            name: "Butter mushrooms",
            category: "Vegetarian",
            area: "British",
            bowls: [
                ("King oysters", "400 g"),
                ("Butter", "40 g"),
                ("Parsley", "1 handful"),
                ("Black pepper", "1 tsp"),
            ],
            walks: [
                "Split the mushrooms and score the cut faces.",
                "Sear them cut side down until they brown.",
                "Baste with butter and cracked pepper.",
                "Finish with chopped parsley at the pass.",
            ]
        ),
        recipe(
            id: "53004",
            name: "Pass tomato salad",
            category: "Side",
            area: "Spanish",
            bowls: [
                ("Ripe tomatoes", "4"),
                ("Shallot", "1"),
                ("Sherry vinegar", "1 tbsp"),
                ("Olive oil", "3 tbsp"),
            ],
            walks: [
                "Slice the tomatoes thick and salt them.",
                "Steep shallot in vinegar for a few minutes.",
                "Spoon the shallot and oil over the tomatoes.",
                "Send the bowl to the pass while the iron works.",
            ]
        ),
        recipe(
            id: "53005",
            name: "Iron pork chop",
            category: "Pork",
            area: "American",
            bowls: [
                ("Pork chops", "2"),
                ("Mustard", "1 tbsp"),
                ("Sage", "6 leaves"),
                ("Cider vinegar", "1 tbsp"),
            ],
            walks: [
                "Dry the chops and paint them with mustard.",
                "Render the fat edge on the iron first.",
                "Cook each side until the centre just yields.",
                "Deglaze with vinegar and wilt the sage in the pan.",
            ]
        ),
        recipe(
            id: "53006",
            name: "Herb oil beans",
            category: "Side",
            area: "Greek",
            bowls: [
                ("Green beans", "300 g"),
                ("Parsley oil", "3 tbsp"),
                ("Lemon zest", "1 tsp"),
                ("Flake salt", "1 pinch"),
            ],
            walks: [
                "Blanch the beans until they stay bright.",
                "Toss them in herb oil while they steam.",
                "Add lemon zest and flake salt.",
                "Pile them beside the plated iron work.",
            ]
        ),
    ]

    private static func recipe(
        id: String,
        name: String,
        category: String,
        area: String,
        bowls: [(String, String)],
        walks: [String]
    ) -> Recipe {
        Recipe(
            id: id,
            name: name,
            category: category,
            area: area,
            thumb: "",
            bowls: bowls.map { Bowl.template(name: $0.0, measure: $0.1) },
            walks: walks.map { Walk.template(text: $0) }
        )
    }
}
