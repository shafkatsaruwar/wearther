import Foundation

enum FitConfidence: String, Equatable {
    case confident = "Confident"
    case bringBackup = "Bring backup"
    case rainRisk = "Rain risk"
    case eveningDrop = "Evening drop"
    case tunedForYou = "Tuned for you"

    var systemImage: String {
        switch self {
        case .confident: return "checkmark"
        case .bringBackup: return "bag"
        case .rainRisk: return "cloud.rain"
        case .eveningDrop: return "moon.stars"
        case .tunedForYou: return "slider.horizontal.3"
        }
    }
}

enum FitCopy {
    static func formatTitle(_ outfit: OutfitRecommendation) -> String {
        let jacketOptions: String.CompareOptions = [.regularExpression, .caseInsensitive]
        let hasJacket = outfit.items.contains {
            $0.range(of: "jacket|coat|bring", options: jacketOptions) != nil
        }
        if hasJacket || outfit.title.range(of: "jacket|coat|bring", options: jacketOptions) != nil {
            return outfit.title
        }
        if outfit.title.range(of: "no jacket", options: jacketOptions) != nil {
            return outfit.title
        }
        return "\(outfit.title), No Jacket"
    }

    static func confidence(
        outfit: OutfitRecommendation,
        weather: WeatherData,
        comfort: ComfortPreference
    ) -> FitConfidence {
        if comfort.feedbackCount > 0 || comfort.lastFeedback != nil {
            return .tunedForYou
        }
        if weather.precipitationChance >= 45 {
            return .rainRisk
        }
        if outfit.bringLater != nil {
            return .eveningDrop
        }
        let tip = packTip(outfit: outfit, weather: weather)
        if tip.value.lowercased() != "travel light" {
            return .bringBackup
        }
        return .confident
    }

    /// Back-compat for widget / older call sites.
    static func confidenceLabel(_ comfort: ComfortPreference) -> String {
        if comfort.feedbackCount > 0 || comfort.lastFeedback != nil {
            return FitConfidence.tunedForYou.rawValue
        }
        return FitConfidence.confident.rawValue
    }

    static func confidenceLabel(
        outfit: OutfitRecommendation,
        weather: WeatherData,
        comfort: ComfortPreference
    ) -> String {
        confidence(outfit: outfit, weather: weather, comfort: comfort).rawValue
    }

    static func packTip(outfit: OutfitRecommendation, weather: WeatherData) -> (label: String, value: String) {
        if let later = outfit.bringLater {
            let short = later
                .replacingOccurrences(
                    of: #"^bring\s+"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            return ("Pack", short.prefix(1).uppercased() + short.dropFirst())
        }
        if weather.precipitationChance >= 40 {
            return ("Pack", "Rain layer")
        }
        if weather.high - weather.low >= 12 {
            return ("Pack", "Light layer")
        }
        return ("Pack", "Travel light")
    }

    /// First-class pack lane cards (empty when nothing special to pack).
    static func packLaneItems(outfit: OutfitRecommendation, weather: WeatherData) -> [String] {
        var items: [String] = []

        if let later = outfit.bringLater {
            let short = later
                .replacingOccurrences(
                    of: #"^bring\s+(a\s+)?"#,
                    with: "",
                    options: [.regularExpression, .caseInsensitive]
                )
                .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            let titled = short.prefix(1).uppercased() + short.dropFirst()
            items.append(titled)
        }

        if weather.precipitationChance >= 40 {
            let rain = "Rain shell"
            if !items.contains(where: { $0.localizedCaseInsensitiveContains("rain") }) {
                items.append(rain)
            }
        }

        if weather.high - weather.low >= 12,
           !items.contains(where: { $0.localizedCaseInsensitiveContains("layer") || $0.localizedCaseInsensitiveContains("jacket") }) {
            items.append("Light layer")
        }

        return items
    }

    static func shortExplanation(_ outfit: OutfitRecommendation) -> String {
        let first = outfit.explanation
            .split(separator: ".")
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first, !first.isEmpty else { return outfit.explanation }
        return first.hasSuffix(".") ? first : "\(first)."
    }

    static func whyDetail(weather: WeatherData, outfit: OutfitRecommendation) -> String {
        if let detail = outfit.whyDetail, !detail.isEmpty {
            return detail
        }

        var parts: [String] = []
        parts.append("Feels like \(weather.feelsLike)°")

        if weather.humidity >= 70 {
            parts.append("humidity is high (\(weather.humidity)%)")
        } else if weather.humidity <= 35 {
            parts.append("humidity is low (\(weather.humidity)%)")
        } else {
            parts.append("humidity is moderate (\(weather.humidity)%)")
        }

        if weather.windSpeed >= 12 {
            parts.append("wind is strong (\(weather.windSpeed) mph)")
        } else if weather.windSpeed >= 8 {
            parts.append("wind is breezy (\(weather.windSpeed) mph)")
        } else {
            parts.append("wind is mild (\(weather.windSpeed) mph)")
        }

        if weather.precipitationChance >= 45 {
            parts.append("rain chance is \(weather.precipitationChance)%")
        }

        if let hourlyDrop = eveningDropDegrees(weather: weather) {
            if hourlyDrop >= 10 {
                parts.append("evening drops about \(hourlyDrop)°")
            } else {
                parts.append("evening only drops \(hourlyDrop)°")
            }
        }

        return parts.joined(separator: ", ") + "."
    }

    static func feedbackResponse(_ feedback: ComfortFeedback) -> String {
        switch feedback {
        case .tooCold:
            return "Got it. Tomorrow will lean warmer."
        case .perfect:
            return "Nice. Keeping this baseline."
        case .tooHot:
            return "Got it. Tomorrow will lighten up."
        }
    }

    static func notificationBody(
        locationName: String,
        weather: WeatherData,
        outfit: OutfitRecommendation
    ) -> String {
        let title = formatTitle(outfit)
        let breeze = weather.windSpeed >= 10 ? "breezy" : weather.condition.lowercased()
        var body = "\(locationName) is \(breeze). \(title)."
        let packs = packLaneItems(outfit: outfit, weather: weather)
        if let first = packs.first {
            let when: String
            if let hour = laterPackHour(weather: weather) {
                when = " after \(hour)"
            } else {
                when = ""
            }
            body += " Pack \(first.lowercased())\(when)."
        }
        return body
    }

    private static func eveningDropDegrees(weather: WeatherData) -> Int? {
        guard !weather.hourly.isEmpty else {
            let span = weather.high - weather.low
            return span > 0 ? span : nil
        }
        let coldest = weather.hourly.map(\.feelsLike).min() ?? weather.feelsLike
        return max(0, weather.feelsLike - coldest)
    }

    private static func laterPackHour(weather: WeatherData) -> String? {
        guard let coldest = weather.hourly.min(by: { $0.feelsLike < $1.feelsLike }) else {
            return "6 PM"
        }
        guard let date = parseTime(coldest.time) else { return "6 PM" }
        let hour = Calendar.current.component(.hour, from: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var comps = DateComponents()
        comps.hour = hour
        guard let display = Calendar.current.date(from: comps) else { return "6 PM" }
        return formatter.string(from: display)
    }

    private static func parseTime(_ iso: String) -> Date? {
        if let d = ISO8601DateFormatter().date(from: iso) { return d }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: String(iso.prefix(16)))
    }
}
