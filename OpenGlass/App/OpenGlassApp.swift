import MWDATCore
import SwiftUI

@main
struct OpenGlassApp: App {
    @StateObject private var sessionViewModel = GeminiSessionViewModel()

    init() {
        do {
            try Wearables.configure()
        } catch {
            NSLog("[OpenGlass] Failed to configure Wearables SDK: %@", error.localizedDescription)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionViewModel)
                .environmentObject(sessionViewModel.modeRouter)
                .onOpenURL { url in
                    guard
                        let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                        components.queryItems?.contains(where: { $0.name == "metaWearablesAction" }) == true
                    else {
                        return
                    }
                    Task {
                        do {
                            _ = try await Wearables.shared.handleUrl(url)
                        } catch {
                            NSLog("[OpenGlass] Failed to handle DAT URL: %@", error.localizedDescription)
                        }
                    }
                }
        }
    }
}
