import SwiftUI

/// Typography matching the web app: Outfit (sans) + Fraunces (display).
enum AppFont {
    private static let sansFamily = "Outfit"
    private static let displayFamily = "Fraunces"

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(sansFamily, size: size).weight(weight)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(displayFamily, size: size).weight(weight)
    }

    static let appTitle = display(28)
    static let cityName = display(34)
    static let temperature = display(72)
    static let outfitTitle = display(36)
    static let hourlyTemp = sans(20, weight: .medium)

    static let body = sans(17)
    static let subheadline = sans(15)
    static let caption = sans(12)
    static let caption2 = sans(11)
    static let labelCaps = sans(11, weight: .medium)
}
