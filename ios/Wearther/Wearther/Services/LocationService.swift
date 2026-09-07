import CoreLocation
import Foundation

enum LocationServiceError: LocalizedError {
    case denied
    case restricted
    case unavailable
    case timedOut
    case reverseFailed

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Location access is off. Enable it in Settings, or search for a city."
        case .restricted:
            return "Location access is restricted on this device."
        case .unavailable:
            return "Couldn’t get your location. Try again."
        case .timedOut:
            return "Location timed out. Try again."
        case .reverseFailed:
            return "Found you, but couldn’t name the place. Try searching a city."
        }
    }
}

@MainActor
final class LocationService: NSObject {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var timeoutTask: Task<Void, Never>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func locateCurrentPlace() async throws -> LocationResult {
        let location = try await requestLocation()
        if let place = try await LocationService.reverseGeocode(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) {
            return place
        }
        throw LocationServiceError.reverseFailed
    }

    private func requestLocation() async throws -> CLLocation {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Wait briefly for the permission sheet result, then continue.
            try await Task.sleep(nanoseconds: 400_000_000)
        case .denied:
            throw LocationServiceError.denied
        case .restricted:
            throw LocationServiceError.restricted
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            break
        }

        if continuation != nil {
            continuation?.resume(throwing: LocationServiceError.unavailable)
            continuation = nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.manager.requestLocation()

            self.timeoutTask?.cancel()
            self.timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 12_000_000_000)
                guard let self, !Task.isCancelled else { return }
                if let pending = self.continuation {
                    self.continuation = nil
                    pending.resume(throwing: LocationServiceError.timedOut)
                }
            }
        }
    }

    static func reverseGeocode(latitude: Double, longitude: Double) async throws -> LocationResult? {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/reverse")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "count", value: "1"),
        ]

        guard let url = components.url else { return nil }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return fallbackNearMe(latitude: latitude, longitude: longitude)
        }

        let decoded = try JSONDecoder().decode(OpenMeteoReverseResponse.self, from: data)
        if let first = decoded.results?.first {
            return LocationResult(
                id: "near-\(first.id)",
                name: first.name,
                region: first.admin1,
                country: first.country ?? "Unknown",
                latitude: first.latitude,
                longitude: first.longitude
            )
        }

        return fallbackNearMe(latitude: latitude, longitude: longitude)
    }

    private static func fallbackNearMe(latitude: Double, longitude: Double) -> LocationResult {
        LocationResult(
            id: "near-me-\(Int(latitude * 100))-\(Int(longitude * 100))",
            name: "Near Me",
            region: nil,
            country: "Current location",
            latitude: latitude,
            longitude: longitude
        )
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // No-op: requestLocation is called after permission settles.
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            timeoutTask?.cancel()
            timeoutTask = nil
            guard let location = locations.last else {
                continuation?.resume(throwing: LocationServiceError.unavailable)
                continuation = nil
                return
            }
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            timeoutTask?.cancel()
            timeoutTask = nil
            let mapped: Error
            if let clError = error as? CLError, clError.code == .denied {
                mapped = LocationServiceError.denied
            } else {
                mapped = LocationServiceError.unavailable
            }
            continuation?.resume(throwing: mapped)
            continuation = nil
        }
    }
}

private struct OpenMeteoReverseResponse: Decodable {
    let results: [OpenMeteoReverseResult]?
}

private struct OpenMeteoReverseResult: Decodable {
    let id: Int
    let name: String
    let admin1: String?
    let country: String?
    let latitude: Double
    let longitude: Double
}
