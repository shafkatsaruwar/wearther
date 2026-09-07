import Foundation

/// Pure clothing recommendation engine — mirrors web `lib/recommendOutfit.ts`.
enum OutfitRecommender {
    private static let strongWindMPH = 12.0
    private static let highRainChance = 45.0
    private static let highHumidity = 70.0
    private static let significantDropF = 10.0

    struct RecommendInput {
        let weather: WeatherData
        let comfort: ComfortPreference?
        var occasion: OccasionContext = .everyday
    }

    private struct BaseLayer {
        let title: String
        let items: [String]
        let warmthLevel: Double
        let reason: String
    }

    private struct LaterAdvice {
        let drop: Int
        let message: String
        let short: String
    }

    static func recommend(_ input: RecommendInput) -> OutfitRecommendation {
        let bias = input.comfort?.effectiveWarmthBias ?? 0
        let style = input.comfort?.style ?? .casual
        let alwaysPack = input.comfort?.alwaysPack
        let adjustedFeels = Double(input.weather.feelsLike) + bias

        let windy = Double(input.weather.windSpeed) >= strongWindMPH
        let rainy = Double(input.weather.precipitationChance) >= highRainChance
        let humid = Double(input.weather.humidity) >= highHumidity

        var effective = adjustedFeels
        if windy && adjustedFeels < 75 {
            effective -= min(6, round(Double(input.weather.windSpeed) / 4))
        }

        let base = baseLayer(for: effective, humid: humid)
        let later = laterDropAdvice(weather: input.weather, currentEffective: effective)

        var items = base.items
        var title = base.title
        var warmthLevel = base.warmthLevel
        var reasons = [base.reason]
        var bringLater = later?.short

        if rainy {
            if !items.contains(where: { $0.range(of: "rain|waterproof", options: .regularExpression) != nil }) {
                items.append("Rain jacket")
            }
            reasons.append("Rain is likely, so keep a waterproof layer handy.")
            warmthLevel = min(10, warmthLevel + 0.5)
        }

        if windy && effective >= 52 && effective <= 75 {
            if !items.contains(where: { $0.range(of: "jacket|coat|sweater", options: .regularExpression) != nil }) {
                items.append("Light jacket")
                title = joinTitle(title, "Light Jacket")
                warmthLevel = min(10, warmthLevel + 1)
            }
            reasons.append("It feels cooler because of the wind.")
        }

        if let later {
            if !items.contains(where: { $0.range(of: "jacket|coat|bring", options: .regularExpression) != nil }) {
                title = joinTitle(stripBring(title), "Bring a Jacket")
            } else if title.range(of: "bring", options: .caseInsensitive) == nil && later.drop >= Int(significantDropF) {
                title = joinTitle(stripBring(title), "Bring a Jacket")
            }
            reasons.append(later.message)
        }

        if humid && Double(input.weather.feelsLike) >= 76 {
            reasons.append("High humidity favors breathable fabrics like linen.")
        }

        if bias >= 2 {
            reasons.append("Based on your feedback, this leans a bit warmer.")
        } else if bias <= -2 {
            reasons.append("Based on your feedback, this leans a bit cooler.")
        }

        applyAlwaysPack(
            items: &items,
            title: &title,
            bringLater: &bringLater,
            alwaysPack: alwaysPack,
            reasons: &reasons
        )

        applyStyle(style, items: &items, title: &title)

        if style != .casual {
            reasons.append("Styled for a \(style.label.lowercased()) look.")
        }

        applyOccasion(
            input.occasion,
            weather: input.weather,
            items: &items,
            title: &title,
            bringLater: &bringLater,
            reasons: &reasons
        )

        let explanation = craftExplanation(
            reasons: reasons,
            weather: input.weather,
            windy: windy,
            rainy: rainy
        )

        let why = whyDetail(
            weather: input.weather,
            windy: windy,
            rainy: rainy,
            later: later
        )

        return OutfitRecommendation(
            title: title,
            items: dedupe(items),
            explanation: explanation,
            warmthLevel: warmthLevel,
            bringLater: bringLater,
            whyDetail: why
        )
    }

    static func recommendForHour(_ hour: HourlyWeather, comfort: ComfortPreference?) -> String {
        let bias = comfort?.effectiveWarmthBias ?? 0
        let t = Double(hour.feelsLike) + bias
        let rainy = Double(hour.precipitationChance) >= highRainChance

        let tip: String
        if t >= 85 { tip = rainy ? "Linen + rain layer" : "Linen / shorts" }
        else if t >= 76 { tip = rainy ? "Short sleeve + rain jacket" : "Short sleeve" }
        else if t >= 68 { tip = rainy ? "Light layers + rain jacket" : "Jacket optional" }
        else if t >= 60 { tip = "Long sleeve" }
        else if t >= 52 { tip = "Long sleeve + light jacket" }
        else if t >= 42 { tip = "Sweater + jacket" }
        else if t >= 32 { tip = "Sweater + coat" }
        else { tip = "Heavy coat + layers" }

        return styleHourTip(comfort?.style ?? .casual, tip)
    }

    // MARK: - Preferences

    private static func applyAlwaysPack(
        items: inout [String],
        title: inout String,
        bringLater: inout String?,
        alwaysPack: AlwaysPackPrefs?,
        reasons: inout [String]
    ) {
        guard let alwaysPack else { return }

        if alwaysPack.rainJacket,
           !items.contains(where: { $0.range(of: "rain|waterproof", options: .regularExpression) != nil }) {
            items.append("Rain jacket")
            reasons.append("You asked to always pack a rain jacket.")
        }

        if alwaysPack.lightLayer {
            bringLater = bringLater ?? "Bring a light layer for later."
            if title.range(of: "bring", options: .caseInsensitive) == nil {
                title = joinTitle(stripBring(title), "Bring a Jacket")
            }
            reasons.append("Keeping a light layer handy, as you prefer.")
        }

        if alwaysPack.scarf,
           !items.contains(where: { $0.localizedCaseInsensitiveContains("scarf") }) {
            items.append("Scarf")
            reasons.append("You asked to always pack a scarf.")
        }
    }

    private static func applyStyle(_ style: StyleMode, items: inout [String], title: inout String) {
        guard style != .casual else { return }
        items = items.map { styleItem(style, $0) }
        title = styleTitle(style, title)
    }

    private static func applyOccasion(
        _ occasion: OccasionContext,
        weather: WeatherData,
        items: inout [String],
        title: inout String,
        bringLater: inout String?,
        reasons: inout [String]
    ) {
        guard occasion != .everyday else { return }

        let rainy = Double(weather.precipitationChance) >= highRainChance
        let hot = Double(weather.feelsLike) >= 76
        let coolIndoor = Double(weather.feelsLike) >= 70

        if occasion.isCorporate {
            items = items.map { corporateItem(occasion, $0, rainy: rainy, hot: hot) }
            title = corporateTitle(occasion, title, rainy: rainy, hot: hot)
            items.removeAll { $0.range(of: "shorts|sandal|slide|flip.?flop", options: [.regularExpression, .caseInsensitive]) != nil }

            if !items.contains(where: { $0.range(of: "chino|trouser|pant|skirt", options: [.regularExpression, .caseInsensitive]) != nil }) {
                items.append(occasion == .formal || occasion == .meeting ? "Dress trousers" : "Lightweight chinos")
            }
            if !items.contains(where: { $0.range(of: "shirt|button|blouse|knit", options: [.regularExpression, .caseInsensitive]) != nil }) {
                if hot {
                    items.insert(occasion == .formal ? "Breathable dress shirt" : "Breathable button-up", at: 0)
                } else {
                    items.insert(occasion == .formal ? "Dress shirt" : "Button-up", at: 0)
                }
            }
            if !items.contains(where: { $0.range(of: "loafer|dress shoe|oxford|derby|boot", options: [.regularExpression, .caseInsensitive]) != nil }) {
                items.append(
                    rainy
                        ? "Water-resistant dress shoes"
                        : (occasion == .office ? "Loafers or clean dress shoes" : "Leather dress shoes")
                )
            }

            if coolIndoor,
               occasion == .office || occasion == .meeting,
               !items.contains(where: { $0.range(of: "blazer|cardigan|sweater|jacket|coat", options: [.regularExpression, .caseInsensitive]) != nil }) {
                bringLater = bringLater ?? (occasion == .meeting
                    ? "Bring an unlined blazer for AC."
                    : "Bring a light cardigan or unlined blazer for AC.")
                if title.range(of: "bring|layer|blazer|cardigan", options: [.regularExpression, .caseInsensitive]) == nil {
                    title = "\(title) + light layer"
                }
            }

            if rainy {
                if !items.contains(where: { $0.localizedCaseInsensitiveContains("umbrella") }) {
                    items.append("Umbrella")
                }
                if !items.contains(where: { $0.range(of: "rain|trench|waterproof", options: [.regularExpression, .caseInsensitive]) != nil }) {
                    items.append(occasion == .formal ? "Tailored raincoat or trench" : "Clean raincoat")
                }
                reasons.append("Use an umbrella or clean raincoat so the outfit stays professional.")
            }

            if occasion == .office {
                reasons.append("Warm commute, but offices often run cool, so a light layer is worth bringing.")
            } else {
                reasons.append("This keeps the outfit polished while staying breathable for the weather.")
            }
        } else if occasion == .remote {
            items = items.map { remoteItem($0, feelsLike: weather.feelsLike) }
            title = remoteTitle(feelsLike: weather.feelsLike)
            reasons.append("Remote day — comfort first, still weather-aware.")
        } else if occasion == .goingOut {
            items = items.map(goingOutItem)
            title = goingOutTitle(title)
            reasons.append("Going out — a bit more styled, still practical for the weather.")
        }

        items = dedupe(items)
    }

    private static func corporateItem(_ occasion: OccasionContext, _ item: String, rainy: Bool, hot: Bool) -> String {
        let lower = item.lowercased()
        if lower.contains("shorts"), !lower.contains("pants") {
            return occasion == .formal || occasion == .meeting ? "Dress trousers" : "Lightweight chinos"
        }
        if lower.range(of: "sandal|slide|flip", options: .regularExpression) != nil {
            return rainy ? "Water-resistant dress shoes" : "Loafers"
        }
        if lower.contains("jean") {
            return occasion == .formal || occasion == .meeting ? "Dress trousers" : "Chinos"
        }
        if lower.range(of: "jogger|sweat", options: .regularExpression) != nil {
            return occasion == .formal ? "Dress trousers" : "Chinos"
        }
        if lower.range(of: "hoodie|athletic tee|performance|training tee|tee\\b|t-shirt", options: .regularExpression) != nil {
            if hot { return occasion == .formal ? "Breathable dress shirt" : "Breathable button-up" }
            return occasion == .formal ? "Dress shirt" : "Button-up"
        }
        if lower.contains("linen"), lower.range(of: "shirt|sleeve", options: .regularExpression) != nil {
            return hot ? "Breathable button-up" : "Linen button-up"
        }
        if lower.contains("short sleeve") {
            return hot ? "Breathable button-up" : "Casual button-up"
        }
        if lower.range(of: "sneaker|running shoe", options: .regularExpression) != nil {
            if rainy { return "Water-resistant dress shoes" }
            return occasion == .office ? "Loafers or clean dress shoes" : "Leather dress shoes"
        }
        if lower.contains("suede") {
            return rainy ? "Water-resistant dress shoes" : "Leather dress shoes"
        }
        if lower.range(of: "rain jacket|rain shell|packable rain", options: .regularExpression) != nil {
            return occasion == .formal ? "Tailored raincoat or trench" : "Clean raincoat"
        }
        if lower.range(of: "light jacket|overshirt", options: .regularExpression) != nil, !lower.contains("rain"), !lower.contains("blazer") {
            return occasion == .meeting || occasion == .formal
                ? "Unlined blazer"
                : "Unlined blazer or light cardigan"
        }
        return item
    }

    private static func corporateTitle(_ occasion: OccasionContext, _ title: String, rainy: Bool, hot: Bool) -> String {
        var next = title
        next = next.replacingOccurrences(of: "shorts", with: occasion == .formal ? "Trousers" : "Chinos", options: .caseInsensitive)
        next = next.replacingOccurrences(of: #"linen\s*/\s*shorts"#, with: "Breathable button-up", options: [.regularExpression, .caseInsensitive])
        next = next.replacingOccurrences(of: "short sleeve", with: "Button-up", options: .caseInsensitive)
        next = next.replacingOccurrences(of: "athletic tee", with: "Button-up", options: .caseInsensitive)
        if hot, next.range(of: "button|dress shirt|shirt", options: [.regularExpression, .caseInsensitive]) == nil {
            next = occasion == .formal ? "Dress shirt" : "Button-up + chinos"
        }
        if rainy, next.range(of: "rain|trench|umbrella", options: [.regularExpression, .caseInsensitive]) == nil {
            next = "\(next) + raincoat"
        }
        return next
    }

    private static func remoteItem(_ item: String, feelsLike: Int) -> String {
        let lower = item.lowercased()
        if lower.range(of: "dress shirt|oxford|button-up|button up", options: .regularExpression) != nil {
            return feelsLike >= 72 ? "Soft tee" : "Soft sweater"
        }
        if lower.range(of: "chino|trouser|dress pant", options: .regularExpression) != nil {
            return "Joggers"
        }
        if lower.range(of: "loafer|dress shoe|leather shoe|oxford", options: .regularExpression) != nil {
            return feelsLike < 60 ? "Socks / slippers" : "Comfort sneakers"
        }
        if lower.contains("blazer") {
            return feelsLike < 68 ? "Hoodie or cardigan" : item
        }
        return item
    }

    private static func remoteTitle(feelsLike: Int) -> String {
        if feelsLike >= 76 { return "Soft tee + joggers" }
        if feelsLike >= 60 { return "Comfort layers" }
        return "Soft sweater + joggers"
    }

    private static func goingOutItem(_ item: String) -> String {
        let lower = item.lowercased()
        if lower.range(of: "tee\\b|t-shirt|athletic tee", options: .regularExpression) != nil { return "Nice casual shirt" }
        if lower.contains("jean") { return "Dark jeans or chinos" }
        if lower.contains("sneaker") { return "Clean sneakers" }
        if lower.contains("hoodie") { return "Light overshirt" }
        return item
    }

    private static func goingOutTitle(_ title: String) -> String {
        title
            .replacingOccurrences(of: "athletic tee", with: "Casual shirt", options: .caseInsensitive)
            .replacingOccurrences(of: "short sleeve", with: "Casual shirt", options: .caseInsensitive)
    }

    private static func styleItem(_ style: StyleMode, _ item: String) -> String {
        let lower = item.lowercased()

        switch style {
        case .casual:
            return item
        case .smartCasual:
            if lower.contains("linen") && lower.contains("shirt") { return "Linen button-up" }
            if lower.contains("short sleeve") || lower.contains("lightweight short") { return "Casual button-up" }
            if lower.contains("long sleeve") { return "Oxford shirt" }
            if lower.contains("shorts") && !lower.contains("pants") { return "Chinos or tailored shorts" }
            if lower.contains("jeans") || lower.contains("pants") || lower.contains("chinos") { return "Chinos" }
            if lower.contains("sneaker") { return "Clean sneakers or loafers" }
            if lower.contains("light jacket") { return "Unstructured blazer or overshirt" }
            return item
        case .athletic:
            if lower.contains("linen") || lower.contains("short sleeve") || lower.contains("lightweight short") {
                return "Breathable athletic tee"
            }
            if lower.contains("long sleeve") { return "Performance long sleeve" }
            if lower.contains("sweater") { return "Light training hoodie" }
            if lower.contains("shorts") { return "Athletic shorts" }
            if lower.contains("pants") || lower.contains("jeans") || lower.contains("chinos") { return "Joggers" }
            if lower.contains("sneaker") || lower.contains("shoe") { return "Running shoes" }
            if lower.contains("rain") { return "Packable rain shell" }
            if lower.contains("light jacket") { return "Lightweight running jacket" }
            if lower.contains("coat") || lower.contains("heavy") { return "Insulated training jacket" }
            return item
        case .formal:
            if lower.contains("linen") { return "Dress shirt (light fabric)" }
            if lower.contains("short sleeve") || lower.contains("lightweight short") { return "Short-sleeve dress shirt" }
            if lower.contains("long sleeve") || lower.contains("oxford") { return "Dress shirt" }
            if lower.contains("sweater") { return "Fine-knit sweater" }
            if lower.contains("shorts") { return "Dress trousers" }
            if lower.contains("pants") || lower.contains("jeans") || lower.contains("chinos") { return "Dress trousers" }
            if lower.contains("sneaker") || lower.contains("shoe") { return "Leather shoes" }
            if lower.contains("light jacket") { return "Blazer" }
            if lower.contains("rain") { return "Tailored raincoat" }
            if lower.contains("coat") || lower.contains("heavy") { return "Wool overcoat" }
            return item
        }
    }

    private static func styleTitle(_ style: StyleMode, _ title: String) -> String {
        var result = title
        switch style {
        case .casual:
            break
        case .smartCasual:
            result = result
                .replacingOccurrences(of: "Short Sleeve or Linen", with: "Button-up", options: .caseInsensitive)
                .replacingOccurrences(of: "Short Sleeve or Thin Long Sleeve", with: "Button-up or knit", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen + Shorts", with: "Linen button-up + chinos", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen or Short Sleeve + Shorts", with: "Button-up + chinos", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen", with: "Linen button-up", options: .caseInsensitive)
                .replacingOccurrences(of: "Long Sleeve", with: "Oxford", options: .caseInsensitive)
                .replacingOccurrences(of: "Light Jacket", with: "Overshirt", options: .caseInsensitive)
        case .athletic:
            result = result
                .replacingOccurrences(of: "Short Sleeve or Linen", with: "Athletic tee", options: .caseInsensitive)
                .replacingOccurrences(of: "Short Sleeve or Thin Long Sleeve", with: "Performance tee", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen + Shorts", with: "Tee + athletic shorts", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen or Short Sleeve + Shorts", with: "Tee + athletic shorts", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen", with: "Athletic tee", options: .caseInsensitive)
                .replacingOccurrences(of: "Long Sleeve", with: "Performance top", options: .caseInsensitive)
                .replacingOccurrences(of: "Light Jacket", with: "Running jacket", options: .caseInsensitive)
                .replacingOccurrences(of: "Sweater", with: "Hoodie", options: .caseInsensitive)
                .replacingOccurrences(of: "Heavy Jacket / Coat", with: "Insulated jacket", options: .caseInsensitive)
                .replacingOccurrences(of: "Heavy Jacket", with: "Insulated jacket", options: .caseInsensitive)
        case .formal:
            result = result
                .replacingOccurrences(of: "Short Sleeve or Linen", with: "Dress shirt", options: .caseInsensitive)
                .replacingOccurrences(of: "Short Sleeve or Thin Long Sleeve", with: "Dress shirt", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen + Shorts", with: "Dress shirt + trousers", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen or Short Sleeve + Shorts", with: "Dress shirt + trousers", options: .caseInsensitive)
                .replacingOccurrences(of: "Linen", with: "Dress shirt", options: .caseInsensitive)
                .replacingOccurrences(of: "Long Sleeve", with: "Dress shirt", options: .caseInsensitive)
                .replacingOccurrences(of: "Light Jacket", with: "Blazer", options: .caseInsensitive)
                .replacingOccurrences(of: "Sweater", with: "Fine knit", options: .caseInsensitive)
                .replacingOccurrences(of: "Heavy Jacket / Coat", with: "Overcoat", options: .caseInsensitive)
                .replacingOccurrences(of: "Heavy Jacket", with: "Overcoat", options: .caseInsensitive)
                .replacingOccurrences(of: "Winter Coat + Warm Layers", with: "Overcoat + layers", options: .caseInsensitive)
        }
        return result
    }

    private static func styleHourTip(_ style: StyleMode, _ tip: String) -> String {
        switch style {
        case .casual:
            return tip
        case .smartCasual:
            return tip
                .replacingOccurrences(of: "Linen", with: "Button-up", options: .caseInsensitive)
                .replacingOccurrences(of: "Short sleeve", with: "Button-up", options: .caseInsensitive)
                .replacingOccurrences(of: "Long sleeve", with: "Oxford", options: .caseInsensitive)
                .replacingOccurrences(of: "shorts", with: "chinos", options: .caseInsensitive)
        case .athletic:
            return tip
                .replacingOccurrences(of: "Linen", with: "Athletic tee", options: .caseInsensitive)
                .replacingOccurrences(of: "Short sleeve", with: "Athletic tee", options: .caseInsensitive)
                .replacingOccurrences(of: "Long sleeve", with: "Perf. top", options: .caseInsensitive)
                .replacingOccurrences(of: "Jacket optional", with: "Light shell optional", options: .caseInsensitive)
                .replacingOccurrences(of: "light jacket", with: "running jacket", options: .caseInsensitive)
                .replacingOccurrences(of: "Sweater", with: "Hoodie", options: .caseInsensitive)
                .replacingOccurrences(of: "coat", with: "insulated jacket", options: .caseInsensitive)
        case .formal:
            return tip
                .replacingOccurrences(of: "Linen", with: "Dress shirt", options: .caseInsensitive)
                .replacingOccurrences(of: "Short sleeve", with: "Dress shirt", options: .caseInsensitive)
                .replacingOccurrences(of: "Long sleeve", with: "Dress shirt", options: .caseInsensitive)
                .replacingOccurrences(of: "Jacket optional", with: "Blazer optional", options: .caseInsensitive)
                .replacingOccurrences(of: "light jacket", with: "blazer", options: .caseInsensitive)
                .replacingOccurrences(of: "Sweater", with: "Fine knit", options: .caseInsensitive)
                .replacingOccurrences(of: "coat", with: "overcoat", options: .caseInsensitive)
        }
    }

    // MARK: - Core engine

    private static func baseLayer(for temp: Double, humid: Bool) -> BaseLayer {
        if temp >= 85 {
            return BaseLayer(
                title: humid ? "Linen + Shorts" : "Linen or Short Sleeve + Shorts",
                items: humid
                    ? ["Linen shirt", "Shorts", "Sneakers"]
                    : ["Linen or lightweight short sleeve", "Shorts", "Sneakers"],
                warmthLevel: 1,
                reason: "It's hot out — keep it light and breathable."
            )
        }
        if temp >= 76 {
            return BaseLayer(
                title: humid ? "Linen" : "Short Sleeve or Linen",
                items: humid
                    ? ["Linen shirt", "Shorts or light pants", "Sneakers"]
                    : ["Short sleeve or linen", "Shorts or light pants", "Sneakers"],
                warmthLevel: 2,
                reason: "Warm weather calls for light, easy layers."
            )
        }
        if temp >= 68 {
            return BaseLayer(
                title: "Short Sleeve or Thin Long Sleeve",
                items: ["Short sleeve or thin long sleeve", "Pants or chinos", "Sneakers"],
                warmthLevel: 3,
                reason: "Mild and comfortable — a thin top should be enough."
            )
        }
        if temp >= 60 {
            return BaseLayer(
                title: "Long Sleeve",
                items: ["Long sleeve shirt", "Jeans or chinos", "Sneakers"],
                warmthLevel: 4,
                reason: "Cool enough for long sleeves without a jacket."
            )
        }
        if temp >= 52 {
            return BaseLayer(
                title: "Long Sleeve + Light Jacket",
                items: ["Long sleeve shirt", "Light jacket", "Jeans or chinos", "Sneakers"],
                warmthLevel: 5,
                reason: "A light jacket should keep you comfortable."
            )
        }
        if temp >= 42 {
            return BaseLayer(
                title: "Sweater + Jacket",
                items: ["Sweater", "Light jacket", "Pants", "Sneakers"],
                warmthLevel: 6,
                reason: "Chilly air — sweater plus a jacket works well."
            )
        }
        if temp >= 32 {
            return BaseLayer(
                title: "Sweater + Heavy Jacket",
                items: ["Sweater", "Heavy jacket / coat", "Pants", "Closed shoes"],
                warmthLevel: 8,
                reason: "Cold enough for a heavy outer layer over a sweater."
            )
        }
        return BaseLayer(
            title: "Winter Coat + Warm Layers",
            items: [
                "Warm base layer",
                "Sweater",
                "Heavy jacket / coat",
                "Scarf",
                "Gloves",
            ],
            warmthLevel: 10,
            reason: "Freezing conditions — bundle up with coat, scarf, and gloves."
        )
    }

    private static func laterDropAdvice(weather: WeatherData, currentEffective: Double) -> LaterAdvice? {
        guard !weather.hourly.isEmpty else { return nil }

        let coldest = weather.hourly.map(\.feelsLike).min() ?? Int(currentEffective)
        let drop = currentEffective - Double(coldest)

        if drop < significantDropF { return nil }
        if coldest >= 68 { return nil }

        return LaterAdvice(
            drop: Int(round(drop)),
            message: "It drops to about \(coldest)° later — bring a jacket for later.",
            short: "Bring a jacket for later."
        )
    }

    private static func craftExplanation(
        reasons: [String],
        weather: WeatherData,
        windy: Bool,
        rainy: Bool
    ) -> String {
        if windy && weather.feelsLike < 70 && !rainy {
            let rest = reasons
                .filter { !$0.localizedCaseInsensitiveContains("wind") }
                .prefix(1)
                .joined(separator: " ")
            var text = "It's cool and breezy today. The jacket will help with the wind."
            if !rest.isEmpty { text += " \(rest)" }
            return text.trimmingCharacters(in: .whitespaces)
        }

        var seen = Set<String>()
        let unique = reasons.filter { seen.insert($0).inserted }.prefix(2)
        return unique.joined(separator: " ")
    }

    private static func whyDetail(
        weather: WeatherData,
        windy: Bool,
        rainy: Bool,
        later: LaterAdvice?
    ) -> String {
        var parts: [String] = ["Feels like \(weather.feelsLike)°"]

        if weather.humidity >= 70 {
            parts.append("humidity is high (\(weather.humidity)%)")
        } else if weather.humidity <= 35 {
            parts.append("humidity is low (\(weather.humidity)%)")
        } else {
            parts.append("humidity is moderate (\(weather.humidity)%)")
        }

        if windy {
            parts.append("wind is breezy (\(weather.windSpeed) mph)")
        } else {
            parts.append("wind is mild (\(weather.windSpeed) mph)")
        }

        if rainy {
            parts.append("rain chance is \(weather.precipitationChance)%")
        }

        if let later {
            parts.append("evening drops about \(later.drop)°")
        } else if !weather.hourly.isEmpty {
            let coldest = weather.hourly.map(\.feelsLike).min() ?? weather.feelsLike
            let drop = max(0, weather.feelsLike - coldest)
            parts.append("evening only drops \(drop)°")
        }

        return parts.joined(separator: ", ") + "."
    }

    private static func joinTitle(_ base: String, _ addition: String) -> String {
        if base.localizedCaseInsensitiveContains(addition) { return base }
        return "\(base) + \(addition)"
    }

    private static func stripBring(_ title: String) -> String {
        title.replacingOccurrences(
            of: #"\s*\+\s*Bring a Jacket"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        ).trimmingCharacters(in: .whitespaces)
    }

    private static func dedupe(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var out: [String] = []
        for item in items {
            let key = item.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            out.append(item)
        }
        return out
    }
}
