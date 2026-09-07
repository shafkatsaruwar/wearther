import Foundation

enum ComfortFeedback: String, Codable, CaseIterable {
    case tooCold = "too_cold"
    case perfect
    case tooHot = "too_hot"
}

enum FeelBaseline: String, Codable, CaseIterable {
    case colder
    case average
    case warmer

    var label: String {
        switch self {
        case .colder: return "Colder than most"
        case .average: return "Average"
        case .warmer: return "Warmer than most"
        }
    }

    var offset: Double {
        switch self {
        case .colder: return 4
        case .average: return 0
        case .warmer: return -4
        }
    }
}

enum StyleMode: String, Codable, CaseIterable {
    case casual
    case smartCasual = "smart_casual"
    case athletic
    case formal

    var label: String {
        switch self {
        case .casual: return "Casual"
        case .smartCasual: return "Smart casual"
        case .athletic: return "Athletic"
        case .formal: return "Formal"
        }
    }
}

enum TempUnits: String, Codable, CaseIterable {
    case fahrenheit
    case celsius

    var symbol: String { self == .celsius ? "C" : "F" }
}

extension TempUnits {
    var degreeLabel: String { "°\(symbol)" }
}

struct AlwaysPackPrefs: Codable, Equatable {
    var rainJacket: Bool
    var lightLayer: Bool
    var scarf: Bool

    static let `default` = AlwaysPackPrefs(
        rainJacket: false,
        lightLayer: false,
        scarf: false
    )
}

struct ComfortPreference: Codable, Equatable {
    var warmthBias: Double
    var feedbackCount: Int
    var lastFeedback: ComfortFeedback?
    var updatedAt: String
    var feelBaseline: FeelBaseline
    var style: StyleMode
    var alwaysPack: AlwaysPackPrefs
    var units: TempUnits

    static let `default` = ComfortPreference(
        warmthBias: 0,
        feedbackCount: 0,
        lastFeedback: nil,
        updatedAt: ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: 0)),
        feelBaseline: .average,
        style: .casual,
        alwaysPack: .default,
        units: .fahrenheit
    )

    var effectiveWarmthBias: Double {
        min(8, max(-8, feelBaseline.offset + warmthBias))
    }
}

struct OutfitRecommendation: Equatable {
    let title: String
    let items: [String]
    let explanation: String
    let warmthLevel: Double
    let bringLater: String?
    /// Expandable “Why?” detail; optional for back-compat with older call sites.
    let whyDetail: String?

    init(
        title: String,
        items: [String],
        explanation: String,
        warmthLevel: Double,
        bringLater: String? = nil,
        whyDetail: String? = nil
    ) {
        self.title = title
        self.items = items
        self.explanation = explanation
        self.warmthLevel = warmthLevel
        self.bringLater = bringLater
        self.whyDetail = whyDetail
    }
}

enum MorningNotifyHour: Int, Codable, CaseIterable, Identifiable {
    case six = 6
    case seven = 7
    case eight = 8

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .six: return "6 AM"
        case .seven: return "7 AM"
        case .eight: return "8 AM"
        }
    }
}

struct NotificationPreference: Codable, Equatable {
    var enabled: Bool
    var hour: MorningNotifyHour
    var weekdaysOnly: Bool

    static let `default` = NotificationPreference(
        enabled: false,
        hour: .seven,
        weekdaysOnly: true
    )
}
