import Foundation

struct MockWeatherProvider: WeatherProvider {
    static let defaultCity = LocationResult(
        id: "boston-us",
        name: "Boston",
        region: "Massachusetts",
        country: "United States",
        latitude: 42.3601,
        longitude: -71.0589
    )

    static let suggestedCities: [LocationResult] = [
        defaultCity,
        LocationResult(id: "new-york-us", name: "New York", region: "New York", country: "United States", latitude: 40.7128, longitude: -74.006),
        LocationResult(id: "san-francisco-us", name: "San Francisco", region: "California", country: "United States", latitude: 37.7749, longitude: -122.4194),
        LocationResult(id: "chicago-us", name: "Chicago", region: "Illinois", country: "United States", latitude: 41.8781, longitude: -87.6298),
        LocationResult(id: "london-gb", name: "London", region: "England", country: "United Kingdom", latitude: 51.5074, longitude: -0.1278),
        LocationResult(id: "tokyo-jp", name: "Tokyo", region: "Tokyo", country: "Japan", latitude: 35.6762, longitude: 139.6503),
        LocationResult(id: "miami-us", name: "Miami", region: "Florida", country: "United States", latitude: 25.7617, longitude: -80.1918),
        LocationResult(id: "seattle-us", name: "Seattle", region: "Washington", country: "United States", latitude: 47.6062, longitude: -122.3321),
    ]

    private static var mockCities: [LocationResult] { suggestedCities }

    func getWeather(lat: Double, lon: Double, locationName: String) async throws -> WeatherData {
        try await Task.sleep(nanoseconds: 280_000_000)
        return mockForCity(locationName)
    }

    func searchLocations(query: String) async throws -> [LocationResult] {
        let q = query.lowercased()
        return Self.mockCities.filter { city in
            city.name.lowercased().contains(q)
                || (city.region?.lowercased().contains(q) ?? false)
                || city.country.lowercased().contains(q)
        }
    }

    private func mockForCity(_ name: String) -> WeatherData {
        let profiles: [String: (temperature: Int, feelsLike: Int, condition: String, conditionCode: String, high: Int, low: Int, humidity: Int, windSpeed: Int, precipitationChance: Int)] = [
            "Boston": (61, 57, "Cloudy", "cloudy", 67, 52, 68, 14, 20),
            "Miami": (88, 94, "Humid", "partly-cloudy", 91, 79, 82, 8, 40),
            "Chicago": (38, 30, "Windy", "windy", 42, 28, 55, 22, 10),
            "London": (54, 50, "Light Rain", "rain", 58, 46, 78, 12, 70),
            "San Francisco": (64, 60, "Foggy", "fog", 68, 55, 72, 16, 5),
        ]

        let base = profiles[name] ?? (72, 70, "Partly Cloudy", "partly-cloudy", 76, 62, 55, 9, 10)

        return WeatherData(
            locationName: name,
            temperature: base.temperature,
            feelsLike: base.feelsLike,
            condition: base.condition,
            conditionCode: base.conditionCode,
            high: base.high,
            low: base.low,
            humidity: base.humidity,
            windSpeed: base.windSpeed,
            precipitationChance: base.precipitationChance,
            hourly: buildHourly(baseTemp: base.temperature, baseFeels: base.feelsLike),
            units: "imperial",
            fetchedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func buildHourly(baseTemp: Int, baseFeels: Int) -> [HourlyWeather] {
        let now = Date()
        let slots = [15, 18, 21]
        let offsets = [7, 0, -6]

        return zip(slots, offsets).enumerated().map { index, pair in
            let (hour, offset) = pair
            var time = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: now) ?? now
            if time < now {
                time = Calendar.current.date(byAdding: .day, value: 1, to: time) ?? time
            }
            let temperature = baseTemp + offset
            let precip = index == 2 ? 35 : 15
            let condition = index == 2 ? "Cloudy" : "Partly Cloudy"
            return HourlyWeather(
                time: time.ISO8601Format(),
                temperature: temperature,
                precipitationChance: precip,
                condition: condition,
                feelsLike: baseFeels + offset - 1
            )
        }
    }
}
