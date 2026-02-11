import XCTest
@testable import OpenGlass

@MainActor
final class ModeSessionIntegrationTests: XCTestCase {

    // MARK: - Full Mode Switch Flow

    func test_fullModeSwitchFlow_assistantToTranslatorAndBack() {
        let router = ModeRouter()

        // Start on assistant
        XCTAssertEqual(router.currentMode.id, "assistant")
        let assistantInstruction = router.currentMode.systemInstruction

        // Switch to translator
        router.switchTo(id: "translator")
        XCTAssertEqual(router.currentMode.id, "translator")
        let translatorInstruction = router.currentMode.systemInstruction
        XCTAssertNotEqual(assistantInstruction, translatorInstruction)
        XCTAssertTrue(translatorInstruction.contains("Mandarin"))

        // Switch back to assistant
        router.switchTo(id: "assistant")
        XCTAssertEqual(router.currentMode.id, "assistant")
        XCTAssertEqual(router.currentMode.systemInstruction, assistantInstruction)
    }

    func test_modeSwitchFlow_callbackFiredWithCorrectMode() {
        let router = ModeRouter()
        var switchedModes: [String] = []

        router.onModeChanged = { mode in
            switchedModes.append(mode.id)
        }

        router.switchTo(id: "translator")
        router.switchTo(id: "spotter")
        router.switchTo(id: "assistant")

        XCTAssertEqual(switchedModes, ["translator", "spotter", "assistant"])
    }

    // MARK: - Auto-Switch via Transcript

    func test_autoSwitch_translateMode_switchesToTranslator() {
        let router = ModeRouter()
        XCTAssertEqual(router.currentMode.id, "assistant")

        router.checkAutoSwitch(transcript: "hey can you help me translate mode", frame: nil)
        XCTAssertEqual(router.currentMode.id, "translator")
    }

    func test_autoSwitch_whatsThis_switchesToSpotter() {
        let router = ModeRouter()
        router.checkAutoSwitch(transcript: "what's this on the shelf", frame: nil)
        XCTAssertEqual(router.currentMode.id, "spotter")
    }

    func test_autoSwitch_scanQR_switchesToQRScanner() {
        let router = ModeRouter()
        router.checkAutoSwitch(transcript: "scan qr on the poster", frame: nil)
        XCTAssertEqual(router.currentMode.id, "qr_scanner")
    }

    // MARK: - System Instruction Verification

    func test_eachMode_hasUniqueSystemInstruction() {
        let router = ModeRouter()
        var instructions = Set<String>()
        for mode in router.availableModes {
            instructions.insert(mode.systemInstruction)
        }
        XCTAssertEqual(instructions.count, router.availableModes.count,
                        "Each mode should have a unique system instruction")
    }

    func test_eachMode_hasToolDeclarations() {
        let router = ModeRouter()
        for mode in router.availableModes {
            XCTAssertFalse(mode.toolDeclarations.isEmpty,
                           "\(mode.id) should have tool declarations")
        }
    }

    // MARK: - QR Auto-Switch with Frame

    func test_qrAutoSwitch_blankFrame_doesNotSwitch() {
        let router = ModeRouter()
        let blankImage = MockCameraSource.createTestImage(width: 10, height: 10, color: .white)
        router.checkAutoSwitch(transcript: "", frame: blankImage)
        XCTAssertEqual(router.currentMode.id, "assistant")
    }

    // MARK: - Mode Configuration for Gemini

    func test_modeConfigureFlow_withMockGeminiService() {
        let mockService = MockGeminiService()
        let router = ModeRouter()

        // Configure with current mode
        let mode = router.currentMode
        mockService.configure(
            systemInstruction: mode.systemInstruction,
            toolDeclarations: mode.toolDeclarations
        )

        XCTAssertEqual(mockService.configuredSystemInstruction, mode.systemInstruction)
        XCTAssertNotNil(mockService.configuredToolDeclarations)

        // Switch mode and reconfigure
        router.switchTo(id: "translator")
        let newMode = router.currentMode
        mockService.configure(
            systemInstruction: newMode.systemInstruction,
            toolDeclarations: newMode.toolDeclarations
        )

        XCTAssertEqual(mockService.configuredSystemInstruction, newMode.systemInstruction)
        XCTAssertTrue(mockService.configuredSystemInstruction?.contains("Mandarin") ?? false)
    }
}
