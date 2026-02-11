import XCTest
@testable import OpenGlass

final class SocialModeTests: XCTestCase {
    let sut = SocialMode()

    func test_id() { XCTAssertEqual(sut.id, "social") }
    func test_name() { XCTAssertEqual(sut.name, "Social") }
    func test_icon() { XCTAssertEqual(sut.icon, "person.2") }

    func test_systemInstruction_containsExpectedKeywords() {
        XCTAssertTrue(sut.systemInstruction.contains("badge"))
        XCTAssertTrue(sut.systemInstruction.contains("social"))
        XCTAssertTrue(sut.systemInstruction.contains("whisper"))
        XCTAssertTrue(sut.systemInstruction.contains("contacts"))
    }

    func test_toolDeclarations_containsExecute() {
        let names = sut.toolDeclarations.compactMap { $0["name"] as? String }
        XCTAssertTrue(names.contains("execute"))
    }

    func test_activationPhrases() {
        XCTAssertTrue(sut.activationPhrases.contains("social mode"))
        XCTAssertTrue(sut.activationPhrases.contains("who is this"))
        XCTAssertTrue(sut.activationPhrases.contains("who's that"))
    }

    func test_shouldAutoActivate_whoIsThis_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "hey who is this person", frame: nil))
    }

    func test_shouldAutoActivate_whosThat_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "who's that over there", frame: nil))
    }

    func test_shouldAutoActivate_noMatch_returnsFalse() {
        XCTAssertFalse(sut.shouldAutoActivate(transcript: "play some music", frame: nil))
    }
}
