import SwiftUI

@main
struct WeartherApp: App {
    @State private var showOnboarding = !ComfortStore.hasCompletedOnboarding

    init() {
        AppFont.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if showOnboarding {
                    OnboardingView {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showOnboarding = false
                        }
                    }
                } else {
                    HomeView()
                }
            }
            .preferredColorScheme(.light)
            .onOpenURL { url in
                // Widgets deep-link with wearther://home
                guard url.scheme == "wearther" else { return }
                if url.host == "home" || url.path == "/home" {
                    showOnboarding = false
                }
            }
        }
    }
}
