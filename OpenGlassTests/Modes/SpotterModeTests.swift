import XCTest
@testable import OpenGlass

final class SpotterModeTests: XCTestCase {
    let sut = SpotterMode()

    func test_id() { XCTAssertEqual(sut.id, "spotter") }
    func test_name() { XCTAssertEqual(sut.name, "Spotter") }
    func test_icon() { XCTAssertEqual(sut.icon, "eye") }

    func test_systemInstruction_containsExpectedKeywords() {
        XCTAssertTrue(sut.systemInstruction.contains("identif"))
        XCTAssertTrue(sut.systemInstruction.contains("camera"))
    }

    func test_toolDeclarations_containsExecute() {
        let names = sut.toolDeclarations.compactMap { $0["name"] as? String }
        XCTAssertTrue(names.contains("execute"))
    }

    func test_activationPhrases() {
        XCTAssertTrue(sut.activationPhrases.contains("spotter mode"))
        XCTAssertTrue(sut.activationPhrases.contains("what's that"))
        XCTAssertTrue(sut.activationPhrases.contains("what is that"))
        XCTAssertTrue(sut.activationPhrases.contains("identify this"))
    }

    func test_shouldAutoActivate_whatsThis_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "hey what's this thing", frame: nil))
    }

    func test_shouldAutoActivate_noMatch_returnsFalse() {
        XCTAssertFalse(sut.shouldAutoActivate(transcript: "play some music", frame: nil))
    }
}
