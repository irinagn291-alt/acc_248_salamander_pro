import XCTest
@testable import Salamander

/// Family invariant: cook mode files ingredients first, then numbered steps. Dish of the day is optional chrome.
final class FamilyInvariantTests: XCTestCase {
    private var calendar: Calendar { SalamanderGMT.calendar }
    private var now: Date { SalamanderGMT.instant(2026, 9, 18) }
    private var recipe: Recipe { PassShelf.bundled[0] }

    func test_ingredientsThenNumberedSteps_walkBeforeFireIsRefused() throws {
        var pass = PassDocument.empty
        try pass.openTicket(from: recipe, now: now, calendar: calendar, ticketID: UUID())
        XCTAssertEqual(pass.openTicket?.phase, .mise)
        XCTAssertFalse(pass.canWalk)
        XCTAssertTrue(pass.canFileBowl)
        XCTAssertFalse(pass.holdsIdle)

        XCTAssertThrowsError(try pass.fileWalk(now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? PassFault, .walkBeforeFire)
        }

        let ticketID = try XCTUnwrap(pass.openTicket?.sheet.id)
        for bowl in pass.bowls.filter({ $0.ticketID == ticketID }).dropLast() {
            try pass.fileBowl(bowl.id, now: now, calendar: calendar)
            XCTAssertEqual(pass.openTicket?.phase, .mise)
            XCTAssertFalse(pass.holdsIdle)
            XCTAssertFalse(pass.canWalk)
        }
        let lastBowl = try XCTUnwrap(pass.bowls.last(where: { $0.ticketID == ticketID && $0.filedUnix == nil }))
        try pass.fileBowl(lastBowl.id, now: now, calendar: calendar)

        XCTAssertEqual(pass.openTicket?.phase, .firing)
        XCTAssertEqual(pass.fireMarks.count, 1)
        XCTAssertTrue(pass.holdsIdle)
        XCTAssertTrue(pass.canWalk)
        XCTAssertEqual(pass.walkIndex(for: ticketID), 0)
        XCTAssertEqual(pass.liveWalk(for: ticketID)?.text, recipe.walks[0].text)

        try pass.fileWalk(now: now, calendar: calendar)
        XCTAssertEqual(pass.walkIndex(for: ticketID), 1)
        XCTAssertEqual(pass.liveWalk(for: ticketID)?.text, recipe.walks[1].text)
        XCTAssertEqual(pass.openTicket?.phase, .firing)
        XCTAssertTrue(pass.holdsIdle)

        while pass.canWalk {
            try pass.fileWalk(now: now, calendar: calendar)
        }
        XCTAssertNil(pass.openTicket)
        XCTAssertEqual(pass.assembled(ticketID)?.phase, .plated)
        XCTAssertEqual(pass.serviceMarks.count, 1)
        XCTAssertEqual(pass.walkIndex(for: ticketID), recipe.walks.count)
        XCTAssertFalse(pass.holdsIdle)
        XCTAssertFalse(pass.canWalk)
        XCTAssertFalse(PassFigures.integer(pass.serviceMarks.count).isEmpty)
        XCTAssertFalse(PassFigures.integer(pass.walkIndex(for: ticketID)).isEmpty)
    }

    func test_startOfDayKeyIsYYYYMMDDInteger() {
        let late = SalamanderGMT.instant(2026, 8, 31, hour: 23)
        let next = SalamanderGMT.instant(2026, 9, 1, hour: 1)
        XCTAssertEqual(PassDaykey.from(late, calendar: calendar).rawValue, 20260831)
        XCTAssertEqual(PassDaykey.from(next, calendar: calendar).rawValue, 20260901)
        XCTAssertEqual(
            calendar.startOfDay(for: late).timeIntervalSince1970,
            PassDaykey.from(late, calendar: calendar).startDate(calendar: calendar)?.timeIntervalSince1970
        )
    }
}
