// OpenGlass - OpenGlassConfig.swift

import Foundation

/// Central configuration for OpenGlass.
/// TODO: Store and retrieve Gemini API key (Keychain)
/// TODO: Store OpenClaw gateway URL (UserDefaults)
/// TODO: Frame rate setting (default 1fps)
/// TODO: JPEG quality setting (default 0.8)
/// TODO: Audio sample rate (default 16000)
/// TODO: Active mode persistence
/// TODO: Custom mode configurations (JSON export/import)
struct OpenGlassConfig {
    static let defaultFrameRate: Double = 1.0
    static let defaultJPEGQuality: CGFloat = 0.8
    static let defaultAudioSampleRate: Double = 16000.0
    static let openClawDefaultPort: Int = 18789
}
