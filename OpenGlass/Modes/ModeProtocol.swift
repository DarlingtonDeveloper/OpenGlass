import UIKit

/// Protocol that defines a mode for OpenGlass.
/// Each mode provides its own system instruction, tool declarations, and activation logic.
protocol GlassMode {
    var id: String { get }
    var name: String { get }
    var icon: String { get }  // SF Symbol name
    var systemInstruction: String { get }
    var toolDeclarations: [[String: Any]] { get }
    var activationPhrases: [String] { get }  // voice triggers

    /// Check if this mode should auto-activate based on transcript or camera frame.
    func shouldAutoActivate(transcript: String, frame: UIImage?) -> Bool
}

extension GlassMode {
    /// Default implementation: check if transcript contains any activation phrase.
    func shouldAutoActivate(transcript: String, frame: UIImage?) -> Bool {
        let lower = transcript.lowercased()
        return activationPhrases.contains { lower.contains($0.lowercased()) }
    }
}
