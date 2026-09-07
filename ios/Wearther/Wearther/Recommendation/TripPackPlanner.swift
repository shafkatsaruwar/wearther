import Foundation

enum TripPackCategory: String, CaseIterable, Identifiable {
    case tops = "Tops"
    case bottoms = "Bottoms"
    case outerwear = "Outerwear"
    case shoes = "Shoes"
    case extras = "Extras"

    var id: String { rawValue }
}

struct TripPackGroup: Equatable, Identifiable {
    var id: String { category.rawValue }
    let category: TripPackCategory
    let items: [String]
}

struct TripPackPlan: Equatable {
    let destinationName: String
    let days: Int
    let daysCovered: [DailyForecast]
    let summary: String
    let packItems: [String]
    let groups: [TripPackGroup]
    let notes: [String]
    let warnings: [String]
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
            let items = ["Light layer", "Comfortable shoes"]
            return TripPackPlan(
                destinationName: destinationName,
                days: clampedDays,
                daysCovered: [],
                summary: "Weather unavailable — pack a flexible layer just in case.",
                packItems: items,
                groups: group(items),
                notes: [],
                warnings: ["Forecast unavailable for this destination."]
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
        let windyHint = slice.contains { $0.conditionCode == "windy" || $0.condition.lowercased().contains("wind") }

        let bias = comfort?.effectiveWarmthBias ?? 0
        let style = comfort?.style ?? .casual
        let effectiveLow = Double(minLow) + bias
        let effectiveHigh = Double(maxHigh) + bias

        var tops: [String] = []
        var bottoms: [String] = []
        var outerwear: [String] = []
        var shoes: [String] = []
        var extras: [String] = []
        var notes: [String] = []
        var warnings: [String] = []

        if effectiveHigh >= 78 && effectiveLow >= 65 {
            tops.append(styleTop(style, warm: true))
            bottoms.append(styleBottom(style, warm: true))
            shoes.append(styleShoe(style, warm: true))
        } else if effectiveLow >= 55 {
            tops.append(styleTop(style, warm: false))
            bottoms.append(styleBottom(style, warm: false))
            shoes.append(styleShoe(style, warm: false))
            if swing >= 12 { outerwear.append(styleLightOuter(style)) }
        } else if effectiveLow >= 40 {
            tops.append(contentsOf: [styleTop(style, warm: false), styleKnit(style)])
            bottoms.append(styleBottom(style, warm: false))
            outerwear.append(styleLightOuter(style))
            shoes.append(styleShoe(style, warm: false))
        } else {
            tops.append(contentsOf: ["Warm base layer", styleKnit(style)])
            bottoms.append(styleBottom(style, warm: false))
            outerwear.append(styleHeavyOuter(style))
            shoes.append("Closed shoes")
        }

        if swing >= 15 {
            if !outerwear.contains(where: { $0.localizedCaseInsensitiveContains("layer") || $0.localizedCaseInsensitiveContains("overshirt") }) {
                outerwear.append("Packable mid-layer")
            }
            warnings.append("Temps swing \(swing)° across the trip.")
            notes.append("Dress in layers so mornings and afternoons both work.")
        }

        if rainyDays > 0 {
            outerwear.append(styleRain(style))
            if rainyDays >= 2 {
                shoes.append("Waterproof shoes or covers")
            }
            warnings.append(
                rainyDays == 1
                    ? "Rain likely on 1 day."
                    : "Rain likely on \(rainyDays) days."
            )
            notes.append("Keep a waterproof layer near the top of your bag.")
        }

        if coldDays > 0 {
            outerwear.append("Warm evening layer")
            warnings.append("Nights dip near \(minLow)°.")
        }

        if hotDays > 0 {
            extras.append("Sun hat or sunglasses")
            warnings.append("Afternoons hit \(maxHigh)°.")
            notes.append("Favor breathable fabrics on the hottest days.")
        }

        if windyHint {
            warnings.append("Expect breezy stretches.")
        }

        if let always = comfort?.alwaysPack {
            if always.rainJacket, !outerwear.contains(where: { $0.localizedCaseInsensitiveContains("rain") }) {
                outerwear.append("Rain shell")
            }
            if always.lightLayer,
               !outerwear.contains(where: { $0.localizedCaseInsensitiveContains("layer") || $0.localizedCaseInsensitiveContains("overshirt") }) {
                outerwear.append("Light layer")
            }
            if always.scarf {
                extras.append("Scarf")
            }
        }

        tops = dedupe(tops)
        bottoms = dedupe(bottoms)
        outerwear = dedupe(outerwear)
        shoes = dedupe(shoes)
        extras = dedupe(extras)

        let groups: [TripPackGroup] = [
            TripPackGroup(category: .tops, items: tops),
            TripPackGroup(category: .bottoms, items: bottoms),
            TripPackGroup(category: .outerwear, items: outerwear),
            TripPackGroup(category: .shoes, items: shoes),
            TripPackGroup(category: .extras, items: extras),
        ].filter { !$0.items.isEmpty }

        let packItems = groups.flatMap(\.items)
        let dayWord = clampedDays == 1 ? "day" : "days"
        let summary =
            "\(clampedDays)-\(dayWord) in \(destinationName): highs to \(maxHigh)°, lows near \(minLow)°."

        return TripPackPlan(
            destinationName: destinationName,
            days: clampedDays,
            daysCovered: slice,
            summary: summary,
            packItems: packItems,
            groups: groups,
            notes: notes,
            warnings: warnings
        )
    }

    private static func group(_ items: [String]) -> [TripPackGroup] {
        [TripPackGroup(category: .extras, items: items)]
    }

    private static func dedupe(_ items: [String]) -> [String] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.lowercased()).inserted }
    }

    private static func styleTop(_ style: StyleMode, warm: Bool) -> String {
        switch style {
        case .casual: return warm ? "Breathable tops" : "Light layers"
        case .smartCasual: return warm ? "Linen or button-up" : "Oxford or knit"
        case .athletic: return warm ? "Athletic tees" : "Performance tops"
        case .formal: return warm ? "Light dress shirts" : "Dress shirts"
        }
    }

    private static func styleBottom(_ style: StyleMode, warm: Bool) -> String {
        switch style {
        case .casual: return warm ? "Shorts or light pants" : "Jeans or chinos"
        case .smartCasual: return warm ? "Chinos or tailored shorts" : "Chinos"
        case .athletic: return warm ? "Athletic shorts" : "Joggers"
        case .formal: return "Dress trousers"
        }
    }

    private static func styleShoe(_ style: StyleMode, warm: Bool) -> String {
        switch style {
        case .casual: return "Comfortable shoes"
        case .smartCasual: return warm ? "Clean sneakers or loafers" : "Loafers or clean sneakers"
        case .athletic: return "Running shoes"
        case .formal: return "Leather shoes"
        }
    }

    private static func styleKnit(_ style: StyleMode) -> String {
        switch style {
        case .casual: return "Sweater or fleece"
        case .smartCasual: return "Fine-knit sweater"
        case .athletic: return "Training hoodie"
        case .formal: return "Fine-knit layer"
        }
    }

    private static func styleLightOuter(_ style: StyleMode) -> String {
        switch style {
        case .casual: return "Light jacket"
        case .smartCasual: return "Overshirt or blazer"
        case .athletic: return "Lightweight running jacket"
        case .formal: return "Blazer"
        }
    }

    private static func styleHeavyOuter(_ style: StyleMode) -> String {
        switch style {
        case .casual: return "Warm coat"
        case .smartCasual: return "Wool overcoat"
        case .athletic: return "Insulated training jacket"
        case .formal: return "Wool overcoat"
        }
    }

    private static func styleRain(_ style: StyleMode) -> String {
        switch style {
        case .casual: return "Rain jacket"
        case .smartCasual: return "Packable rain shell"
        case .athletic: return "Packable rain shell"
        case .formal: return "Tailored raincoat"
        }
    }
}
