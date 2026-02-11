import XCTest
@testable import OpenGlass

final class QRScannerModeTests: XCTestCase {
    let sut = QRScannerMode()

    func test_id() { XCTAssertEqual(sut.id, "qr_scanner") }
    func test_name() { XCTAssertEqual(sut.name, "QR Scanner") }
    func test_icon() { XCTAssertEqual(sut.icon, "qrcode.viewfinder") }

    func test_systemInstruction_containsExpectedKeywords() {
        XCTAssertTrue(sut.systemInstruction.contains("QR"))
        XCTAssertTrue(sut.systemInstruction.contains("URL"))
        XCTAssertTrue(sut.systemInstruction.contains("WiFi"))
    }

    func test_toolDeclarations_containsExecute() {
        let names = sut.toolDeclarations.compactMap { $0["name"] as? String }
        XCTAssertTrue(names.contains("execute"))
    }

    func test_activationPhrases() {
        XCTAssertTrue(sut.activationPhrases.contains("qr mode"))
        XCTAssertTrue(sut.activationPhrases.contains("scan qr"))
        XCTAssertTrue(sut.activationPhrases.contains("scan this code"))
    }

    func test_shouldAutoActivate_voiceTrigger_returnsTrue() {
        XCTAssertTrue(sut.shouldAutoActivate(transcript: "scan qr code", frame: nil))
    }

    func test_shouldAutoActivate_noMatch_returnsFalse() {
        XCTAssertFalse(sut.shouldAutoActivate(transcript: "hello there", frame: nil))
    }

    // QRScannerMode overrides shouldAutoActivate to also check frames for QR codes.
    // Testing with a blank image (no QR) should return false.
    func test_shouldAutoActivate_blankFrame_noQR_returnsFalse() {
        let blankImage = MockCameraSource.createTestImage(width: 10, height: 10, color: .white)
        XCTAssertFalse(sut.shouldAutoActivate(transcript: "", frame: blankImage))
    }
}
