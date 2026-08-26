import Foundation

struct OpenWeatherProvider: WeatherProvider {
    let apiKey: String

    func getWeather(lat: Double, lon: Double, locationName: String) async throws -> WeatherData {
        var components = URLComponents(string: "https://api.openweathermap.org/data/3.0/onecall")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "units", value: "imperial"),
            URLQueryItem(name: "exclude", value: "minutely,alerts"),
            URLQueryItem(name: "appid", value: apiKey),
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw WeatherServiceError.invalidResponse }
        guard http.statusCode == 200 else { throw WeatherServiceError.httpStatus(http.statusCode) }

        let decoded = try JSONDecoder().decode(OpenWeatherOneCall.self, from: data)
        let condition = Self.mapCondition(decoded.current.weather.first?.main ?? "Clouds")
        let now = Date().timeIntervalSince1970
        let targetHours = [15, 18, 21]
        var hourly: [HourlyWeather] = []

        for th in targetHours {
            guard let match = decoded.hourly.first(where: { h in
                h.dt > now && Calendar.current.component(.hour, from: Date(timeIntervalSince1970: h.dt)) == th
            }) else { continue }

            let c = Self.mapCondition(match.weather.first?.main ?? "Clouds")
            hourly.append(HourlyWeather(
                time: Date(timeIntervalSince1970: match.dt).ISO8601Format(),
                temperature: Int(round(match.temp)),
                precipitationChance: Int(round(match.pop * 100)),
                condition: c.label,
                feelsLike: Int(round(match.feelsLike))
            ))
        }

        let tomorrow = parseTomorrowForecast(from: decoded)

        return WeatherData(
            locationName: locationName,
            temperature: Int(round(decoded.current.temp)),
            feelsLike: Int(round(decoded.current.feelsLike)),
            condition: condition.label,
            conditionCode: condition.key,
            high: Int(round(decoded.daily.first?.temp.max ?? decoded.current.temp)),
            low: Int(round(decoded.daily.first?.temp.min ?? decoded.current.temp)),
            humidity: Int(round(decoded.current.humidity)),
            windSpeed: Int(round(decoded.current.windSpeed)),
            precipitationChance: Int(round((decoded.daily.first?.pop ?? 0) * 100)),
            hourly: hourly,
            units: "imperial",
            fetchedAt: ISO8601DateFormatter().string(from: Date()),
            tomorrow: tomorrow
        )
    }

    private func parseTomorrowForecast(from decoded: OpenWeatherOneCall) -> TomorrowForecast? {
        guard decoded.daily.count > 1 else { return nil }

        let day = decoded.daily[1]
        let high = Int(round(day.temp.max))
        let low = Int(round(day.temp.min))
        let precip = Int(round(day.pop * 100))
        let condition = Self.mapCondition(day.weather.first?.main ?? "Clouds")

        let tomorrowHours = pickTomorrowHours(from: decoded.hourly)
        let midday = tomorrowHours.first(where: {
            guard let date = ISO8601DateFormatter().date(from: $0.time) else { return false }
            return Calendar.current.component(.hour, from: date) == 12
        }) ?? tomorrowHours.first

        let feelsLike = midday?.feelsLike ?? (high + low) / 2
        let tomorrowDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let dateLabel = tomorrowDate.formatted(.dateTime.weekday(.wide).month(.wide).day())

        return TomorrowForecast(
            dateLabel: dateLabel,
            high: high,
            low: low,
            feelsLike: feelsLike,
            condition: condition.label,
            conditionCode: condition.key,
            humidity: Int(round(day.humidity ?? 55)),
            windSpeed: Int(round(day.windSpeed ?? 8)),
            precipitationChance: precip,
            hourly: tomorrowHours
        )
    }

    private func pickTomorrowHours(from hourly: [OpenWeatherHourly]) -> [HourlyWeather] {
        let targetHours = [9, 12, 18]
        var results: [HourlyWeather] = []

        for target in targetHours {
            guard let match = hourly.first(where: { h in
                let date = Date(timeIntervalSince1970: h.dt)
                return Calendar.current.isDateInTomorrow(date)
                    && Calendar.current.component(.hour, from: date) == target
            }) else { continue }

            let c = Self.mapCondition(match.weather.first?.main ?? "Clouds")
            results.append(HourlyWeather(
                time: Date(timeIntervalSince1970: match.dt).ISO8601Format(),
                temperature: Int(round(match.temp)),
                precipitationChance: Int(round(match.pop * 100)),
                condition: c.label,
                feelsLike: Int(round(match.feelsLike))
            ))
        }

        return results
    }

    func searchLocations(query: String) async throws -> [LocationResult] {
        var components = URLComponents(string: "https://api.openweathermap.org/geo/1.0/direct")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "6"),
            URLQueryItem(name: "appid", value: apiKey),
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw WeatherServiceError.invalidResponse }
        guard http.statusCode == 200 else { throw WeatherServiceError.httpStatus(http.statusCode) }

        let decoded = try JSONDecoder().decode([OpenWeatherGeoResult].self, from: data)
        return decoded.enumerated().map { index, r in
            LocationResult(
                id: "\(r.name)-\(r.lat)-\(r.lon)-\(index)",
                name: r.name,
                region: r.state,
                country: r.country,
                latitude: r.lat,
                longitude: r.lon
            )
        }
    }

    private static func mapCondition(_ main: String) -> (label: String, key: String) {
        let m = main.lowercased()
        if m.contains("thunder") { return ("Thunderstorm", "storm") }
        if m.contains("drizzle") { return ("Drizzle", "rain") }
        if m.contains("rain") { return ("Rain", "rain") }
        if m.contains("snow") { return ("Snow", "snow") }
        if m.contains("mist") || m.contains("fog") || m.contains("haze") { return ("Foggy", "fog") }
        if m.contains("cloud") { return ("Cloudy", "cloudy") }
        if m.contains("clear") { return ("Clear", "clear") }
        return (main, "cloudy")
    }
}

private struct OpenWeatherOneCall: Decodable {
    let current: OpenWeatherCurrent
    let hourly: [OpenWeatherHourly]
    let daily: [OpenWeatherDaily]
}

private struct OpenWeatherCurrent: Decodable {
    let temp: Double
    let feelsLike: Double
    let humidity: Double
    let windSpeed: Double
    let weather: [OpenWeatherCondition]

    enum CodingKeys: String, CodingKey {
        case temp, humidity, weather
        case feelsLike = "feels_like"
        case windSpeed = "wind_speed"
    }
}

private struct OpenWeatherHourly: Decodable {
    let dt: TimeInterval
    let temp: Double
    let feelsLike: Double
    let pop: Double
    let weather: [OpenWeatherCondition]

    enum CodingKeys: String, CodingKey {
        case dt, temp, pop, weather
        case feelsLike = "feels_like"
    }
}

private struct OpenWeatherDaily: Decodable {
    let temp: OpenWeatherDailyTemp
    let pop: Double
    let weather: [OpenWeatherCondition]
    let humidity: Double?
    let windSpeed: Double?

    enum CodingKeys: String, CodingKey {
        case temp, pop, weather, humidity
        case windSpeed = "wind_speed"
    }
}

private struct OpenWeatherDailyTemp: Decodable {
    let max: Double
    let min: Double
}

private struct OpenWeatherCondition: Decodable {
    let main: String
}

private struct OpenWeatherGeoResult: Decodable {
    let name: String
    let state: String?
    let country: String
    let lat: Double
    let lon: Double
}
