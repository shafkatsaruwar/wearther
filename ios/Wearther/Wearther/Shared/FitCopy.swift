import Foundation

enum FitCopy {
    static func formatTitle(_ outfit: OutfitRecommendation) -> String {
        let hasJacket = outfit.items.contains {
            $0.range(of: "jacket|coat|bring", options: .regularExpression) != nil
        }
        if hasJacket || outfit.title.range(of: "jacket|coat|bring", options: .regularExpression) != nil {
            return outfit.title
        }
        if outfit.title.range(of: "no jacket", options: [.regularExpression, .caseInsensitive]) != nil {
            return outfit.title
        }
        return "\(outfit.title), No Jacket"
    }

    static func confidenceLabel(_ comfort: ComfortPreference) -> String {
        if comfort.feedbackCount > 0 || comfort.lastFeedback != nil {
            return "Tuned"
        }
        return "Confident"
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
}
