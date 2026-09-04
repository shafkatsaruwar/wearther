import CoreText
import SwiftUI
import UIKit

/// Typography matching the web app: Outfit (sans) + Fraunces (display).
///
/// Fonts are registered at launch via Core Text (not only `UIAppFonts`), because
/// Xcode copies group resources to the bundle root — so `Fonts/foo.ttf` in
/// Info.plist often fails to find the file.
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

    private static let bundledFiles = [
        "Outfit-Regular",
        "Outfit-Medium",
        "Outfit-SemiBold",
        "Fraunces-Regular",
        "Fraunces-SemiBold",
        "Fraunces-72pt-Regular",
        "Fraunces-72pt-SemiBold",
    ]

    /// Call once before any view that uses these fonts is created.
    static func registerBundledFonts() {
        for name in bundledFiles {
            guard let url = fontURL(named: name) else {
                print("[Wearther] Font file not found in bundle: \(name).ttf")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                // Already registered is fine; anything else is worth logging.
                if let error {
                    print("[Wearther] Font register warning for \(name): \(error.takeUnretainedValue())")
                }
            }
        }

        #if DEBUG
        let required = [Sans.regular, Sans.medium, Sans.semibold, Display.regular, Display.semibold]
        for name in required {
            if UIFont(name: name, size: 12) == nil {
                print("[Wearther] UIFont lookup failed for PostScript name: \(name)")
                print("[Wearther] Available families: \(UIFont.familyNames.sorted())")
            }
        }
        #endif
    }

    static func sans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        uiFont(psName(.sans, weight: weight), size: size)
    }

    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        uiFont(psName(.display, weight: weight), size: size)
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

    private enum FontFamily {
        case sans, display
    }

    private static func psName(_ family: FontFamily, weight: Font.Weight) -> String {
        switch (family, weight) {
        case (.sans, .semibold), (.sans, .bold), (.sans, .heavy), (.sans, .black):
            return Sans.semibold
        case (.sans, .medium):
            return Sans.medium
        case (.sans, _):
            return Sans.regular
        case (.display, .semibold), (.display, .bold), (.display, .heavy), (.display, .black):
            return Display.semibold
        default:
            return Display.regular
        }
    }

    private static func uiFont(_ postScriptName: String, size: CGFloat) -> Font {
        if let ui = UIFont(name: postScriptName, size: size) {
            return Font(ui)
        }
        // Fallback keeps the app usable if registration failed.
        return Font.custom(postScriptName, size: size)
    }

    private static func fontURL(named name: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts")
    }
}
