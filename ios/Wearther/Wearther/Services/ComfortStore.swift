import Foundation

enum ComfortStore {
    private static let comfortKey = "wearther:comfort-preference"
    private static let locationKey = "wearther:selected-location"

    static func loadComfortPreference() -> ComfortPreference {
        guard let data = UserDefaults.standard.data(forKey: comfortKey),
              let parsed = try? JSONDecoder().decode(ComfortPreference.self, from: data)
        else {
            return .default
        }

        return ComfortPreference(
            warmthBias: clamp(parsed.warmthBias, min: -8, max: 8),
            feedbackCount: parsed.feedbackCount,
            lastFeedback: parsed.lastFeedback,
            updatedAt: parsed.updatedAt
        )
    }

    static func saveComfortPreference(_ pref: ComfortPreference) {
        guard let data = try? JSONEncoder().encode(pref) else { return }
        UserDefaults.standard.set(data, forKey: comfortKey)
    }

    static func applyFeedback(_ current: ComfortPreference, feedback: ComfortFeedback) -> ComfortPreference {
        var bias = current.warmthBias

        switch feedback {
        case .tooCold:
            bias = clamp(bias + 2, min: -8, max: 8)
        case .tooHot:
            bias = clamp(bias - 2, min: -8, max: 8)
        case .perfect:
            if bias > 0 { bias = max(0, bias - 0.5) }
            if bias < 0 { bias = min(0, bias + 0.5) }
        }

        let next = ComfortPreference(
            warmthBias: bias,
            feedbackCount: current.feedbackCount + 1,
            lastFeedback: feedback,
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        saveComfortPreference(next)
        return next
    }

    static func loadSavedLocation() -> LocationResult {
        guard let data = UserDefaults.standard.data(forKey: locationKey),
              let location = try? JSONDecoder().decode(LocationResult.self, from: data)
        else {
            return MockWeatherProvider.defaultCity
        }
        return location
    }

    static func saveLocation(_ location: LocationResult) {
        guard let data = try? JSONEncoder().encode(location) else { return }
        UserDefaults.standard.set(data, forKey: locationKey)
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.min(max, Swift.max(min, value))
    }
}
