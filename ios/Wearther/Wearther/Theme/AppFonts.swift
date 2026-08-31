import SwiftUI
import UIKit

/// Typography matching the web app: Outfit (sans) + Fraunces (display).
/// Uses PostScript names from bundled static TTFs — never chain `.weight()` on
/// `Font.custom`, or iOS silently falls back to San Francisco.
enum AppFont {
    private enum Sans {
        static let regular = "Outfit-Regular"
        static let medium = "Outfit-Medium"
        static let semibold = "Outfit-SemiBold"
    }

    private enum Display {
        static let regular = "Fraunces72pt-Regular"
        static let semibold = "Fraunces72pt-SemiBold"
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(psName(Sans.self, weight: weight), size: size)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(psName(Display.self, weight: weight), size: size)
    }

    static let appTitle = display(28)
    static let cityName = display(34)
    static let temperature = display(72)
    static let outfitTitle = display(36)
    static let hourlyTemp = sans(20, weight: .medium)

    static let body = sans(17)
    static let subheadline = sans(15)
    static let subheadlineMedium = sans(15, weight: .medium)
    static let caption = sans(12)
    static let captionSemibold = sans(12, weight: .semibold)
    static let caption2 = sans(11)
    static let labelCaps = sans(11, weight: .medium)

    /// Debug helper — call once at launch to verify fonts are in the bundle.
    static func verifyBundledFonts() {
        #if DEBUG
        let required = [
            Sans.regular, Sans.medium, Sans.semibold,
            Display.regular, Display.semibold,
        ]
        for name in required where UIFont(name: name, size: 12) == nil {
            assertionFailure("Missing bundled font: \(name)")
        }
        #endif
    }

    private static func psName(_ family: Any.Type, weight: Font.Weight) -> String {
        switch weight {
        case .semibold, .bold, .heavy, .black:
            return family == Sans.self ? Sans.semibold : Display.semibold
        case .medium:
            return family == Sans.self ? Sans.medium : Display.regular
        default:
            return family == Sans.self ? Sans.regular : Display.regular
        }
    }
}
