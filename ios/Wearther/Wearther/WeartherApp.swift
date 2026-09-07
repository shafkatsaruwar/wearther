import SwiftUI

@main
struct WeartherApp: App {
    @State private var showOnboarding = !ComfortStore.hasCompletedOnboarding
    @Environment(\.scenePhase) private var scenePhase

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
            .task {
                await RemoteConfigStore.refreshIfNeeded()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task { await RemoteConfigStore.refreshIfNeeded() }
            }
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
