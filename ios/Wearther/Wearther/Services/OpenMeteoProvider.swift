import Foundation

enum OpenMeteoProvider: WeatherProvider {
    static func condition(from code: Int) -> (label: String, key: String) {
        switch code {
        case 0: return ("Clear", "clear")
        case 1...3: return ("Partly Cloudy", "partly-cloudy")
        case 4...48: return ("Foggy", "fog")
        case 51...57: return ("Drizzle", "rain")
        case 61...67: return ("Rain", "rain")
        case 71...77: return ("Snow", "snow")
        case 80...82: return ("Showers", "rain")
        case 85...86: return ("Snow Showers", "snow")
        case 87...99: return ("Thunderstorm", "storm")
        default: return ("Cloudy", "cloudy")
        }
    }

    func getWeather(lat: Double, lon: Double, locationName: String) async throws -> WeatherData {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,apparent_temperature,precipitation_probability,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,precipitation_probability_max"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1"),
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw WeatherServiceError.invalidResponse }
        guard http.statusCode == 200 else { throw WeatherServiceError.httpStatus(http.statusCode) }

        let decoded = try JSONDecoder().decode(OpenMeteoForecast.self, from: data)
        let condition = Self.condition(from: decoded.current.weatherCode)

        return WeatherData(
            locationName: locationName,
            temperature: Int(round(decoded.current.temperature)),
            feelsLike: Int(round(decoded.current.apparentTemperature)),
            condition: condition.label,
            conditionCode: condition.key,
            high: Int(round(decoded.daily.temperatureMax.first ?? decoded.current.temperature)),
            low: Int(round(decoded.daily.temperatureMin.first ?? decoded.current.temperature)),
            humidity: Int(round(decoded.current.humidity)),
            windSpeed: Int(round(decoded.current.windSpeed)),
            precipitationChance: decoded.daily.precipitationProbabilityMax.first ?? 0,
            hourly: pickLaterHours(decoded.hourly),
            units: "imperial",
            fetchedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    func searchLocations(query: String) async throws -> [LocationResult] {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "6"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse else { throw WeatherServiceError.invalidResponse }
        guard http.statusCode == 200 else { throw WeatherServiceError.httpStatus(http.statusCode) }

        let decoded = try JSONDecoder().decode(OpenMeteoGeocodingResponse.self, from: data)
        return (decoded.results ?? []).map { r in
            LocationResult(
                id: String(r.id),
                name: r.name,
                region: r.admin1,
                country: r.country,
                latitude: r.latitude,
                longitude: r.longitude
            )
        }
    }

    // MARK: - Hourly selection

    private func pickLaterHours(_ hourly: OpenMeteoHourly) -> [HourlyWeather] {
        let now = Date()
        let targetHours = [15, 18, 21]
        var results: [HourlyWeather] = []

        for target in targetHours {
            guard let index = hourly.time.firstIndex(where: { iso in
                guard let date = ISO8601DateFormatter().date(from: iso) ?? parseDate(iso) else { return false }
                return date > now && Calendar.current.component(.hour, from: date) == target
            }) else { continue }

            let code = hourly.weatherCode[index]
            let label = Self.condition(from: code).label
            let timeISO = hourly.time[index]
            results.append(HourlyWeather(
                time: (ISO8601DateFormatter().date(from: timeISO) ?? parseDate(timeISO) ?? now).ISO8601Format(),
                temperature: Int(round(hourly.temperature[index])),
                precipitationChance: hourly.precipitationProbability[index] ?? 0,
                condition: label,
                feelsLike: Int(round(hourly.apparentTemperature[index]))
            ))
        }

        if results.isEmpty {
            let future = hourly.time.enumerated().compactMap { i, iso -> (Int, String)? in
                guard let date = ISO8601DateFormatter().date(from: iso) ?? parseDate(iso), date > now else { return nil }
                return (i, iso)
            }
            for (idx, pair) in future.enumerated() where idx % 3 == 2 {
                guard results.count < 3 else { break }
                let i = pair.0
                let label = Self.condition(from: hourly.weatherCode[i]).label
                let date = ISO8601DateFormatter().date(from: pair.1) ?? parseDate(pair.1) ?? now
                results.append(HourlyWeather(
                    time: date.ISO8601Format(),
                    temperature: Int(round(hourly.temperature[i])),
                    precipitationChance: hourly.precipitationProbability[i] ?? 0,
                    condition: label,
                    feelsLike: Int(round(hourly.apparentTemperature[i]))
                ))
            }
        }

        return results
    }

    private func parseDate(_ iso: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: String(iso.prefix(16)))
    }
}

// MARK: - API types

private struct OpenMeteoForecast: Decodable {
    let current: OpenMeteoCurrent
    let daily: OpenMeteoDaily
    let hourly: OpenMeteoHourly

    enum CodingKeys: String, CodingKey {
        case current, daily, hourly
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        current = try c.decode(OpenMeteoCurrent.self, forKey: .current)
        daily = try c.decode(OpenMeteoDaily.self, forKey: .daily)
        hourly = try c.decode(OpenMeteoHourly.self, forKey: .hourly)
    }
}

private struct OpenMeteoCurrent: Decodable {
    let temperature: Double
    let apparentTemperature: Double
    let humidity: Double
    let weatherCode: Int
    let windSpeed: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case humidity = "relative_humidity_2m"
        case weatherCode = "weather_code"
        case windSpeed = "wind_speed_10m"
    }
}

private struct OpenMeteoDaily: Decodable {
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    let precipitationProbabilityMax: [Int]

    enum CodingKeys: String, CodingKey {
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}

private struct OpenMeteoHourly: Decodable {
    let time: [String]
    let temperature: [Double]
    let apparentTemperature: [Double]
    let precipitationProbability: [Int?]
    let weatherCode: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case apparentTemperature = "apparent_temperature"
        case precipitationProbability = "precipitation_probability"
        case weatherCode = "weather_code"
    }
}

private struct OpenMeteoGeocodingResponse: Decodable {
    let results: [OpenMeteoGeocodingResult]?
}

private struct OpenMeteoGeocodingResult: Decodable {
    let id: Int
    let name: String
    let admin1: String?
    let country: String
    let latitude: Double
    let longitude: Double
}
