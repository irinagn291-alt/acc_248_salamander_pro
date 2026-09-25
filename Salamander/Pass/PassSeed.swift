import Foundation

/// Role: Pass. Simulator demo behind slm.demo.v1. Device never writes this. Tonight's ticket is Firing so Walk is live.
enum PassSeed {
    static func document(at now: Date, calendar: Calendar, shelf: [Recipe] = PassShelf.bundled) -> PassDocument {
        let daykey = PassDaykey.from(now, calendar: calendar).rawValue
        let unix = now.timeIntervalSince1970
        var document = PassDocument.empty
        document.schemaVersion = PassDocument.schema
        document.onboardingComplete = true
        document.currentDaykey = daykey
        document.cachedCatalog = shelf
        document.recipes = Array(shelf.prefix(5))

        for (index, recipe) in document.recipes.enumerated() {
            document.cookbookItems.append(
                CookbookItem(
                    id: fixed(10 + index),
                    mealID: recipe.id,
                    name: recipe.name,
                    savedDaykey: daykey
                )
            )
        }

        let plated = plate(
            recipe: shelf[1],
            ticketID: fixed(1),
            nowUnix: unix - 3_600,
            daykey: daykey,
            bowlBase: 100,
            walkBase: 200,
            markBase: 300
        )
        document.tickets.append(plated.record)
        document.bowls.append(contentsOf: plated.bowls)
        document.walks.append(contentsOf: plated.walks)
        document.walkMarks.append(contentsOf: plated.walkMarks)
        document.fireMarks.append(plated.fire)
        document.serviceMarks.append(plated.service)

        let live = firing(
            recipe: shelf[0],
            ticketID: fixed(2),
            nowUnix: unix,
            daykey: daykey,
            bowlBase: 400,
            walkBase: 500,
            markBase: 600
        )
        document.tickets.append(live.record)
        document.bowls.append(contentsOf: live.bowls)
        document.walks.append(contentsOf: live.walks)
        document.walkMarks.append(contentsOf: live.walkMarks)
        document.fireMarks.append(live.fire)

        return document
    }

    private struct BuiltTicket {
        var record: TicketRecord
        var bowls: [Bowl]
        var walks: [Walk]
        var walkMarks: [WalkMark]
        var fire: FireMark
        var service: ServiceMark
    }

    private static func plate(
        recipe: Recipe,
        ticketID: UUID,
        nowUnix: Double,
        daykey: Int,
        bowlBase: Int,
        walkBase: Int,
        markBase: Int
    ) -> BuiltTicket {
        var bowls: [Bowl] = []
        var walks: [Walk] = []
        var marks: [WalkMark] = []
        for (index, bowl) in recipe.bowls.enumerated() {
            var placed = bowl.placed(on: ticketID, id: fixed(bowlBase + index))
            placed.filedUnix = nowUnix - Double(recipe.bowls.count - index)
            bowls.append(placed)
        }
        for (index, walk) in recipe.walks.enumerated() {
            let placed = walk.placed(on: ticketID, id: fixed(walkBase + index))
            walks.append(placed)
            marks.append(
                WalkMark(
                    id: fixed(markBase + index),
                    ticketID: ticketID,
                    walkID: placed.id,
                    daykey: daykey,
                    markedUnix: nowUnix - Double(recipe.walks.count - index)
                )
            )
        }
        let record = TicketRecord(
            id: ticketID,
            mealID: recipe.id,
            name: recipe.name,
            phase: .plated,
            openedDaykey: daykey
        )
        let fire = FireMark(id: fixed(markBase + 80), ticketID: ticketID, daykey: daykey, markedUnix: nowUnix - 20)
        let service = ServiceMark(
            id: fixed(markBase + 90),
            ticketID: ticketID,
            mealID: recipe.id,
            name: recipe.name,
            daykey: daykey,
            markedUnix: nowUnix
        )
        return BuiltTicket(record: record, bowls: bowls, walks: walks, walkMarks: marks, fire: fire, service: service)
    }

    private static func firing(
        recipe: Recipe,
        ticketID: UUID,
        nowUnix: Double,
        daykey: Int,
        bowlBase: Int,
        walkBase: Int,
        markBase: Int
    ) -> BuiltTicket {
        var bowls: [Bowl] = []
        var walks: [Walk] = []
        for (index, bowl) in recipe.bowls.enumerated() {
            var placed = bowl.placed(on: ticketID, id: fixed(bowlBase + index))
            placed.filedUnix = nowUnix - Double(recipe.bowls.count - index)
            bowls.append(placed)
        }
        for (index, walk) in recipe.walks.enumerated() {
            walks.append(walk.placed(on: ticketID, id: fixed(walkBase + index)))
        }
        let firstWalk = walks[0]
        let marks = [
            WalkMark(
                id: fixed(markBase),
                ticketID: ticketID,
                walkID: firstWalk.id,
                daykey: daykey,
                markedUnix: nowUnix - 5
            ),
        ]
        let record = TicketRecord(
            id: ticketID,
            mealID: recipe.id,
            name: recipe.name,
            phase: .firing,
            openedDaykey: daykey
        )
        let fire = FireMark(id: fixed(markBase + 80), ticketID: ticketID, daykey: daykey, markedUnix: nowUnix - 30)
        let service = ServiceMark(
            id: fixed(markBase + 90),
            ticketID: ticketID,
            mealID: recipe.id,
            name: recipe.name,
            daykey: daykey,
            markedUnix: nowUnix
        )
        return BuiltTicket(record: record, bowls: bowls, walks: walks, walkMarks: marks, fire: fire, service: service)
    }

    private static func fixed(_ value: Int) -> UUID {
        UUID(uuidString: String(format: "aaaaaaaa-bbbb-4ccc-8ddd-%012x", value)) ?? UUID()
    }
}
