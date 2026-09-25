import XCTest
@testable import Salamander

final class PassLatchTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = PassLatch.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.surface, .cookbook)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinctScreensPlusSearch() {
        XCTAssertEqual(ReviewPane.today.rawValue, "today")
        XCTAssertEqual(ReviewPane.log.rawValue, "log")
        XCTAssertEqual(ReviewPane.goals.rawValue, "goals")
        XCTAssertEqual(ReviewPane.search.rawValue, "search")
        XCTAssertEqual(ReviewPane.today.surface, .home)
        XCTAssertEqual(ReviewPane.log.surface, .cookbook)
        XCTAssertEqual(ReviewPane.goals.surface, .settings)
        XCTAssertEqual(ReviewPane.search.surface, .search)
        XCTAssertEqual(ReviewPane.home.surface, .home)
        XCTAssertEqual(ReviewPane.cookbook.surface, .cookbook)
        XCTAssertEqual(ReviewPane.settings.surface, .settings)
        XCTAssertEqual(ReviewPane.cook.surface, .home)
        XCTAssertNotEqual(ReviewPane.today.surface, ReviewPane.log.surface)
        XCTAssertNotEqual(ReviewPane.log.surface, ReviewPane.goals.surface)
        XCTAssertNotEqual(ReviewPane.today.surface, ReviewPane.goals.surface)
        XCTAssertNotEqual(ReviewPane.search.surface, ReviewPane.today.surface)
        XCTAssertEqual(PassSheet.from(ReviewPane.cookbook.surface), .cookbook)
        XCTAssertEqual(PassSheet.from(ReviewPane.settings.surface), .settings)
        XCTAssertNil(PassSheet.from(.home))
        XCTAssertEqual(PassSheet.from(.cookbook), .cookbook)
        XCTAssertEqual(PassSheet.from(.settings), .settings)
        XCTAssertEqual(PassSheet.from(.search), .search)
        XCTAssertFalse([PassSheet.search, .cookbook, .settings].map(\.rawValue).contains("game"))
        XCTAssertEqual(PassLatch.flag, "-ReviewScreen")

        var consumed = false
        XCTAssertEqual(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
        consumed = false
        XCTAssertEqual(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "search"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .search
        )
        consumed = false
        XCTAssertEqual(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "cookbook"],
                onboardingComplete: true,
                consumed: &consumed
            )?.surface,
            .cookbook
        )
        consumed = false
        XCTAssertEqual(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "settings"],
                onboardingComplete: true,
                consumed: &consumed
            )?.surface,
            .settings
        )
        consumed = false
        XCTAssertEqual(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "home"],
                onboardingComplete: true,
                consumed: &consumed
            )?.surface,
            .home
        )
        consumed = false
        XCTAssertEqual(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "cook"],
                onboardingComplete: true,
                consumed: &consumed
            )?.surface,
            .home
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            PassLatch.consume(
                arguments: ["-ReviewScreen", "game"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }
}
