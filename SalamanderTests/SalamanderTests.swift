import XCTest
@testable import Salamander

final class SalamanderTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: SalamanderApp.self), "SalamanderApp")
        XCTAssertEqual(PassDocument.schema, 1)
        XCTAssertEqual(PassKey.snapshot, "slm.pass.v1")
        XCTAssertGreaterThanOrEqual(PassShelf.bundled.count, 4)
        XCTAssertEqual(PassType.face, "SF Pro")
        XCTAssertEqual(PassInk.Hex.background, "#1F1415")
        XCTAssertEqual(PassInk.Hex.surface, "#2B1C1D")
        XCTAssertEqual(PassInk.Hex.ink, "#F2EDEE")
        XCTAssertEqual(PassInk.Hex.accent, "#E45864")
        XCTAssertEqual(PassInk.Hex.muted, "#AC9193")
    }
}
