import Foundation

struct SweataWeathaMoment: Equatable {
    let headline: String
    let subtitle: String
    let line: String
    let isTomorrow: Bool
}

/// Detects classic sweater weather and serves Boston-accent copy.
enum SweataWeatha {
    private static let minFeels = 52
    private static let maxFeels = 68
    private static let maxRainChance = 44

    static func todayMoment(for weather: WeatherData) -> SweataWeathaMoment? {
        guard isSweaterWeather(
            feelsLike: weather.feelsLike,
            precipitationChance: weather.precipitationChance,
            conditionCode: weather.conditionCode
        ) else { return nil }

        return SweataWeathaMoment(
            headline: "Sweata Weatha",
            subtitle: todaySubtitle(cityName: weather.locationName),
            line: todayLine(feelsLike: weather.feelsLike, windy: weather.windSpeed >= 12),
            isTomorrow: false
        )
    }

    static func tomorrowMoment(for forecast: TomorrowForecast, cityName: String) -> SweataWeathaMoment? {
        guard isSweaterWeather(
            feelsLike: forecast.feelsLike,
            precipitationChance: forecast.precipitationChance,
            conditionCode: forecast.conditionCode
        ) else { return nil }

        return SweataWeathaMoment(
            headline: "Sweata Weatha",
            subtitle: "Tomorrah in \(cityName) — ya gonna wanna plan ahead",
            line: tomorrowLine(feelsLike: forecast.feelsLike, windy: forecast.windSpeed >= 12),
            isTomorrow: true
        )
    }

    static func notificationAlert(for forecast: TomorrowForecast, cityName: String) -> WeatherAlert? {
        guard tomorrowMoment(for: forecast, cityName: cityName) != nil else { return nil }

        return WeatherAlert(
            title: "Sweata Weatha tomorrah in \(cityName) 🧣",
            body: "Tomorrah's gonna be pahfect sweata weatha. Pack a sweater or fleece — it's gonna feel crisp out theah."
        )
    }

    // MARK: - Detection

    static func isSweaterWeather(feelsLike: Int, precipitationChance: Int, conditionCode: String) -> Bool {
        guard feelsLike >= minFeels, feelsLike <= maxFeels else { return false }
        guard precipitationChance <= maxRainChance else { return false }
        guard !["storm", "snow", "rain"].contains(conditionCode) else { return false }
        return true
    }

    // MARK: - Copy

    private static func todaySubtitle(cityName: String) -> String {
        if cityName.localizedCaseInsensitiveContains("Boston") {
            return "Out theah in Boston — wicked nice sweata weatha"
        }
        return "Out theah in \(cityName) — it's sweata weatha"
    }

    private static func todayLine(feelsLike: Int, windy: Bool) -> String {
        var line: String
        switch feelsLike {
        case ..<58:
            line = "Wicked chilly — grab ya fleece or a heavy sweater before ya head out."
        case 58...62:
            line = "Pahfect sweata weatha. A sweater and jeans oughta do ya just fine."
        default:
            line = "Light sweata weatha — a cardigan or thin sweater should be all ya need."
        }

        if windy {
            line += " And it's breezy — bring a light jacket too, would ya?"
        }
        return line
    }

    private static func tomorrowLine(feelsLike: Int, windy: Bool) -> String {
        var line: String
        switch feelsLike {
        case ..<58:
            line = "Tomorrah's sweata weatha — pack a warm sweater, not just a tee."
        case 58...62:
            line = "Tomorrah's pahfect sweata weatha. Lay out ya favorite sweater tonight."
        default:
            line = "Tomorrah's light sweata weatha — a layer in the backpack wouldn't hurt."
        }

        if windy {
            line += " Wind's pickin' up too — throw a jacket in with it."
        }
        return line
    }
}
