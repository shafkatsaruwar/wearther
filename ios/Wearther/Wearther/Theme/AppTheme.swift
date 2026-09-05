import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.043, green: 0.310, blue: 0.286) // #0B4F49
    static let accentSoft = Color(red: 0.235, green: 0.482, blue: 0.412) // #3C7B69
    static let coral = Color(red: 0.898, green: 0.435, blue: 0.357) // #E56F5B
    static let ink = Color(red: 0.090, green: 0.125, blue: 0.153) // #172027
    static let inkSoft = Color(red: 0.20, green: 0.26, blue: 0.24)
    static let inkMuted = Color(red: 0.30, green: 0.37, blue: 0.34)
    static let inkFaint = Color(red: 0.43, green: 0.50, blue: 0.47)
    static let line = Color(red: 0.09, green: 0.125, blue: 0.153).opacity(0.10)
    static let surface = Color(red: 1.0, green: 0.992, blue: 0.965).opacity(0.86) // cream
    static let surfaceHover = Color(red: 1.0, green: 0.992, blue: 0.965).opacity(0.96)
    static let fitSurface = Color(red: 1.0, green: 0.992, blue: 0.965)
    static let fitIconBg = Color(red: 0.043, green: 0.310, blue: 0.286).opacity(0.07)
    static let mint = Color(red: 0.847, green: 0.933, blue: 0.906) // #D8EEE7
    static let sky = Color(red: 0.875, green: 0.933, blue: 0.961) // #DFEEF5
    static let cream = Color(red: 1.0, green: 0.992, blue: 0.965) // #FFFDF6
    static let bgTop = Color(red: 0.875, green: 0.933, blue: 0.961)
    static let bgMid = Color(red: 0.910, green: 0.949, blue: 0.957)
    static let bgBottom = Color(red: 0.847, green: 0.933, blue: 0.906)
    static let cardRadius: CGFloat = 28
    static let statRadius: CGFloat = 20
}

struct AtmosphereBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.bgTop, AppTheme.bgMid, AppTheme.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.43, green: 0.59, blue: 0.65).opacity(0.28), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 220
                    )
                )
                .frame(width: 440, height: 440)
                .offset(x: -120, y: -180)
                .blur(radius: 40)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppTheme.coral.opacity(0.14), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 140, y: 320)
                .blur(radius: 36)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
    }
}

struct CardSurface: ViewModifier {
    var radius: CGFloat = AppTheme.cardRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .stroke(AppTheme.line, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.ink.opacity(0.08), radius: 18, y: 8)
            )
    }
}

extension View {
    func cardSurface(radius: CGFloat = AppTheme.cardRadius) -> some View {
        modifier(CardSurface(radius: radius))
    }
}
