// OpenGlass - QRScannerMode.swift

import Foundation

/// QR code detection and action mode.
/// TODO: Enable continuous QR detection from camera frames
/// TODO: Parse QR payload and present actions (open URL, add contact, etc.)
/// TODO: Trigger OpenClaw skills based on QR content
/// TODO: Mostly local processing — minimal Gemini interaction
struct QRScannerMode: OpenGlassMode {
    let id = "qr_scanner"
    let displayName = "QR Scanner"
    let systemInstruction = "QR scanning mode is active. When a QR code is detected, help the user understand its content and suggest actions."
    let enabledTools = ["open_url", "add_contact"]

    func activate() { /* TODO: Start QR detection */ }
    func deactivate() { /* TODO: Stop QR detection */ }
}
