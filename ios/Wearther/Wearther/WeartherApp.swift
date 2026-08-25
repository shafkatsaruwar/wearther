import SwiftUI

@main
struct WeartherApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(nil)
        }
    }
}
