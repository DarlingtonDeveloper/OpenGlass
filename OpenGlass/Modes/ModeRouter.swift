import Foundation
import UIKit

@MainActor
class ModeRouter: ObservableObject {
    @Published var currentMode: any GlassMode
    @Published var availableModes: [any GlassMode]

    /// Callback fired when mode changes. The session should reconnect with new instructions.
    var onModeChanged: ((any GlassMode) -> Void)?

    init() {
        let modes: [any GlassMode] = [
            AssistantMode(),
            TranslatorMode(),
            QRScannerMode(),
            SpotterMode(),
            CoachMode(),
            SocialMode()
        ]
        self.availableModes = modes
        self.currentMode = modes[0]
    }

    func switchTo(_ mode: any GlassMode) {
        guard mode.id != currentMode.id else { return }
        NSLog("[ModeRouter] Switching from %@ to %@", currentMode.id, mode.id)
        currentMode = mode
        onModeChanged?(mode)
    }

    func switchTo(id: String) {
        guard let mode = availableModes.first(where: { $0.id == id }) else { return }
        switchTo(mode)
    }

    /// Called on each transcript update to check for voice-triggered mode switches.
    func checkAutoSwitch(transcript: String, frame: UIImage?) {
        for mode in availableModes where mode.id != currentMode.id {
            if mode.shouldAutoActivate(transcript: transcript, frame: frame) {
                switchTo(mode)
                return
            }
        }
    }
}
