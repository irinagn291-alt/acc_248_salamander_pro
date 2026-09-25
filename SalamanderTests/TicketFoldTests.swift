import XCTest
@testable import Salamander

/// Architecture: Ticket ADT fold Mise | Firing | Plated. Pass is a fold over Tickets. Walk index is WalkMark count. No View.
final class TicketFoldTests: XCTestCase {
    private var calendar: Calendar { SalamanderGMT.calendar }
    private var now: Date { SalamanderGMT.instant(2026, 9, 18, hour: 19) }
    private var recipe: Recipe { PassShelf.bundled[0] }
    private var other: Recipe { PassShelf.bundled[2] }

    func test_primaryVerbEmptyPopulatedInvalid() throws {
        var pass = PassDocument.empty
        XCTAssertFalse(pass.canWalk)
        XCTAssertThrowsError(try pass.fileWalk(now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? PassFault, .passEmpty)
        }

        try pass.openTicket(from: recipe, now: now, calendar: calendar)
        XCTAssertFalse(pass.canWalk)
        XCTAssertThrowsError(try pass.fileWalk(now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? PassFault, .walkBeforeFire)
        }

        try fileAllBowls(&pass)
        XCTAssertTrue(pass.canWalk)
        XCTAssertEqual(pass.openTicket?.phase, .firing)

        try pass.fileWalk(now: now, calendar: calendar)
        XCTAssertTrue(pass.canWalk)

        while pass.canWalk {
            try pass.fileWalk(now: now, calendar: calendar)
        }
        XCTAssertFalse(pass.canWalk)
        XCTAssertThrowsError(try pass.fileWalk(now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? PassFault, .passEmpty)
        }
    }

    func test_secondOpenWhileFiringIsRefused() throws {
        var pass = PassDocument.empty
        try pass.openTicket(from: recipe, now: now, calendar: calendar)
        XCTAssertThrowsError(try pass.openTicket(from: other, now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? PassFault, .openRefused)
        }
        try fileAllBowls(&pass)
        XCTAssertEqual(pass.openTicket?.phase, .firing)
        XCTAssertThrowsError(try pass.openTicket(from: other, now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? PassFault, .openRefused)
        }
        while pass.canWalk {
            try pass.fileWalk(now: now, calendar: calendar)
        }
        XCTAssertTrue(pass.canOpen)
        try pass.openTicket(from: other, now: now, calendar: calendar)
        XCTAssertEqual(pass.openTicket?.sheet.mealID, other.id)
        XCTAssertEqual(pass.openTicket?.phase, .mise)
    }

    func test_retractPeelsWalkThenBowlAndReversesMarks() throws {
        var pass = PassDocument.empty
        try pass.openTicket(from: recipe, now: now, calendar: calendar)
        let ticketID = try XCTUnwrap(pass.openTicket?.sheet.id)
        try fileAllBowls(&pass)
        XCTAssertEqual(pass.fireMarks.count, 1)
        try pass.fileWalk(now: now, calendar: calendar)
        XCTAssertEqual(pass.walkIndex(for: ticketID), 1)

        try pass.retract()
        XCTAssertEqual(pass.walkIndex(for: ticketID), 0)
        XCTAssertEqual(pass.openTicket?.phase, .firing)
        XCTAssertEqual(pass.fireMarks.count, 1)

        try pass.retract()
        XCTAssertEqual(pass.openTicket?.phase, .mise)
        XCTAssertEqual(pass.fireMarks.count, 0)
        XCTAssertEqual(pass.bowls.filter { $0.ticketID == ticketID && $0.isFiled }.count, recipe.bowls.count - 1)

        try fileAllBowls(&pass)
        while pass.canWalk {
            try pass.fileWalk(now: now, calendar: calendar)
        }
        XCTAssertEqual(pass.serviceMarks.count, 1)
        XCTAssertEqual(pass.assembled(ticketID)?.phase, .plated)

        try pass.retract()
        XCTAssertEqual(pass.openTicket?.phase, .firing)
        XCTAssertEqual(pass.serviceMarks.count, 0)
        XCTAssertEqual(pass.walkIndex(for: ticketID), recipe.walks.count - 1)
        XCTAssertTrue(pass.holdsIdle)
    }

    func test_walkIndexIsMarkCountAndIdleIsDerived() throws {
        var pass = PassDocument.empty
        try pass.openTicket(from: recipe, now: now, calendar: calendar)
        let ticketID = try XCTUnwrap(pass.openTicket?.sheet.id)
        try fileAllBowls(&pass)
        try pass.fileWalk(now: now, calendar: calendar)
        try pass.fileWalk(now: now, calendar: calendar)
        XCTAssertEqual(pass.walkIndex(for: ticketID), pass.walkMarks.filter { $0.ticketID == ticketID }.count)
        XCTAssertEqual(pass.walkIndex(for: ticketID), 2)
        XCTAssertTrue(pass.holdsIdle)

        let data = try pass.encoded()
        let text = String(data: data, encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("walkIndex"))
        XCTAssertFalse(text.contains("holdsIdle"))
        XCTAssertFalse(text.contains("idleSleep"))
        XCTAssertTrue(text.contains("\"walkMarks\""))
        XCTAssertTrue(text.contains("\"fireMarks\""))
        XCTAssertTrue(text.contains("\"serviceMarks\""))
        XCTAssertTrue(text.contains("\"currentDaykey\""))
        XCTAssertTrue(text.contains("\"schemaVersion\""))
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        var pass = PassDocument.empty
        try pass.openTicket(from: recipe, now: now, calendar: calendar)
        let data = try pass.encoded()
        let decoded = try PassDocument.read(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.tickets.count, 1)

        XCTAssertThrowsError(try PassDocument.read(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? PassCodecError, .unknownSchema(99))
        }
        XCTAssertThrowsError(try PassDocument.read(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? PassCodecError, .damaged)
        }
    }

    func test_seedLeavesWalkEnabled() {
        let pass = PassSeed.document(at: now, calendar: calendar)
        XCTAssertTrue(pass.onboardingComplete)
        XCTAssertTrue(pass.canWalk)
        XCTAssertEqual(pass.openTicket?.phase, .firing)
        XCTAssertTrue(pass.holdsIdle)
        XCTAssertGreaterThanOrEqual(pass.cookbookItems.count, 4)
        XCTAssertGreaterThanOrEqual(pass.serviceMarks.count, 1)
        XCTAssertGreaterThan(pass.remainingWalks(for: pass.openTicket?.sheet.id ?? UUID()), 0)
        XCTAssertEqual(pass.currentDaykey, 20260918)
    }

    func test_instructionBlockBecomesNumberedWalks() {
        let lines = PassWalks.split("1. Warm the iron.\n2. Season the fish.\n3. Rest the plate.")
        XCTAssertEqual(lines, ["Warm the iron.", "Season the fish.", "Rest the plate."])
    }

    private func fileAllBowls(_ pass: inout PassDocument) throws {
        let ticketID = try XCTUnwrap(pass.openTicket?.sheet.id)
        let pending = pass.bowls.filter { $0.ticketID == ticketID && !$0.isFiled }
        for bowl in pending {
            try pass.fileBowl(bowl.id, now: now, calendar: calendar)
        }
    }
}
