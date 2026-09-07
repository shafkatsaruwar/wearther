import Foundation

/// Mirrors `public/remote-config.json` / web `src/lib/remoteConfig.ts`.
/// Edit that JSON + deploy to tweak thresholds/copy without a new App Store binary.
struct WeartherRemoteConfig: Codable, Equatable {
    var version: Int
    var thresholds: Thresholds
    var timing: Timing
    var copy: Copy
    var flags: Flags

    struct Thresholds: Codable, Equatable {
        var strongWindMph: Double
        var highRainChance: Double
        var packRainChance: Double
        var highHumidity: Double
        var lowHumidity: Double
        var significantDropF: Double
        var diurnalSpanF: Double
        var windChillBelowF: Double
        var windJacketMinF: Double
        var windJacketMaxF: Double
        var humidHotFeelsF: Double
        var tempBandsF: [Double]
    }

    struct Timing: Codable, Equatable {
        var weatherStaleMinutes: Int
        var widgetRefreshMinutes: Int
        var widgetStaleHours: Int
        var configCacheMinutes: Int
    }

    struct Copy: Codable, Equatable {
        var confidence: Confidence
        var packTips: PackTips
        var feedback: Feedback
        var notificationTitle: String

        struct Confidence: Codable, Equatable {
            var confident: String
            var bringBackup: String
            var rainRisk: String
            var eveningDrop: String
            var tunedForYou: String
        }

        struct PackTips: Codable, Equatable {
            var rainLayer: String
            var lightLayer: String
            var travelLight: String
        }

        struct Feedback: Codable, Equatable {
            var too_cold: String
            var too_hot: String
            var perfect: String
        }
    }

    struct Flags: Codable, Equatable {
        var enableOccasionPicker: Bool
        var enableTripPack: Bool
        var enableMorningNotifications: Bool
    }

    static let bundled = WeartherRemoteConfig(
        version: 1,
        thresholds: .init(
            strongWindMph: 12,
            highRainChance: 45,
            packRainChance: 40,
            highHumidity: 70,
            lowHumidity: 35,
            significantDropF: 10,
            diurnalSpanF: 12,
            windChillBelowF: 75,
            windJacketMinF: 52,
            windJacketMaxF: 75,
            humidHotFeelsF: 76,
            tempBandsF: [85, 76, 68, 60, 52, 42, 32]
        ),
        timing: .init(
            weatherStaleMinutes: 90,
            widgetRefreshMinutes: 30,
            widgetStaleHours: 3,
            configCacheMinutes: 60
        ),
        copy: .init(
            confidence: .init(
                confident: "Confident",
                bringBackup: "Bring backup",
                rainRisk: "Rain risk",
                eveningDrop: "Evening drop",
                tunedForYou: "Tuned for you"
            ),
            packTips: .init(
                rainLayer: "Rain layer",
                lightLayer: "Light layer",
                travelLight: "Travel light"
            ),
            feedback: .init(
                too_cold: "Got it. Tomorrow will lean warmer.",
                too_hot: "Got it. Tomorrow will lighten up.",
                perfect: "Nice. Keeping this baseline."
            ),
            notificationTitle: "Today’s Fit"
        ),
        flags: .init(
            enableOccasionPicker: true,
            enableTripPack: true,
            enableMorningNotifications: true
        )
    )
}

enum RemoteConfigStore {
    private static let cacheKey = "wearther:remote-config"
    private static let fetchedAtKey = "wearther:remote-config-fetched-at"
    private static let lock = NSLock()
    private static var memory = loadCached() ?? .bundled

    private static var defaults: UserDefaults {
        WeartherAppGroup.defaults
    }

    static var current: WeartherRemoteConfig {
        lock.lock()
        defer { lock.unlock() }
        // Prefer App Group cache so the widget extension sees the same knobs.
        if let shared = loadCached() {
            memory = shared
        }
        return memory
    }

    /// Call at launch (and when returning to foreground). Safe to call often.
    static func refreshIfNeeded() async {
        let cached = current
        if isCacheFresh(cached) { return }

        guard let url = configURL() else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return
            }
            let decoded = try JSONDecoder().decode(WeartherRemoteConfig.self, from: data)
            let merged = sanitize(decoded)
            lock.lock()
            memory = merged
            lock.unlock()
            if let encoded = try? JSONEncoder().encode(merged) {
                defaults.set(encoded, forKey: cacheKey)
                defaults.set(Date().timeIntervalSince1970, forKey: fetchedAtKey)
            }
        } catch {
            // Keep bundled / last cache.
        }
    }

    private static func configURL() -> URL? {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "WEARTHER_CONFIG_URL") as? String {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, let url = URL(string: trimmed) {
                return url
            }
        }
        // Public raw file on main — edit public/remote-config.json and push.
        return URL(string: "https://raw.githubusercontent.com/shafkatsaruwar/wearther/main/public/remote-config.json")
    }

    private static func loadCached() -> WeartherRemoteConfig? {
        guard let data = defaults.data(forKey: cacheKey) else { return nil }
        guard let decoded = try? JSONDecoder().decode(WeartherRemoteConfig.self, from: data) else {
            return nil
        }
        return sanitize(decoded)
    }

    private static func isCacheFresh(_ config: WeartherRemoteConfig) -> Bool {
        let fetchedAt = defaults.double(forKey: fetchedAtKey)
        guard fetchedAt > 0 else { return false }
        let ttl = TimeInterval(config.timing.configCacheMinutes * 60)
        return Date().timeIntervalSince1970 - fetchedAt < ttl
    }

    private static func sanitize(_ config: WeartherRemoteConfig) -> WeartherRemoteConfig {
        var next = config
        if next.thresholds.tempBandsF.count != 7 {
            next.thresholds.tempBandsF = WeartherRemoteConfig.bundled.thresholds.tempBandsF
        }
        return next
    }
}
