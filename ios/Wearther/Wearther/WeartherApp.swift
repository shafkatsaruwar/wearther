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
        }
    }
}
