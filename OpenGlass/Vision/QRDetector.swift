import UIKit
import CoreImage

/// Detected QR code content with type classification.
struct QRContent {
    enum ContentType {
        case url(URL)
        case wifi(ssid: String, password: String, encryption: String)
        case vCard(String)
        case text(String)
    }

    let rawValue: String
    let type: ContentType
    let bounds: CGRect

    /// Parse raw QR string into a typed content.
    static func parse(_ string: String, bounds: CGRect) -> QRContent {
        // URL
        if let url = URL(string: string), url.scheme != nil {
            return QRContent(rawValue: string, type: .url(url), bounds: bounds)
        }

        // WiFi: WIFI:S:<ssid>;T:<encryption>;P:<password>;;
        if string.hasPrefix("WIFI:") {
            var ssid = "", password = "", encryption = ""
            let body = String(string.dropFirst(5))
            for component in body.split(separator: ";") {
                let part = String(component)
                if part.hasPrefix("S:") { ssid = String(part.dropFirst(2)) }
                else if part.hasPrefix("P:") { password = String(part.dropFirst(2)) }
                else if part.hasPrefix("T:") { encryption = String(part.dropFirst(2)) }
            }
            return QRContent(rawValue: string, type: .wifi(ssid: ssid, password: password, encryption: encryption), bounds: bounds)
        }

        // vCard
        if string.hasPrefix("BEGIN:VCARD") {
            return QRContent(rawValue: string, type: .vCard(string), bounds: bounds)
        }

        // Plain text
        return QRContent(rawValue: string, type: .text(string), bounds: bounds)
    }
}

/// Scans UIImages for QR codes using CIDetector.
class QRDetector {
    private let detector: CIDetector?
    private let context = CIContext()

    init() {
        detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
    }

    /// Scan an image for QR codes. Returns all detected codes.
    func scan(_ image: UIImage) -> [QRContent] {
        guard let ciImage = CIImage(image: image) else { return [] }
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] else { return [] }

        return features.compactMap { feature in
            guard let message = feature.messageString else { return nil }
            return QRContent.parse(message, bounds: feature.bounds)
        }
    }
}
