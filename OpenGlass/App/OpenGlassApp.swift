import MWDATCore
import SwiftUI

@main
struct OpenGlassApp: App {
    @StateObject private var sessionViewModel = GeminiSessionViewModel()

    init() {
        do {
            try Wearables.configure()
            NSLog("[OpenGlass] Wearables SDK configured — registration: %@, devices: %d",
                  Wearables.shared.registrationState.description,
                  Wearables.shared.devices.count)
        } catch {
            NSLog("[OpenGlass] ⚠️ Wearables.configure() FAILED: %@", "\(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionViewModel)
                .environmentObject(sessionViewModel.modeRouter)
                .onOpenURL { url in
                    NSLog("[OpenGlass] onOpenURL: %@", url.absoluteString)
                    Task {
                        do {
                            let handled = try await Wearables.shared.handleUrl(url)
                            NSLog("[OpenGlass] handleUrl result: %@", handled ? "handled" : "not handled")
                        } catch {
                            NSLog("[OpenGlass] handleUrl error: %@", "\(error)")
                        }
                    }
                }
        }
    }
}
