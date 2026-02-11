import XCTest
@testable import OpenGlass

final class TranslatorModeTests: XCTestCase {
    let sut = TranslatorMode()

    func test_id() { XCTAssertEqual(sut.id, "translator") }
    func test_name() { XCTAssertEqual(sut.name, "Translator") }
    func test_icon() { XCTAssertEqual(sut.icon, "character.bubble") }

    func test_systemInstruction_containsExpectedKeywords() {
        XCTAssertTrue(sut.systemInstruction.contains("Mandarin"))
        XCTAssertTrue(sut.systemInstruction.contains("English"))
        XCTAssertTrue(sut.systemInstruction.contains("translat"))
    }

    func test_toolDeclarations_containsExecute() {
        let names = sut.toolDeclarations.compactMap { $0["name"] as? String }
        XCTAssertTrue(names.contains("execute"))
    }

    func test_activationPhrases() {
        XCTAssertTrue(sut.activationPhrases.contains("translate mode"))
        XCTAssertTrue(sut.activationPhrases.contains("translator mode"))
        XCTAssertTrue(sut.activationPhrases.contains("help me translate"))
    }

    func test_shouldAutoActivate_translatorPhrase_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "translate mode", frame: nil))
    }

    func test_shouldAutoActivate_noMatch_returnsFalse() {
        XCTAssertFalse(sut.shouldAutoActivate(transcript: "what time is it", frame: nil))
    }
}
