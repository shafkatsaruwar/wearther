import Foundation

/// Pure clothing recommendation engine — mirrors web `lib/recommendOutfit.ts`.
enum OutfitRecommender {
    private static let strongWindMPH = 12.0
    private static let highRainChance = 45.0
    private static let highHumidity = 70.0
    private static let significantDropF = 10.0

    struct RecommendInput {
        let weather: WeatherData
        let comfort: ComfortPreference?
    }

    private struct BaseLayer {
        let title: String
        let items: [String]
        let warmthLevel: Double
        let reason: String
    }

    private struct LaterAdvice {
        let drop: Int
        let message: String
        let short: String
    }

    static func recommend(_ input: RecommendInput) -> OutfitRecommendation {
        let bias = input.comfort?.warmthBias ?? 0
        let adjustedFeels = Double(input.weather.feelsLike) + bias

        let windy = Double(input.weather.windSpeed) >= strongWindMPH
        let rainy = Double(input.weather.precipitationChance) >= highRainChance
        let humid = Double(input.weather.humidity) >= highHumidity

        var effective = adjustedFeels
        if windy && adjustedFeels < 75 {
            effective -= min(6, round(Double(input.weather.windSpeed) / 4))
        }

        let base = baseLayer(for: effective, humid: humid)
        let later = laterDropAdvice(weather: input.weather, currentEffective: effective)

        var items = base.items
        var title = base.title
        var warmthLevel = base.warmthLevel
        var reasons = [base.reason]

        if rainy {
            if !items.contains(where: { $0.range(of: "rain|waterproof", options: .regularExpression) != nil }) {
                items.append("Rain jacket")
            }
            reasons.append("Rain is likely, so keep a waterproof layer handy.")
            warmthLevel = min(10, warmthLevel + 0.5)
        }

        if windy && effective >= 52 && effective <= 75 {
            if !items.contains(where: { $0.range(of: "jacket|coat|sweater", options: .regularExpression) != nil }) {
                items.append("Light jacket")
                title = joinTitle(title, "Light Jacket")
                warmthLevel = min(10, warmthLevel + 1)
            }
            reasons.append("It feels cooler because of the wind.")
        }

        if let later {
            if !items.contains(where: { $0.range(of: "jacket|coat|bring", options: .regularExpression) != nil }) {
                title = joinTitle(stripBring(title), "Bring a Jacket")
            } else if title.range(of: "bring", options: .caseInsensitive) == nil && later.drop >= Int(significantDropF) {
                title = joinTitle(stripBring(title), "Bring a Jacket")
            }
            reasons.append(later.message)
        }

        if humid && Double(input.weather.feelsLike) >= 76 {
            reasons.append("High humidity favors breathable fabrics like linen.")
        }

        if bias >= 2 {
            reasons.append("Based on your feedback, this leans a bit warmer.")
        } else if bias <= -2 {
            reasons.append("Based on your feedback, this leans a bit cooler.")
        }

        let explanation = craftExplanation(
            reasons: reasons,
            weather: input.weather,
            windy: windy,
            rainy: rainy
        )

        return OutfitRecommendation(
            title: title,
            items: dedupe(items),
            explanation: explanation,
            warmthLevel: warmthLevel,
            bringLater: later?.short
        )
    }

    static func recommendForHour(_ hour: HourlyWeather, comfort: ComfortPreference?) -> String {
        let bias = comfort?.warmthBias ?? 0
        let t = Double(hour.feelsLike) + bias
        let rainy = Double(hour.precipitationChance) >= highRainChance

        if t >= 85 { return rainy ? "Linen + rain layer" : "Linen / shorts" }
        if t >= 76 { return rainy ? "Short sleeve + rain jacket" : "Short sleeve" }
        if t >= 68 { return rainy ? "Light layers + rain jacket" : "Jacket optional" }
        if t >= 60 { return "Long sleeve" }
        if t >= 52 { return "Long sleeve + light jacket" }
        if t >= 42 { return "Sweater + jacket" }
        if t >= 32 { return "Sweater + coat" }
        return "Heavy coat + layers"
    }

    static func recommendForTomorrow(
        _ forecast: TomorrowForecast,
        locationName: String,
        comfort: ComfortPreference?
    ) -> OutfitRecommendation {
        let weather = WeatherData(
            locationName: locationName,
            temperature: forecast.feelsLike,
            feelsLike: forecast.feelsLike,
            condition: forecast.condition,
            conditionCode: forecast.conditionCode,
            high: forecast.high,
            low: forecast.low,
            humidity: forecast.humidity,
            windSpeed: forecast.windSpeed,
            precipitationChance: forecast.precipitationChance,
            hourly: forecast.hourly,
            units: "imperial",
            fetchedAt: ISO8601DateFormatter().string(from: Date()),
            tomorrow: nil
        )

        var recommendation = recommend(.init(weather: weather, comfort: comfort))
        if !recommendation.explanation.localizedCaseInsensitiveContains("tomorrow") {
            recommendation = OutfitRecommendation(
                title: recommendation.title,
                items: recommendation.items,
                explanation: "For tomorrow: \(recommendation.explanation)",
                warmthLevel: recommendation.warmthLevel,
                bringLater: recommendation.bringLater
            )
        }
        return recommendation
    }

    // MARK: - Private

    private static func baseLayer(for temp: Double, humid: Bool) -> BaseLayer {
        if temp >= 85 {
            return BaseLayer(
                title: humid ? "Linen + Shorts" : "Linen or Short Sleeve + Shorts",
                items: humid
                    ? ["Linen shirt", "Shorts", "Sneakers"]
                    : ["Linen or lightweight short sleeve", "Shorts", "Sneakers"],
                warmthLevel: 1,
                reason: "It's hot out — keep it light and breathable."
            )
        }
        if temp >= 76 {
            return BaseLayer(
                title: humid ? "Linen" : "Short Sleeve or Linen",
                items: humid
                    ? ["Linen shirt", "Shorts or light pants", "Sneakers"]
                    : ["Short sleeve or linen", "Shorts or light pants", "Sneakers"],
                warmthLevel: 2,
                reason: "Warm weather calls for light, easy layers."
            )
        }
        if temp >= 68 {
            return BaseLayer(
                title: "Short Sleeve or Thin Long Sleeve",
                items: ["Short sleeve or thin long sleeve", "Pants or chinos", "Sneakers"],
                warmthLevel: 3,
                reason: "Mild and comfortable — a thin top should be enough."
            )
        }
        if temp >= 60 {
            return BaseLayer(
                title: "Long Sleeve",
                items: ["Long sleeve shirt", "Jeans or chinos", "Sneakers"],
                warmthLevel: 4,
                reason: "Cool enough for long sleeves without a jacket."
            )
        }
        if temp >= 52 {
            return BaseLayer(
                title: "Long Sleeve + Light Jacket",
                items: ["Long sleeve shirt", "Light jacket", "Jeans or chinos", "Sneakers"],
                warmthLevel: 5,
                reason: "A light jacket should keep you comfortable."
            )
        }
        if temp >= 42 {
            return BaseLayer(
                title: "Sweater + Jacket",
                items: ["Sweater", "Light jacket", "Pants", "Sneakers"],
                warmthLevel: 6,
                reason: "Chilly air — sweater plus a jacket works well."
            )
        }
        if temp >= 32 {
            return BaseLayer(
                title: "Sweater + Heavy Jacket",
                items: ["Sweater", "Heavy jacket / coat", "Pants", "Closed shoes"],
                warmthLevel: 8,
                reason: "Cold enough for a heavy outer layer over a sweater."
            )
        }
        return BaseLayer(
            title: "Winter Coat + Warm Layers",
            items: [
                "Warm base layer",
                "Sweater",
                "Heavy jacket / coat",
                "Scarf",
                "Gloves",
            ],
            warmthLevel: 10,
            reason: "Freezing conditions — bundle up with coat, scarf, and gloves."
        )
    }

    private static func laterDropAdvice(weather: WeatherData, currentEffective: Double) -> LaterAdvice? {
        guard !weather.hourly.isEmpty else { return nil }

        let coldest = weather.hourly.map(\.feelsLike).min() ?? Int(currentEffective)
        let drop = currentEffective - Double(coldest)

        if drop < significantDropF { return nil }
        if coldest >= 68 { return nil }

        return LaterAdvice(
            drop: Int(round(drop)),
            message: "It drops to about \(coldest)° later — bring a jacket for later.",
            short: "Bring a jacket for later."
        )
    }

    private static func craftExplanation(
        reasons: [String],
        weather: WeatherData,
        windy: Bool,
        rainy: Bool
    ) -> String {
        if windy && weather.feelsLike < 70 && !rainy {
            let rest = reasons
                .filter { !$0.localizedCaseInsensitiveContains("wind") }
                .prefix(1)
                .joined(separator: " ")
            var text = "It's cool and breezy today. The jacket will help with the wind."
            if !rest.isEmpty { text += " \(rest)" }
            return text.trimmingCharacters(in: .whitespaces)
        }

        var seen = Set<String>()
        let unique = reasons.filter { seen.insert($0).inserted }.prefix(2)
        return unique.joined(separator: " ")
    }

    private static func joinTitle(_ base: String, _ addition: String) -> String {
        if base.localizedCaseInsensitiveContains(addition) { return base }
        return "\(base) + \(addition)"
    }

    private static func stripBring(_ title: String) -> String {
        title.replacingOccurrences(
            of: #"\s*\+\s*Bring a Jacket"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        ).trimmingCharacters(in: .whitespaces)
    }

    private static func dedupe(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for item in items {
            let key = item.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            out.append(item)
        }
        return out
    }
}
