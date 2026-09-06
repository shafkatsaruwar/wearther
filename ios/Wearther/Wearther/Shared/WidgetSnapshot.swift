import Foundation
import WidgetKit

enum WeartherAppGroup {
    static let id = "group.com.wearther.app.saruwar"
    static let snapshotKey = "wearther:widget-snapshot"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: id) ?? .standard
    }
}

struct WidgetHourSlot: Codable, Equatable, Identifiable {
    var id: String { timeLabel }
    var timeLabel: String
    var temperature: Int
    var tip: String
}

struct WidgetSnapshot: Codable, Equatable {
    var locationName: String
    var outfitTitle: String
    var shortOutfitTitle: String
    var explanation: String
    var confidenceLabel: String
    var temperature: Int
    var feelsLike: Int
    var condition: String
    var windSpeed: Int
    var packHint: String?
    var itemLabels: [String]
    var itemSymbols: [String]
    var laterHours: [WidgetHourSlot]
    var unitsSymbol: String
    var updatedAt: Date
    var isStale: Bool

    static let placeholder = WidgetSnapshot(
        locationName: "Boston",
        outfitTitle: "Long Sleeve, No Jacket",
        shortOutfitTitle: "Long Sleeve",
        explanation: "Mild and calm — a long sleeve is enough for the day.",
        confidenceLabel: "Confident",
        temperature: 68,
        feelsLike: 66,
        condition: "Partly cloudy",
        windSpeed: 11,
        packHint: "Pack layer",
        itemLabels: ["Long sleeve", "Chinos", "Sneakers"],
        itemSymbols: ["tshirt", "figure.stand", "shoeprints.fill"],
        laterHours: [
            WidgetHourSlot(timeLabel: "3 PM", temperature: 70, tip: "Same layer"),
            WidgetHourSlot(timeLabel: "6 PM", temperature: 64, tip: "Light layer"),
            WidgetHourSlot(timeLabel: "9 PM", temperature: 58, tip: "Add layer"),
        ],
        unitsSymbol: "F",
        updatedAt: Date(),
        isStale: false
    )

    var temperatureLabel: String { "\(temperature)°" }
    var windLabel: String { "Wind \(windSpeed)" }
    var weatherContext: String {
        let breeze = windSpeed >= 10 ? "breezy" : condition.lowercased()
        return "\(temperature)° · \(breeze)"
    }
    var locationDateLabel: String { "\(locationName) · Today" }
    var updatedLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last updated \(formatter.localizedString(for: updatedAt, relativeTo: Date()))"
    }
    var lockInline: String { "\(shortOutfitTitle) · \(temperature)°" }
    var lockRectangularPrimary: String { shortOutfitTitle }
    var lockRectangularSecondary: String {
        var parts = ["\(feelsLike)° feels"]
        if let packHint, !packHint.isEmpty {
            let trimmed = packHint.lowercased().replacingOccurrences(of: "pack ", with: "")
            parts.append("\(trimmed) later")
        }
        return parts.joined(separator: " · ")
    }
}

enum WidgetSnapshotStore {
    static func load() -> WidgetSnapshot? {
        guard let data = WeartherAppGroup.defaults.data(forKey: WeartherAppGroup.snapshotKey) else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        WeartherAppGroup.defaults.set(data, forKey: WeartherAppGroup.snapshotKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func saveFromApp(
        location: LocationResult,
        weather: WeatherData,
        outfit: OutfitRecommendation,
        comfort: ComfortPreference
    ) {
        let units = comfort.units
        let temp = TemperatureDisplay.value(weather.temperature, units: units)
        let feels = TemperatureDisplay.value(weather.feelsLike, units: units)
        let title = FitCopy.formatTitle(outfit)
        let short = shortTitle(from: title)
        let tip = FitCopy.packTip(outfit: outfit, weather: weather)
        let items = Array(outfit.items.prefix(3))

        let snapshot = WidgetSnapshot(
            locationName: location.name,
            outfitTitle: title,
            shortOutfitTitle: short,
            explanation: outfit.explanation,
            confidenceLabel: FitCopy.confidenceLabel(comfort),
            temperature: temp,
            feelsLike: feels,
            condition: weather.condition,
            windSpeed: weather.windSpeed,
            packHint: tip.value,
            itemLabels: items,
            itemSymbols: items.map(ClothingSymbol.sfSymbol(for:)),
            laterHours: laterSlots(from: weather.hourly, units: units),
            unitsSymbol: units.symbol,
            updatedAt: Date(),
            isStale: false
        )
        save(snapshot)
    }

    private static func shortTitle(from title: String) -> String {
        let cleaned = title
            .replacingOccurrences(of: ", No Jacket", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let first = cleaned.split(separator: ",").first {
            return String(first).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }

    private static func laterSlots(from hourly: [HourlyWeather], units: TempUnits) -> [WidgetHourSlot] {
        let targets = [15, 18, 21]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        var slots: [WidgetHourSlot] = []
        for hour in targets {
            guard let match = hourly.first(where: { entry in
                guard let date = ISO8601DateFormatter().date(from: entry.time)
                        ?? formatter.date(from: entry.time)
                        ?? parseLoose(entry.time)
                else { return false }
                return Calendar.current.component(.hour, from: date) == hour
            }) else { continue }

            let label: String
            switch hour {
            case 15: label = "3 PM"
            case 18: label = "6 PM"
            default: label = "9 PM"
            }

            let tip: String
            if match.temperature <= 58 {
                tip = "Add layer"
            } else if match.precipitationChance >= 40 {
                tip = "Rain layer"
            } else if match.temperature <= 64 {
                tip = "Light layer"
            } else {
                tip = "Same layer"
            }

            slots.append(
                WidgetHourSlot(
                    timeLabel: label,
                    temperature: TemperatureDisplay.value(match.temperature, units: units),
                    tip: tip
                )
            )
        }
        return slots
    }

    private static func parseLoose(_ iso: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return formatter.date(from: String(iso.prefix(16)))
    }
}

enum ClothingSymbol {
    static func sfSymbol(for label: String) -> String {
        let lower = label.lowercased()
        if lower.contains("blazer") || lower.contains("overshirt") || lower.contains("oxford")
            || lower.contains("button-up") || lower.contains("dress shirt") {
            return "tshirt"
        }
        if lower.contains("hoodie") || lower.contains("athletic") || lower.contains("performance")
            || lower.contains("training") {
            return "figure.run"
        }
        if lower.contains("jogger") { return "figure.walk" }
        if lower.contains("loafer") || lower.contains("leather") || lower.contains("running shoe") {
            return "shoeprints.fill"
        }
        if lower.contains("linen") || lower.contains("short sleeve") || lower.contains("t-shirt")
            || lower.contains("tee") {
            return "tshirt.fill"
        }
        if lower.contains("long sleeve") { return "tshirt" }
        if lower.contains("sweater") || lower.contains("base layer") || lower.contains("fine-knit")
            || lower.contains("fine knit") {
            return "figure.stand.dress.line.vertical.figure"
        }
        if lower.contains("rain") || lower.contains("waterproof") || lower.contains("shell") {
            return "cloud.rain.fill"
        }
        if lower.contains("jacket") || lower.contains("coat") || lower.contains("overcoat") {
            return "cloud.fill"
        }
        if lower.contains("shorts") { return "figure.walk" }
        if lower.contains("pants") || lower.contains("jeans") || lower.contains("chinos")
            || lower.contains("trousers") {
            return "figure.stand"
        }
        if lower.contains("scarf") { return "wind" }
        if lower.contains("gloves") { return "hand.raised.fill" }
        if lower.contains("sneaker") || lower.contains("shoe") { return "shoeprints.fill" }
        return "hanger"
    }
}
