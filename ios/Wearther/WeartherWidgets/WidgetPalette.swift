import CoreText
import SwiftUI
import UIKit

enum WidgetPalette {
    static let deepTeal = Color(red: 0.043, green: 0.310, blue: 0.286) // #0B4F49
    static let sage = Color(red: 0.235, green: 0.482, blue: 0.412) // #3C7B69
    static let coral = Color(red: 0.898, green: 0.435, blue: 0.357) // #E56F5B
    static let cream = Color(red: 1.0, green: 0.992, blue: 0.965) // #FFFDF6
    static let paleSky = Color(red: 0.875, green: 0.933, blue: 0.961) // #DFEEF5
    static let mint = Color(red: 0.847, green: 0.933, blue: 0.906) // #D8EEE7
    static let ink = Color(red: 0.090, green: 0.125, blue: 0.153) // #172027
    static let sun = Color(red: 0.96, green: 0.78, blue: 0.35)

    private static let registerFonts: Void = {
        let names = [
            "Outfit-Regular",
            "Outfit-Medium",
            "Outfit-SemiBold",
            "Fraunces-72pt-Regular",
            "Fraunces-72pt-SemiBold",
        ]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()

    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        _ = registerFonts
        let name = (weight == .regular) ? "Fraunces72pt-Regular" : "Fraunces72pt-SemiBold"
        if let ui = UIFont(name: name, size: size) {
            return Font(ui)
        }
        return .system(size: size, weight: weight == .regular ? .regular : .semibold, design: .serif)
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        _ = registerFonts
        let name: String
        switch weight {
        case .semibold, .bold, .heavy, .black:
            name = "Outfit-SemiBold"
        case .medium:
            name = "Outfit-Medium"
        default:
            name = "Outfit-Regular"
        }
        if let ui = UIFont(name: name, size: size) {
            return Font(ui)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }
}
