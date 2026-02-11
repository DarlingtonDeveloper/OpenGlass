import UIKit

/// QR code scanner mode — detects and acts on QR codes in the camera feed.
struct QRScannerMode: GlassMode {
    let id = "qr_scanner"
    let name = "QR Scanner"
    let icon = "qrcode.viewfinder"

    let systemInstruction = """
        You are a QR code assistant for someone wearing smart glasses.

        Your primary job is to help the user with QR codes they encounter:
        - When a QR code is detected in the camera feed, tell the user what it contains.
        - For URLs: briefly describe what the link appears to be and ask if they want to open it or get more info.
        - For WiFi codes: read out the network name and offer to connect.
        - For vCards: read out the contact name and key details.
        - For plain text: read it out.

        Use the execute tool to take actions:
        - Open URLs in the user's browser
        - Save contact information
        - Connect to WiFi networks
        - Any other action based on QR content

        Keep responses brief and action-oriented. The user is scanning QR codes for quick actions, not conversation.
        """

    var toolDeclarations: [[String: Any]] {
        [ToolDeclarations.execute]
    }

    let activationPhrases: [String] = [
        "switch to qr",
        "qr mode",
        "qr scanner",
        "scan qr",
        "scan this code"
    ]

    func shouldAutoActivate(transcript: String, frame: UIImage?) -> Bool {
        // Voice trigger
        let lower = transcript.lowercased()
        if activationPhrases.contains(where: { lower.contains($0) }) {
            return true
        }

        // Auto-activate if a QR code is detected in the frame
        if let frame {
            let detector = QRDetector()
            let codes = detector.scan(frame)
            if !codes.isEmpty {
                return true
            }
        }

        return false
    }
}
