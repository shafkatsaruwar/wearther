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
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var timeoutTask: Task<Void, Never>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func locateCurrentPlace() async throws -> LocationResult {
        let location = try await requestLocation()
        if let place = await reverseGeocode(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ) {
            return place
        }
        throw LocationServiceError.reverseFailed
    }

    private func requestLocation() async throws -> CLLocation {
        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await requestAuthorization()
        }

        switch status {
        case .denied:
            throw LocationServiceError.denied
        case .restricted:
            throw LocationServiceError.restricted
        case .authorizedAlways, .authorizedWhenInUse:
            break
        case .notDetermined:
            throw LocationServiceError.denied
        @unknown default:
            break
        }

        if locationContinuation != nil {
            locationContinuation?.resume(throwing: LocationServiceError.unavailable)
            locationContinuation = nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.manager.requestLocation()

            self.timeoutTask?.cancel()
            self.timeoutTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 15_000_000_000)
                guard let self, !Task.isCancelled else { return }
                if let pending = self.locationContinuation {
                    self.locationContinuation = nil
                    pending.resume(throwing: LocationServiceError.timedOut)
                }
            }
        }
    }

    private func requestAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            self.manager.requestWhenInUseAuthorization()
        }
    }

    /// Resolve coordinates to a named place: CLGeocoder first, then Nominatim.
    func reverseGeocode(latitude: Double, longitude: Double) async -> LocationResult? {
        if let apple = await reverseWithApple(latitude: latitude, longitude: longitude) {
            return apple
        }
        if let nominatim = await reverseWithNominatim(latitude: latitude, longitude: longitude) {
            return nominatim
        }
        return nil
    }

    private func reverseWithApple(latitude: Double, longitude: Double) async -> LocationResult? {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)
        do {
            let marks = try await geocoder.reverseGeocodeLocation(location)
            guard let mark = marks.first else { return nil }

            let name = mark.locality
                ?? mark.subAdministrativeArea
                ?? mark.subLocality
                ?? mark.name
            guard let name, !name.isEmpty else { return nil }

            let region = mark.administrativeArea
            let country = mark.country ?? "Unknown"
            let idSeed = "\(name)-\(region ?? "")-\(country)"
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")

            return LocationResult(
                id: "here-\(idSeed)",
                name: name,
                region: region,
                country: country,
                latitude: latitude,
                longitude: longitude
            )
        } catch {
            return nil
        }
    }

    private func reverseWithNominatim(latitude: Double, longitude: Double) async -> LocationResult? {
        var components = URLComponents(string: "https://nominatim.openstreetmap.org/reverse")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "addressdetails", value: "1"),
            URLQueryItem(name: "accept-language", value: "en"),
            URLQueryItem(name: "zoom", value: "10"),
        ]
        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Wearther/1.0 (outfit weather app)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(NominatimReverseResponse.self, from: data)
            let address = decoded.address
            let name = address?.city
                ?? address?.town
                ?? address?.village
                ?? address?.municipality
                ?? address?.county
            guard let name, !name.isEmpty else { return nil }

            let region = address?.state
            let country = address?.country ?? "Unknown"
            let idSeed = "\(name)-\(region ?? "")-\(country)"
                .lowercased()
                .replacingOccurrences(of: " ", with: "-")

            return LocationResult(
                id: "here-\(idSeed)",
                name: name,
                region: region,
                country: country,
                latitude: latitude,
                longitude: longitude
            )
        } catch {
            return nil
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            guard let pending = authContinuation else { return }
            let status = manager.authorizationStatus
            guard status != .notDetermined else { return }
            authContinuation = nil
            pending.resume(returning: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            timeoutTask?.cancel()
            timeoutTask = nil
            guard let location = locations.last else {
                locationContinuation?.resume(throwing: LocationServiceError.unavailable)
                locationContinuation = nil
                return
            }
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
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
            locationContinuation?.resume(throwing: mapped)
            locationContinuation = nil
        }
    }
}

private struct NominatimReverseResponse: Decodable {
    let address: NominatimAddress?
}

private struct NominatimAddress: Decodable {
    let city: String?
    let town: String?
    let village: String?
    let municipality: String?
    let county: String?
    let state: String?
    let country: String?
}
