import XCTest
@testable import OpenGlass

final class CoachModeTests: XCTestCase {
    let sut = CoachMode()

    func test_id() { XCTAssertEqual(sut.id, "coach") }
    func test_name() { XCTAssertEqual(sut.name, "Coach") }
    func test_icon() { XCTAssertEqual(sut.icon, "figure.run") }

    func test_systemInstruction_containsExpectedKeywords() {
        XCTAssertTrue(sut.systemInstruction.contains("coach"))
        XCTAssertTrue(sut.systemInstruction.contains("Gym"))
        XCTAssertTrue(sut.systemInstruction.contains("Cooking"))
        XCTAssertTrue(sut.systemInstruction.contains("Navigation"))
        XCTAssertTrue(sut.systemInstruction.contains("camera"))
    }

    func test_toolDeclarations_containsExecute() {
        let names = sut.toolDeclarations.compactMap { $0["name"] as? String }
        XCTAssertTrue(names.contains("execute"))
    }

    func test_activationPhrases() {
        XCTAssertTrue(sut.activationPhrases.contains("coach mode"))
        XCTAssertTrue(sut.activationPhrases.contains("coach me"))
        XCTAssertTrue(sut.activationPhrases.contains("watch my form"))
        XCTAssertTrue(sut.activationPhrases.contains("help me cook"))
    }

    func test_shouldAutoActivate_coachMe_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "hey coach me on this", frame: nil))
    }

    func test_shouldAutoActivate_watchMyForm_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "can you watch my form", frame: nil))
    }

    func test_shouldAutoActivate_noMatch_returnsFalse() {
        XCTAssertFalse(sut.shouldAutoActivate(transcript: "what time is it", frame: nil))
    }
}
