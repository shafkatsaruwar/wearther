import Foundation

struct TripPackPlan: Equatable {
    let destinationName: String
    let days: Int
    let daysCovered: [DailyForecast]
    let summary: String
    let packItems: [String]
    let notes: [String]
}

enum TripPackPlanner {
    static func plan(
        destinationName: String,
        days: Int,
        daily: [DailyForecast],
        comfort: ComfortPreference?
    ) -> TripPackPlan {
        let clampedDays = max(1, min(7, days))
        let slice = Array(daily.prefix(clampedDays))
        guard !slice.isEmpty else {
            return TripPackPlan(
                destinationName: destinationName,
                days: clampedDays,
                daysCovered: [],
                summary: "Weather unavailable — pack a flexible layer just in case.",
                packItems: ["Light layer", "Comfortable shoes"],
                notes: []
            )
        }

        let highs = slice.map(\.high)
        let lows = slice.map(\.low)
        let maxHigh = highs.max() ?? 70
        let minLow = lows.min() ?? 55
        let swing = maxHigh - minLow
        let rainyDays = slice.filter { $0.precipitationChance >= 45 }.count
        let coldDays = slice.filter { $0.low <= 45 }.count
        let hotDays = slice.filter { $0.high >= 82 }.count

        let bias = comfort?.effectiveWarmthBias ?? 0
        let effectiveLow = Double(minLow) + bias
        let effectiveHigh = Double(maxHigh) + bias

        var items: [String] = []
        var notes: [String] = []

        if effectiveHigh >= 78 && effectiveLow >= 65 {
            items.append(contentsOf: ["Breathable tops", "Shorts or light pants"])
        } else if effectiveLow >= 55 {
            items.append(contentsOf: ["Light layers", "Jeans or chinos"])
        } else if effectiveLow >= 40 {
            items.append(contentsOf: ["Sweater or fleece", "Long pants"])
        } else {
            items.append(contentsOf: ["Warm coat", "Thermal base layer"])
        }

        if swing >= 15 {
            items.append("Packable mid-layer")
            notes.append("Temps swing \(swing)° across the trip — dress in layers.")
        }

        if rainyDays > 0 {
            items.append("Rain jacket")
            if rainyDays >= 2 {
                items.append("Waterproof shoes or covers")
            }
            notes.append(
                rainyDays == 1
                    ? "Rain likely on 1 day — keep a waterproof layer handy."
                    : "Rain likely on \(rainyDays) days — pack for wet weather."
            )
        }

        if coldDays > 0 {
            items.append("Warm evening layer")
            notes.append("Nights dip near \(minLow)° — bring something for evenings.")
        }

        if hotDays > 0 {
            items.append("Sun hat or sunglasses")
            notes.append("Afternoons hit \(maxHigh)° — favor breathable fabrics.")
        }

        if let always = comfort?.alwaysPack {
            if always.rainJacket, !items.contains(where: { $0.localizedCaseInsensitiveContains("rain") }) {
                items.append("Rain jacket")
            }
            if always.lightLayer, !items.contains(where: { $0.localizedCaseInsensitiveContains("layer") }) {
                items.append("Light layer")
            }
            if always.scarf {
                items.append("Scarf")
            }
        }

        var seen = Set<String>()
        items = items.filter { seen.insert($0.lowercased()).inserted }

        let dayWord = clampedDays == 1 ? "day" : "days"
        let summary =
            "\(clampedDays)-\(dayWord) in \(destinationName): highs to \(maxHigh)°, lows near \(minLow)°."

        return TripPackPlan(
            destinationName: destinationName,
            days: clampedDays,
            daysCovered: slice,
            summary: summary,
            packItems: items,
            notes: notes
        )
    }
}
