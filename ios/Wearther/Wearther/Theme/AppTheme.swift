import SwiftUI
import UIKit

enum AppTheme {
    static let accent = Color(red: 0.24, green: 0.42, blue: 0.37)
    static let ink = Color(red: 0.10, green: 0.12, blue: 0.14)
    static let inkSoft = Color(red: 0.23, green: 0.26, blue: 0.29)
    static let inkMuted = Color(red: 0.42, green: 0.45, blue: 0.50)
    static let inkFaint = Color(red: 0.60, green: 0.64, blue: 0.68)
    static let line = Color.black.opacity(0.08)
    static let surface = Color.white.opacity(0.48)
    static let surfaceHover = Color.white.opacity(0.82)
    static let fitSurface = Color.white.opacity(0.55)
    static let fitIconBg = Color.black.opacity(0.04)
    static let bgTop = Color(red: 0.87, green: 0.90, blue: 0.93)
    static let bgMid = Color(red: 0.91, green: 0.93, blue: 0.95)
    static let bgBottom = Color(red: 0.89, green: 0.91, blue: 0.90)

    /// Matches `LaunchBackground` in the asset catalog / Info.plist launch screen.
    static let uiBackground = UIColor(
        red: 0.91,
        green: 0.93,
        blue: 0.95,
        alpha: 1
    )
}

/// Full-bleed atmosphere that never expands layout (offset glows stay clipped).
struct AtmosphereBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppTheme.bgMid

                LinearGradient(
                    colors: [AppTheme.bgTop, AppTheme.bgMid, AppTheme.bgBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.43, green: 0.59, blue: 0.65).opacity(0.32),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 220
                        )
                    )
                    .frame(width: 440, height: 440)
                    .position(x: 40, y: 40)
                    .blur(radius: 40)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.51, green: 0.59, blue: 0.55).opacity(0.22),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 180
                        )
                    )
                    .frame(width: 360, height: 360)
                    .position(x: geo.size.width - 20, y: geo.size.height * 0.72)
                    .blur(radius: 36)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea(.all)
    }
}
