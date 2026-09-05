import Foundation

struct HourlyWeather: Codable, Equatable, Identifiable {
    var id: String { time }
    let time: String
    let temperature: Int
    let precipitationChance: Int
    let condition: String
    let feelsLike: Int
}

struct DailyForecast: Codable, Equatable, Identifiable {
    var id: String { date }
    let date: String
    let high: Int
    let low: Int
    let precipitationChance: Int
    let condition: String
    let conditionCode: String
}

struct WeatherData: Codable, Equatable {
    let locationName: String
    let temperature: Int
    let feelsLike: Int
    let condition: String
    let conditionCode: String
    let high: Int
    let low: Int
    let humidity: Int
    let windSpeed: Int
    let precipitationChance: Int
    let hourly: [HourlyWeather]
    let daily: [DailyForecast]
    let units: String
    let fetchedAt: String

    var tomorrow: DailyForecast? {
        guard daily.count > 1 else { return nil }
        return daily[1]
    }
}

struct LocationResult: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let name: String
    let region: String?
    let country: String
    let latitude: Double
    let longitude: Double
}

enum WeatherProviderName: String {
    case mock
    case openMeteo = "open-meteo"
    case openWeather = "openweather"
}

protocol WeatherProvider {
    func getWeather(lat: Double, lon: Double, locationName: String) async throws -> WeatherData
    func searchLocations(query: String) async throws -> [LocationResult]
}

enum WeatherServiceError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid weather response."
        case .httpStatus(let code):
            return "Weather request failed (\(code))."
        }
    }
}
