import SwiftUI

@main
struct WeartherApp: App {
    init() {
        AppFont.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.light)
        }
    }
}
