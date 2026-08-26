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

    // MARK: - Typography
    // Playfair Display for headlines, Literata for body — warm serif pairing.

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black:
            name = "PlayfairDisplay-SemiBold"
        default:
            name = "PlayfairDisplay-Regular"
        }
        return .custom(name, size: size)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .medium:
            name = "Literata-Medium"
        case .semibold, .bold, .heavy, .black:
            name = "Literata-SemiBold"
        default:
            name = "Literata-Regular"
        }
        return .custom(name, size: size)
    }

    static let titleCity = display(34, weight: .semibold)
    static let titleOutfit = display(30, weight: .regular)
    static let titleTemp = display(68, weight: .regular)
    static let titleSection = display(22, weight: .semibold)
    static let titleSweata = display(28, weight: .semibold)
    static let titleTomorrowTemp = display(44, weight: .regular)

    static let body = sans(16)
    static let bodyMedium = sans(16, weight: .medium)
    static let callout = sans(15)
    static let subheadline = sans(14)
    static let subheadlineMedium = sans(14, weight: .medium)
    static let subheadlineSemibold = sans(14, weight: .semibold)
    static let caption = sans(12)
    static let captionMedium = sans(12, weight: .medium)
    static let captionSemibold = sans(12, weight: .semibold)
    static let overline = sans(11, weight: .semibold)
    static let micro = sans(11, weight: .semibold)
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
