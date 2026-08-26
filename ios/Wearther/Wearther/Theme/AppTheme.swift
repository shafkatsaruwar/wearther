import SwiftUI

enum AppTheme {
    /// Dark Wine
    static let darkWine = Color(red: 0x6F / 255, green: 0x1D / 255, blue: 0x1B / 255)
    /// Linen
    static let linen = Color(red: 0xF0 / 255, green: 0xE5 / 255, blue: 0xDE / 255)
    /// Ash Grey
    static let ashGrey = Color(red: 0xAD / 255, green: 0xBD / 255, blue: 0xAB / 255)

    static let accent = darkWine
    static let ink = Color(red: 0.18, green: 0.10, blue: 0.09)
    static let inkSoft = Color(red: 0.32, green: 0.22, blue: 0.20)
    static let inkMuted = Color(red: 0.45, green: 0.36, blue: 0.33)
    static let inkFaint = Color(red: 0.58, green: 0.50, blue: 0.46)
    static let line = darkWine.opacity(0.12)
    static let surface = Color.white.opacity(0.72)
    static let surfaceHover = Color.white.opacity(0.92)
    static let fitSurface = Color.white.opacity(0.82)
    static let fitIconBg = darkWine.opacity(0.06)
    static let bgTop = linen
    static let bgMid = ashGrey
    static let bgBottom = linen
}

/// Soft wine / ash / linen atmosphere from the brand palette (no text).
struct AtmosphereBackground: View {
    var body: some View {
        GeometryReader { geo in
            Image("Atmosphere")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay {
                    // Soft fallback blend if the asset ever fails to load.
                    LinearGradient(
                        stops: [
                            .init(color: AppTheme.linen.opacity(0.15), location: 0),
                            .init(color: .clear, location: 0.35),
                            .init(color: AppTheme.ashGrey.opacity(0.12), location: 0.55),
                            .init(color: AppTheme.linen.opacity(0.35), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                }
        }
        .background(AppTheme.linen)
        .ignoresSafeArea()
    }
}
