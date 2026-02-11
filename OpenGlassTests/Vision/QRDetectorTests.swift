import XCTest
@testable import OpenGlass

final class QRDetectorTests: XCTestCase {

    let testBounds = CGRect(x: 0, y: 0, width: 100, height: 100)

    // MARK: - URL Detection

    func test_parse_validHTTPSURL_returnsURLType() {
        let content = QRContent.parse("https://example.com", bounds: testBounds)
        if case .url(let url) = content.type {
            XCTAssertEqual(url.absoluteString, "https://example.com")
        } else {
            XCTFail("Expected URL type, got \(content.type)")
        }
    }

    func test_parse_validHTTPURL_returnsURLType() {
        let content = QRContent.parse("http://test.org/path?q=1", bounds: testBounds)
        if case .url(let url) = content.type {
            XCTAssertEqual(url.host, "test.org")
        } else {
            XCTFail("Expected URL type")
        }
    }

    func test_parse_schemalessString_returnsText() {
        // "example.com" has no scheme, so URL(string:)?.scheme is nil
        let content = QRContent.parse("example.com", bounds: testBounds)
        if case .text(let text) = content.type {
            XCTAssertEqual(text, "example.com")
        } else {
            XCTFail("Expected text type for schemeless URL")
        }
    }

    // MARK: - WiFi Parsing

    func test_parse_wifiString_extractsFields() {
        let wifi = "WIFI:T:WPA;S:MyNetwork;P:secretpass;;"
        let content = QRContent.parse(wifi, bounds: testBounds)
        if case .wifi(let ssid, let password, let encryption) = content.type {
            XCTAssertEqual(ssid, "MyNetwork")
            XCTAssertEqual(password, "secretpass")
            XCTAssertEqual(encryption, "WPA")
        } else {
            XCTFail("Expected wifi type, got \(content.type)")
        }
    }

    func test_parse_wifiWPA2_parsesEncryption() {
        let wifi = "WIFI:S:Office;T:WPA2;P:p@ss123;;"
        let content = QRContent.parse(wifi, bounds: testBounds)
        if case .wifi(let ssid, let password, let encryption) = content.type {
            XCTAssertEqual(ssid, "Office")
            XCTAssertEqual(password, "p@ss123")
            XCTAssertEqual(encryption, "WPA2")
        } else {
            XCTFail("Expected wifi type")
        }
    }

    func test_parse_wifiNoPassword_emptyPassword() {
        let wifi = "WIFI:S:OpenNetwork;T:nopass;;"
        let content = QRContent.parse(wifi, bounds: testBounds)
        if case .wifi(let ssid, let password, _) = content.type {
            XCTAssertEqual(ssid, "OpenNetwork")
            XCTAssertEqual(password, "")
        } else {
            XCTFail("Expected wifi type")
        }
    }

    // MARK: - vCard Detection

    func test_parse_vCard_returnsVCardType() {
        let vcard = "BEGIN:VCARD\nVERSION:3.0\nFN:John Doe\nTEL:+1234567890\nEND:VCARD"
        let content = QRContent.parse(vcard, bounds: testBounds)
        if case .vCard(let text) = content.type {
            XCTAssertTrue(text.contains("John Doe"))
        } else {
            XCTFail("Expected vCard type")
        }
    }

    // MARK: - Plain Text Fallback

    func test_parse_plainText_returnsTextType() {
        let content = QRContent.parse("Hello World 12345", bounds: testBounds)
        if case .text(let text) = content.type {
            XCTAssertEqual(text, "Hello World 12345")
        } else {
            XCTFail("Expected text type")
        }
    }

    func test_parse_emptyString_returnsTextType() {
        let content = QRContent.parse("", bounds: testBounds)
        if case .text(let text) = content.type {
            XCTAssertEqual(text, "")
        } else {
            XCTFail("Expected text type for empty string")
        }
    }

    // MARK: - Raw Value Preserved

    func test_parse_rawValue_isPreserved() {
        let raw = "WIFI:S:Test;T:WPA;P:pass;;"
        let content = QRContent.parse(raw, bounds: testBounds)
        XCTAssertEqual(content.rawValue, raw)
    }

    func test_parse_bounds_arePreserved() {
        let bounds = CGRect(x: 10, y: 20, width: 30, height: 40)
        let content = QRContent.parse("test", bounds: bounds)
        XCTAssertEqual(content.bounds, bounds)
    }

    // MARK: - QRDetector scan

    func test_scan_blankImage_returnsEmpty() {
        let detector = QRDetector()
        let image = MockCameraSource.createTestImage(width: 10, height: 10, color: .white)
        let results = detector.scan(image)
        XCTAssertTrue(results.isEmpty)
    }
}
