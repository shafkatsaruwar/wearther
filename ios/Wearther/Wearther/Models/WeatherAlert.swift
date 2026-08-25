import Foundation

struct WeatherAlert: Equatable {
    let title: String
    let body: String
}

enum WeatherAlertPlanner {
    private static let rainCodes: Set<String> = ["rain", "storm", "drizzle"]
    private static let highRainChance = 45

    static func plan(for forecast: TomorrowForecast, cityName: String) -> WeatherAlert? {
        var tips: [String] = []

        let rainy = forecast.precipitationChance >= highRainChance
            || rainCodes.contains(forecast.conditionCode)
            || forecast.condition.localizedCaseInsensitiveContains("rain")
            || forecast.condition.localizedCaseInsensitiveContains("shower")
            || forecast.condition.localizedCaseInsensitiveContains("drizzle")
            || forecast.condition.localizedCaseInsensitiveContains("thunder")

        let snowy = forecast.conditionCode == "snow"
            || forecast.condition.localizedCaseInsensitiveContains("snow")

        if rainy {
            tips.append("It's gonna rain tomorrow! Make sure to pack an umbrella or rain wear.")
        }

        if snowy {
            tips.append("Snow is expected — wear warm, waterproof layers and sturdy shoes.")
        }

        if forecast.low <= 32 {
            tips.append("Freezing temps ahead — bundle up with a heavy coat, scarf, and gloves.")
        } else if forecast.feelsLike <= 40 {
            tips.append("It'll feel chilly — don't forget a warm jacket.")
        }

        if forecast.high >= 90 {
            tips.append("Hot tomorrow — stick to light, breathable clothes and stay hydrated.")
        }

        if forecast.windSpeed >= 20 {
            tips.append("Strong winds expected — bring a jacket to block the breeze.")
        }

        guard !tips.isEmpty else { return nil }

        let title: String
        if rainy {
            title = "Rain tomorrow in \(cityName) ☔️"
        } else if snowy {
            title = "Snow tomorrow in \(cityName) ❄️"
        } else if forecast.low <= 32 {
            title = "Cold snap tomorrow in \(cityName) 🥶"
        } else if forecast.high >= 90 {
            title = "Heat tomorrow in \(cityName) 🥵"
        } else {
            title = "Heads up for tomorrow in \(cityName)"
        }

        return WeatherAlert(title: title, body: tips.joined(separator: " "))
    }
}
