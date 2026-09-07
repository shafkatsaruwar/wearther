import Foundation

enum ComfortStore {
    private static let comfortKey = "wearther:comfort-preference"
    private static let locationKey = "wearther:selected-location"
    private static let savedCitiesKey = "wearther:saved-cities"
    private static let onboardingKey = "wearther:onboarding-complete"
    private static let notificationKey = "wearther:notification-preference"
    private static let occasionKey = "wearther:occasion-context"

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
            return .boston
        }
        return location
    }

    static func saveLocation(_ location: LocationResult) {
        guard let data = try? JSONEncoder().encode(location) else { return }
        UserDefaults.standard.set(data, forKey: locationKey)
    }

    static var hasCompletedOnboarding: Bool {
        if UserDefaults.standard.object(forKey: onboardingKey) != nil {
            return UserDefaults.standard.bool(forKey: onboardingKey)
        }
        // Existing installs already chose a city — skip first-run onboarding.
        return UserDefaults.standard.data(forKey: locationKey) != nil
    }

    static func setOnboardingComplete(_ complete: Bool = true) {
        UserDefaults.standard.set(complete, forKey: onboardingKey)
    }

    static func loadSavedCities() -> [LocationResult] {
        guard let data = UserDefaults.standard.data(forKey: savedCitiesKey),
              let cities = try? JSONDecoder().decode([LocationResult].self, from: data)
        else {
            // Seed with the currently selected city so favorites never start empty.
            let current = loadSavedLocation()
            saveSavedCities([current])
            return [current]
        }
        return cities
    }

    static func saveSavedCities(_ cities: [LocationResult]) {
        guard let data = try? JSONEncoder().encode(cities) else { return }
        UserDefaults.standard.set(data, forKey: savedCitiesKey)
    }

    static func isCitySaved(_ location: LocationResult) -> Bool {
        loadSavedCities().contains(where: { $0.id == location.id })
    }

    @discardableResult
    static func toggleSavedCity(_ location: LocationResult) -> [LocationResult] {
        var cities = loadSavedCities()
        if let index = cities.firstIndex(where: { $0.id == location.id }) {
            cities.remove(at: index)
        } else {
            cities.insert(location, at: 0)
        }
        saveSavedCities(cities)
        return cities
    }

    @discardableResult
    static func addSavedCity(_ location: LocationResult) -> [LocationResult] {
        var cities = loadSavedCities()
        cities.removeAll { $0.id == location.id }
        cities.insert(location, at: 0)
        saveSavedCities(cities)
        return cities
    }

    static func loadNotificationPreference() -> NotificationPreference {
        guard let data = UserDefaults.standard.data(forKey: notificationKey),
              let pref = try? JSONDecoder().decode(NotificationPreference.self, from: data)
        else {
            return .default
        }
        return pref
    }

    static func saveNotificationPreference(_ pref: NotificationPreference) {
        guard let data = try? JSONEncoder().encode(pref) else { return }
        UserDefaults.standard.set(data, forKey: notificationKey)
    }

    static func loadOccasionContext() -> OccasionContext {
        guard let raw = UserDefaults.standard.string(forKey: occasionKey),
              let value = OccasionContext(rawValue: raw)
        else {
            return .everyday
        }
        return value
    }

    static func saveOccasionContext(_ context: OccasionContext) {
        UserDefaults.standard.set(context.rawValue, forKey: occasionKey)
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
