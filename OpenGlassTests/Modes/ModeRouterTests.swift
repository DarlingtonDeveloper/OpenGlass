import XCTest
@testable import OpenGlass

@MainActor
final class ModeRouterTests: XCTestCase {
    var sut: ModeRouter!

    override func setUp() {
        super.setUp()
        sut = ModeRouter()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func test_initialMode_isAssistant() {
        XCTAssertEqual(sut.currentMode.id, "assistant")
    }

    func test_availableModes_containsFourModes() {
        XCTAssertEqual(sut.availableModes.count, 4)
        let ids = sut.availableModes.map { $0.id }
        XCTAssertTrue(ids.contains("assistant"))
        XCTAssertTrue(ids.contains("translator"))
        XCTAssertTrue(ids.contains("qr_scanner"))
        XCTAssertTrue(ids.contains("spotter"))
    }

    // MARK: - switchTo

    func test_switchTo_changesCurrentMode() {
        let translator = sut.availableModes.first { $0.id == "translator" }!
        sut.switchTo(translator)
        XCTAssertEqual(sut.currentMode.id, "translator")
    }

    func test_switchTo_sameMode_doesNotTriggerCallback() {
        var callCount = 0
        sut.onModeChanged = { _ in callCount += 1 }

        // Switch to assistant (already active) — should be no-op
        let assistant = sut.availableModes.first { $0.id == "assistant" }!
        sut.switchTo(assistant)
        XCTAssertEqual(callCount, 0)
    }

    func test_switchTo_differentMode_triggersCallback() {
        var callCount = 0
        var changedTo: String?
        sut.onModeChanged = { mode in
            callCount += 1
            changedTo = mode.id
        }

        let spotter = sut.availableModes.first { $0.id == "spotter" }!
        sut.switchTo(spotter)
        XCTAssertEqual(callCount, 1)
        XCTAssertEqual(changedTo, "spotter")
    }

    func test_switchToById_works() {
        sut.switchTo(id: "translator")
        XCTAssertEqual(sut.currentMode.id, "translator")
    }

    func test_switchToById_invalidId_noChange() {
        sut.switchTo(id: "nonexistent")
        XCTAssertEqual(sut.currentMode.id, "assistant")
    }

    // MARK: - checkAutoSwitch

    func test_checkAutoSwitch_translatorPhrase_switches() {
        sut.checkAutoSwitch(transcript: "can you translate mode please", frame: nil)
        XCTAssertEqual(sut.currentMode.id, "translator")
    }

    func test_checkAutoSwitch_spotterPhrase_switches() {
        sut.checkAutoSwitch(transcript: "what's that over there", frame: nil)
        XCTAssertEqual(sut.currentMode.id, "spotter")
    }

    func test_checkAutoSwitch_qrPhrase_switches() {
        sut.checkAutoSwitch(transcript: "scan qr code", frame: nil)
        XCTAssertEqual(sut.currentMode.id, "qr_scanner")
    }

    func test_checkAutoSwitch_noMatch_staysOnCurrentMode() {
        sut.checkAutoSwitch(transcript: "what is the weather today", frame: nil)
        XCTAssertEqual(sut.currentMode.id, "assistant")
    }

    func test_checkAutoSwitch_emptyTranscript_noSwitch() {
        sut.checkAutoSwitch(transcript: "", frame: nil)
        XCTAssertEqual(sut.currentMode.id, "assistant")
    }

    func test_checkAutoSwitch_caseInsensitive() {
        sut.checkAutoSwitch(transcript: "TRANSLATE MODE", frame: nil)
        XCTAssertEqual(sut.currentMode.id, "translator")
    }
}
