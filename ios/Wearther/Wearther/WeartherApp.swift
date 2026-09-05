import SwiftUI
import UIKit

@main
struct WeartherApp: App {
    init() {
        AppFont.registerBundledFonts()
        Self.configureWindowAppearance()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
                .background(AppTheme.bgMid.ignoresSafeArea(.all))
                .onAppear { Self.configureWindowAppearance() }
        }
    }

    /// Prevents black letterboxing at device rounded corners / safe areas.
    private static func configureWindowAppearance() {
        UIWindow.appearance().backgroundColor = AppTheme.uiBackground

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.backgroundColor = AppTheme.uiBackground
            }
        }
    }
}
