import Foundation

enum ComfortStore {
    private static let comfortKey = "wearther:comfort-preference"
    private static let locationKey = "wearther:selected-location"

    static func loadComfortPreference() -> ComfortPreference {
        guard let data = UserDefaults.standard.data(forKey: comfortKey) else {
            return .default
        }

        // Prefer full decode; fall back to legacy shape without new fields.
        if let parsed = try? JSONDecoder().decode(ComfortPreference.self, from: data) {
            return ComfortPreference(
                warmthBias: clamp(parsed.warmthBias, min: -8, max: 8),
                feedbackCount: parsed.feedbackCount,
                lastFeedback: parsed.lastFeedback,
                updatedAt: parsed.updatedAt,
                feelBaseline: parsed.feelBaseline,
                style: parsed.style,
                alwaysPack: parsed.alwaysPack,
                units: parsed.units
            )
        }

        struct Legacy: Codable {
            var warmthBias: Double
            var feedbackCount: Int
            var lastFeedback: ComfortFeedback?
            var updatedAt: String
        }

        if let legacy = try? JSONDecoder().decode(Legacy.self, from: data) {
            return ComfortPreference(
                warmthBias: clamp(legacy.warmthBias, min: -8, max: 8),
                feedbackCount: legacy.feedbackCount,
                lastFeedback: legacy.lastFeedback,
                updatedAt: legacy.updatedAt,
                feelBaseline: .average,
                style: .casual,
                alwaysPack: .default,
                units: .fahrenheit
            )
        }

        return .default
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

        var next = current
        next.warmthBias = bias
        next.feedbackCount = current.feedbackCount + 1
        next.lastFeedback = feedback
        next.updatedAt = ISO8601DateFormatter().string(from: Date())
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

enum TemperatureDisplay {
    static func value(_ fahrenheit: Int, units: TempUnits) -> Int {
        if units == .celsius {
            return Int(round(Double(fahrenheit - 32) * 5.0 / 9.0))
        }
        return fahrenheit
    }

    static func wind(_ mph: Int, units: TempUnits) -> String {
        if units == .celsius {
            return "\(Int(round(Double(mph) * 1.609))) km/h"
        }
        return "\(mph) mph"
    }
}
