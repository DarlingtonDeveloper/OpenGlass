import SwiftUI

@main
struct OpenGlassApp: App {
    @StateObject private var sessionViewModel = GeminiSessionViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sessionViewModel)
                .environmentObject(sessionViewModel.modeRouter)
        }
    }
}
