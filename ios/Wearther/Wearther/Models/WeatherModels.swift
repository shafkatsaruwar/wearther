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
    /// True when mock / offline fallback data is shown.
    let isMock: Bool

    init(
        locationName: String,
        temperature: Int,
        feelsLike: Int,
        condition: String,
        conditionCode: String,
        high: Int,
        low: Int,
        humidity: Int,
        windSpeed: Int,
        precipitationChance: Int,
        hourly: [HourlyWeather],
        daily: [DailyForecast],
        units: String,
        fetchedAt: String,
        isMock: Bool = false
    ) {
        self.locationName = locationName
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.condition = condition
        self.conditionCode = conditionCode
        self.high = high
        self.low = low
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.precipitationChance = precipitationChance
        self.hourly = hourly
        self.daily = daily
        self.units = units
        self.fetchedAt = fetchedAt
        self.isMock = isMock
    }

    var tomorrow: DailyForecast? {
        guard daily.count > 1 else { return nil }
        return daily[1]
    }

    var fetchedDate: Date? {
        if let d = ISO8601DateFormatter().date(from: fetchedAt) { return d }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let d = formatter.date(from: fetchedAt) { return d }
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: String(fetchedAt.prefix(19)))
    }

    /// Stale after 90 minutes.
    var isStale: Bool {
        guard let fetchedDate else { return true }
        return Date().timeIntervalSince(fetchedDate) > 90 * 60
    }

    var updatedLabel: String {
        guard let fetchedDate else { return "Updated just now" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Updated \(formatter.string(from: fetchedDate))"
    }
}

struct LocationResult: Codable, Equatable, Identifiable, Hashable {
    let id: String
    let name: String
    let region: String?
    let country: String
    let latitude: Double
    let longitude: Double

    /// Shared default city — safe for app + widget targets (no mock provider dependency).
    static let boston = LocationResult(
        id: "boston-us",
        name: "Boston",
        region: "Massachusetts",
        country: "United States",
        latitude: 42.3601,
        longitude: -71.0589
    )
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
