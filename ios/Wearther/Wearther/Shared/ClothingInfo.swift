import Foundation

struct ClothingInfo: Equatable, Identifiable {
    var id: String { name }
    let name: String
    let subtitle: String
    let whatItIs: String
    let whyToday: String
}

enum ClothingInfoProvider {
    static func info(for item: String, weather: WeatherData? = nil) -> ClothingInfo {
        let key = item.lowercased()
        let base = match(key)
        return ClothingInfo(
            name: item,
            subtitle: base.subtitle,
            whatItIs: base.whatItIs,
            whyToday: whyToday(for: key, weather: weather, fallback: base.whyToday)
        )
    }

    private struct Base {
        let subtitle: String
        let whatItIs: String
        let whyToday: String
    }

    private static func match(_ key: String) -> Base {
        if key.contains("linen") {
            return Base(
                subtitle: "Light breathable fabric",
                whatItIs: "A lightweight breathable shirt, usually worn in warm or humid weather.",
                whyToday: "Humidity or heat favors breathable fabric over heavier cotton."
            )
        }
        if key.contains("oxford") {
            return Base(
                subtitle: "Textured button-up",
                whatItIs: "A button-up shirt with slightly textured cotton. Dressier than a tee, more casual than a formal dress shirt.",
                whyToday: "It gives you light coverage without feeling heavy in mild weather."
            )
        }
        if key.contains("button-up") || key.contains("button up") || key.contains("casual button") {
            return Base(
                subtitle: "Collared shirt",
                whatItIs: "A collared shirt you can wear open or buttoned — polished without feeling formal.",
                whyToday: "It reads neat in mild weather when a tee feels too casual."
            )
        }
        if key.contains("dress shirt") {
            return Base(
                subtitle: "Polished collared shirt",
                whatItIs: "A cleaner dress shirt meant for smarter or formal looks.",
                whyToday: "It matches today’s formal-leaning recommendation while still layering well."
            )
        }
        if key.contains("performance") || key.contains("athletic tee") || key.contains("training") {
            return Base(
                subtitle: "Breathable athletic top",
                whatItIs: "A moisture-wicking athletic top built for movement and sweat.",
                whyToday: "It stays comfortable if you’ll be active or the air feels sticky."
            )
        }
        if key.contains("short sleeve") || key.contains("short-sleeve") {
            return Base(
                subtitle: "Breathable everyday top",
                whatItIs: "A short-sleeve top that keeps your arms cool while covering your torso.",
                whyToday: "Temperatures are warm enough that full sleeves are optional."
            )
        }
        if key.contains("long sleeve") || key.contains("long-sleeve") {
            return Base(
                subtitle: "Light arm coverage",
                whatItIs: "A lightweight long-sleeve top that covers your arms without bulk.",
                whyToday: "Cooler air or breeze makes light arm coverage more comfortable."
            )
        }
        if key.contains("tee") || key.contains("t-shirt") || key.contains("t shirt") {
            return Base(
                subtitle: "Casual lightweight top",
                whatItIs: "A simple casual top for everyday wear.",
                whyToday: "It’s an easy base layer for today’s mild or warm conditions."
            )
        }
        if key.contains("hoodie") {
            return Base(
                subtitle: "Soft training layer",
                whatItIs: "A soft hooded layer that adds warmth for movement or downtime.",
                whyToday: "It bridges cooler air without needing a stiff jacket."
            )
        }
        if key.contains("sweater") || key.contains("fine knit") || key.contains("fine-knit") {
            return Base(
                subtitle: "Warm knit layer",
                whatItIs: "A knit layer that traps warmth around your core and arms.",
                whyToday: "The air is cool enough that a tee alone will feel thin."
            )
        }
        if key.contains("overshirt") || key.contains("unstructured blazer") {
            return Base(
                subtitle: "Light jacket-like shirt",
                whatItIs: "A thicker shirt worn open or buttoned over another top, like a very light jacket.",
                whyToday: "It adds warmth for cooler air without needing a full jacket."
            )
        }
        if key.contains("blazer") {
            return Base(
                subtitle: "Tailored light jacket",
                whatItIs: "A structured jacket that sharpens an outfit without heavy winter warmth.",
                whyToday: "It finishes a smarter look while covering mild chill."
            )
        }
        if key.contains("rain") || key.contains("waterproof") || key.contains("shell") {
            return Base(
                subtitle: "Thin waterproof layer",
                whatItIs: "A thin waterproof jacket that blocks rain without adding much warmth.",
                whyToday: "Rain chances are high enough that waterproof coverage is worth carrying."
            )
        }
        if key.contains("coat") || key.contains("heavy") || key.contains("overcoat") || key.contains("insulated") {
            return Base(
                subtitle: "Warm outer layer",
                whatItIs: "A heavier outer layer meant for cold air and wind.",
                whyToday: "Temperatures are low enough that a light jacket won’t be enough."
            )
        }
        if key.contains("light jacket") || key.contains("running jacket") || key.contains("jacket") {
            return Base(
                subtitle: "Light outer layer",
                whatItIs: "A light jacket that blocks breeze and adds a little warmth.",
                whyToday: "Wind or cooler feels-like temps make a thin outer layer useful."
            )
        }
        if key.contains("scarf") {
            return Base(
                subtitle: "Warm neck layer",
                whatItIs: "A soft neck layer that adds warmth without changing your whole outfit.",
                whyToday: "Wind or colder air can make your neck and face feel colder."
            )
        }
        if key.contains("glove") {
            return Base(
                subtitle: "Hand warmth",
                whatItIs: "A small layer that keeps your hands warm in cold air.",
                whyToday: "Cold temperatures make uncovered hands uncomfortable quickly."
            )
        }
        if key.contains("chino") {
            return Base(
                subtitle: "Clean casual pants",
                whatItIs: "Clean casual pants, usually lighter and dressier than jeans.",
                whyToday: "They work well when the weather is mild and you do not need heavy layers."
            )
        }
        if key.contains("trouser") || key.contains("dress pant") {
            return Base(
                subtitle: "Dressier pants",
                whatItIs: "Neater pants meant for smarter or formal outfits.",
                whyToday: "They match today’s polished recommendation."
            )
        }
        if key.contains("jean") {
            return Base(
                subtitle: "Everyday sturdy pants",
                whatItIs: "Sturdy everyday pants that work for most mild conditions.",
                whyToday: "Temperatures are comfortable enough for a standard pant layer."
            )
        }
        if key.contains("jogger") {
            return Base(
                subtitle: "Soft athletic pants",
                whatItIs: "Relaxed athletic pants built for movement and comfort.",
                whyToday: "They fit an active look without needing dressier bottoms."
            )
        }
        if key.contains("short") && !key.contains("short sleeve") && !key.contains("short-sleeve") {
            return Base(
                subtitle: "Warm-weather bottoms",
                whatItIs: "Shorts that keep your legs cool when the air is warm.",
                whyToday: "It’s warm enough that full-length pants will feel heavy."
            )
        }
        if key.contains("pant") {
            return Base(
                subtitle: "Everyday pants",
                whatItIs: "Standard pants for cooler or mild weather.",
                whyToday: "The temperature sits in a range where covered legs feel better."
            )
        }
        if key.contains("sneaker") || key.contains("running shoe") {
            return Base(
                subtitle: "Everyday walking shoes",
                whatItIs: "Comfortable everyday shoes for walking.",
                whyToday: "Dry or mild conditions do not require boots or waterproof shoes."
            )
        }
        if key.contains("loafer") || key.contains("leather shoe") {
            return Base(
                subtitle: "Clean closed shoes",
                whatItIs: "Neater closed shoes that finish a smarter outfit.",
                whyToday: "They match today’s polished look in dry conditions."
            )
        }
        if key.contains("boot") {
            return Base(
                subtitle: "Sturdy covered shoes",
                whatItIs: "Sturdier shoes that cover more of the foot and ankle.",
                whyToday: "Colder or wetter conditions favor more coverage than open sneakers."
            )
        }
        if key.contains("closed shoe") || key.contains("shoe") {
            return Base(
                subtitle: "Covered everyday shoes",
                whatItIs: "Closed shoes that protect your feet in cooler weather.",
                whyToday: "The air is cool enough that open or very light shoes feel thin."
            )
        }
        if key.contains("base layer") {
            return Base(
                subtitle: "Warm under layer",
                whatItIs: "A thin warm layer worn under other clothes.",
                whyToday: "Cold conditions need insulation closest to the skin."
            )
        }

        return Base(
            subtitle: "Recommended layer",
            whatItIs: "A suggested clothing item for today’s conditions.",
            whyToday: "It fits the current temperature, wind, rain, and comfort preferences."
        )
    }

    private static func whyToday(for key: String, weather: WeatherData?, fallback: String) -> String {
        guard let weather else { return fallback }

        if key.contains("linen") {
            if weather.humidity >= 70 {
                return "Humidity is high, so breathable fabric will feel better than heavier cotton."
            }
            if weather.feelsLike >= 76 {
                return "It’s warm out — light fabric will keep you cooler."
            }
        }
        if key.contains("rain") || key.contains("waterproof") || key.contains("shell") {
            if weather.precipitationChance >= 40 {
                return "Rain chances are high enough that waterproof coverage is worth carrying."
            }
        }
        if key.contains("scarf") {
            if weather.windSpeed >= 12 {
                return "Wind can make your neck and face feel colder than the thermometer suggests."
            }
        }
        if key.contains("sneaker") || key.contains("running shoe") {
            if weather.precipitationChance < 40 {
                return "Dry or mild conditions do not require boots or waterproof shoes."
            }
        }
        if key.contains("overshirt") || key.contains("light jacket") || key.contains("jacket"),
           !key.contains("rain"), !key.contains("heavy"), !key.contains("coat") {
            if weather.windSpeed >= 10 || weather.feelsLike <= 68 {
                return "It adds warmth for cooler or breezy air without needing a full coat."
            }
        }
        if key.contains("chino") || key.contains("jean") || key.contains("pant") {
            if weather.feelsLike >= 55 && weather.feelsLike <= 75 {
                return "They work well when the weather is mild and you do not need heavy layers."
            }
        }
        return fallback
    }
}
