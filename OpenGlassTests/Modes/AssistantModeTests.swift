import XCTest
@testable import OpenGlass

final class AssistantModeTests: XCTestCase {
    let sut = AssistantMode()

    func test_id() {
        XCTAssertEqual(sut.id, "assistant")
    }

    func test_name() {
        XCTAssertEqual(sut.name, "Assistant")
    }

    func test_icon() {
        XCTAssertEqual(sut.icon, "sparkles")
    }

    func test_systemInstruction_isNonEmpty() {
        XCTAssertFalse(sut.systemInstruction.isEmpty)
    }

    func test_systemInstruction_containsExpectedKeywords() {
        XCTAssertTrue(sut.systemInstruction.contains("execute"))
        XCTAssertTrue(sut.systemInstruction.contains("smart glasses"))
        XCTAssertTrue(sut.systemInstruction.contains("tool"))
    }

    func test_toolDeclarations_containsExecute() {
        let tools = sut.toolDeclarations
        XCTAssertFalse(tools.isEmpty)
        let names = tools.compactMap { $0["name"] as? String }
        XCTAssertTrue(names.contains("execute"))
    }

    func test_activationPhrases_areCorrect() {
        XCTAssertTrue(sut.activationPhrases.contains("assistant mode"))
        XCTAssertTrue(sut.activationPhrases.contains("normal mode"))
    }

    func test_shouldAutoActivate_matchingPhrase_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "switch to assistant mode", frame: nil))
    }

    func test_shouldAutoActivate_noMatch_returnsFalse() {
        XCTAssertFalse(sut.shouldAutoActivate(transcript: "hello world", frame: nil))
    }
}
