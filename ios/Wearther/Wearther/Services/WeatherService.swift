import Foundation

enum WeatherService {
    static func resolveProvider() -> any WeatherProvider {
        let name = (Bundle.main.object(forInfoDictionaryKey: "WEATHER_PROVIDER") as? String ?? "open-meteo")
            .lowercased()

        switch name {
        case "mock":
            return MockWeatherProvider()
        case "openweather":
            let key = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String ?? ""
            if key.isEmpty {
                return MockWeatherProvider()
            }
            return OpenWeatherProvider(apiKey: key)
        default:
            return OpenMeteoProvider()
        }
    }

    static func getWeather(for location: LocationResult) async -> WeatherData {
        let provider = resolveProvider()
        do {
            return try await provider.getWeather(
                lat: location.latitude,
                lon: location.longitude,
                locationName: location.name
            )
        } catch {
            return (try? await MockWeatherProvider().getWeather(
                lat: location.latitude,
                lon: location.longitude,
                locationName: location.name
            )) ?? mockFallback(name: location.name)
        }
    }

    static func searchCities(query: String) async -> [LocationResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }

        let provider = resolveProvider()
        do {
            return try await provider.searchLocations(query: trimmed)
        } catch {
            return (try? await MockWeatherProvider().searchLocations(query: trimmed)) ?? []
        }
    }

    private static func mockFallback(name: String) -> WeatherData {
        WeatherData(
            locationName: name,
            temperature: 72,
            feelsLike: 70,
            condition: "Partly Cloudy",
            conditionCode: "partly-cloudy",
            high: 76,
            low: 62,
            humidity: 55,
            windSpeed: 9,
            precipitationChance: 10,
            hourly: [],
            daily: [],
            units: "imperial",
            fetchedAt: ISO8601DateFormatter().string(from: Date()),
            isMock: true
        )
    }
}
