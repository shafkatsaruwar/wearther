import Foundation

enum ComfortFeedback: String, Codable, CaseIterable {
    case tooCold = "too_cold"
    case perfect
    case tooHot = "too_hot"
}

struct ComfortPreference: Codable, Equatable {
    var warmthBias: Double
    var feedbackCount: Int
    var lastFeedback: ComfortFeedback?
    var updatedAt: String

    static let `default` = ComfortPreference(
        warmthBias: 0,
        feedbackCount: 0,
        lastFeedback: nil,
        updatedAt: ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: 0))
    )
}

struct OutfitRecommendation: Equatable {
    let title: String
    let items: [String]
    let explanation: String
    let warmthLevel: Double
    let bringLater: String?
}
