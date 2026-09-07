import type { WeatherData } from "@/types/weather";

export interface ClothingInfo {
  name: string;
  subtitle: string;
  whatItIs: string;
  whyToday: string;
}

interface BaseInfo {
  subtitle: string;
  whatItIs: string;
  whyToday: string;
}

function match(key: string): BaseInfo {
  if (key.includes("linen")) {
    return {
      subtitle: "Light breathable fabric",
      whatItIs:
        "A lightweight breathable shirt, usually worn in warm or humid weather.",
      whyToday:
        "Humidity or heat favors breathable fabric over heavier cotton.",
    };
  }
  if (key.includes("oxford")) {
    return {
      subtitle: "Textured button-up",
      whatItIs:
        "A button-up shirt with slightly textured cotton. Dressier than a tee, more casual than a formal dress shirt.",
      whyToday:
        "It gives you light coverage without feeling heavy in mild weather.",
    };
  }
  if (
    key.includes("button-up") ||
    key.includes("button up") ||
    key.includes("casual button")
  ) {
    return {
      subtitle: "Collared shirt",
      whatItIs:
        "A collared shirt you can wear open or buttoned — polished without feeling formal.",
      whyToday:
        "It reads neat in mild weather when a tee feels too casual.",
    };
  }
  if (key.includes("dress shirt")) {
    return {
      subtitle: "Polished collared shirt",
      whatItIs: "A cleaner dress shirt meant for smarter or formal looks.",
      whyToday:
        "It matches today’s formal-leaning recommendation while still layering well.",
    };
  }
  if (
    key.includes("performance") ||
    key.includes("athletic tee") ||
    key.includes("training")
  ) {
    return {
      subtitle: "Breathable athletic top",
      whatItIs:
        "A moisture-wicking athletic top built for movement and sweat.",
      whyToday:
        "It stays comfortable if you’ll be active or the air feels sticky.",
    };
  }
  if (key.includes("short sleeve") || key.includes("short-sleeve")) {
    return {
      subtitle: "Breathable everyday top",
      whatItIs:
        "A short-sleeve top that keeps your arms cool while covering your torso.",
      whyToday:
        "Temperatures are warm enough that full sleeves are optional.",
    };
  }
  if (key.includes("long sleeve") || key.includes("long-sleeve")) {
    return {
      subtitle: "Light arm coverage",
      whatItIs:
        "A lightweight long-sleeve top that covers your arms without bulk.",
      whyToday:
        "Cooler air or breeze makes light arm coverage more comfortable.",
    };
  }
  if (key.includes("tee") || key.includes("t-shirt") || key.includes("t shirt")) {
    return {
      subtitle: "Casual lightweight top",
      whatItIs: "A simple casual top for everyday wear.",
      whyToday:
        "It’s an easy base layer for today’s mild or warm conditions.",
    };
  }
  if (key.includes("hoodie")) {
    return {
      subtitle: "Soft training layer",
      whatItIs:
        "A soft hooded layer that adds warmth for movement or downtime.",
      whyToday: "It bridges cooler air without needing a stiff jacket.",
    };
  }
  if (
    key.includes("sweater") ||
    key.includes("fine knit") ||
    key.includes("fine-knit")
  ) {
    return {
      subtitle: "Warm knit layer",
      whatItIs:
        "A knit layer that traps warmth around your core and arms.",
      whyToday: "The air is cool enough that a tee alone will feel thin.",
    };
  }
  if (key.includes("overshirt") || key.includes("unstructured blazer")) {
    return {
      subtitle: "Light jacket-like shirt",
      whatItIs:
        "A thicker shirt worn open or buttoned over another top, like a very light jacket.",
      whyToday:
        "It adds warmth for cooler air without needing a full jacket.",
    };
  }
  if (key.includes("blazer")) {
    return {
      subtitle: "Tailored light jacket",
      whatItIs:
        "A structured jacket that sharpens an outfit without heavy winter warmth.",
      whyToday: "It finishes a smarter look while covering mild chill.",
    };
  }
  if (
    key.includes("rain") ||
    key.includes("waterproof") ||
    key.includes("shell")
  ) {
    return {
      subtitle: "Thin waterproof layer",
      whatItIs:
        "A thin waterproof jacket that blocks rain without adding much warmth.",
      whyToday:
        "Rain chances are high enough that waterproof coverage is worth carrying.",
    };
  }
  if (
    key.includes("coat") ||
    key.includes("heavy") ||
    key.includes("overcoat") ||
    key.includes("insulated")
  ) {
    return {
      subtitle: "Warm outer layer",
      whatItIs: "A heavier outer layer meant for cold air and wind.",
      whyToday:
        "Temperatures are low enough that a light jacket won’t be enough.",
    };
  }
  if (
    key.includes("light jacket") ||
    key.includes("running jacket") ||
    key.includes("jacket")
  ) {
    return {
      subtitle: "Light outer layer",
      whatItIs:
        "A light jacket that blocks breeze and adds a little warmth.",
      whyToday:
        "Wind or cooler feels-like temps make a thin outer layer useful.",
    };
  }
  if (key.includes("scarf")) {
    return {
      subtitle: "Warm neck layer",
      whatItIs:
        "A soft neck layer that adds warmth without changing your whole outfit.",
      whyToday:
        "Wind or colder air can make your neck and face feel colder.",
    };
  }
  if (key.includes("glove")) {
    return {
      subtitle: "Hand warmth",
      whatItIs: "A small layer that keeps your hands warm in cold air.",
      whyToday:
        "Cold temperatures make uncovered hands uncomfortable quickly.",
    };
  }
  if (key.includes("chino")) {
    return {
      subtitle: "Clean casual pants",
      whatItIs:
        "Clean casual pants, usually lighter and dressier than jeans.",
      whyToday:
        "They work well when the weather is mild and you do not need heavy layers.",
    };
  }
  if (key.includes("trouser") || key.includes("dress pant")) {
    return {
      subtitle: "Dressier pants",
      whatItIs: "Neater pants meant for smarter or formal outfits.",
      whyToday: "They match today’s polished recommendation.",
    };
  }
  if (key.includes("jean")) {
    return {
      subtitle: "Everyday sturdy pants",
      whatItIs: "Sturdy everyday pants that work for most mild conditions.",
      whyToday:
        "Temperatures are comfortable enough for a standard pant layer.",
    };
  }
  if (key.includes("jogger")) {
    return {
      subtitle: "Soft athletic pants",
      whatItIs: "Relaxed athletic pants built for movement and comfort.",
      whyToday: "They fit an active look without needing dressier bottoms.",
    };
  }
  if (
    key.includes("short") &&
    !key.includes("short sleeve") &&
    !key.includes("short-sleeve")
  ) {
    return {
      subtitle: "Warm-weather bottoms",
      whatItIs: "Shorts that keep your legs cool when the air is warm.",
      whyToday: "It’s warm enough that full-length pants will feel heavy.",
    };
  }
  if (key.includes("pant")) {
    return {
      subtitle: "Everyday pants",
      whatItIs: "Standard pants for cooler or mild weather.",
      whyToday:
        "The temperature sits in a range where covered legs feel better.",
    };
  }
  if (key.includes("sneaker") || key.includes("running shoe")) {
    return {
      subtitle: "Everyday walking shoes",
      whatItIs: "Comfortable everyday shoes for walking.",
      whyToday:
        "Dry or mild conditions do not require boots or waterproof shoes.",
    };
  }
  if (key.includes("loafer") || key.includes("leather shoe")) {
    return {
      subtitle: "Clean closed shoes",
      whatItIs: "Neater closed shoes that finish a smarter outfit.",
      whyToday: "They match today’s polished look in dry conditions.",
    };
  }
  if (key.includes("boot")) {
    return {
      subtitle: "Sturdy covered shoes",
      whatItIs: "Sturdier shoes that cover more of the foot and ankle.",
      whyToday:
        "Colder or wetter conditions favor more coverage than open sneakers.",
    };
  }
  if (key.includes("closed shoe") || key.includes("shoe")) {
    return {
      subtitle: "Covered everyday shoes",
      whatItIs: "Closed shoes that protect your feet in cooler weather.",
      whyToday:
        "The air is cool enough that open or very light shoes feel thin.",
    };
  }
  if (key.includes("base layer")) {
    return {
      subtitle: "Warm under layer",
      whatItIs: "A thin warm layer worn under other clothes.",
      whyToday: "Cold conditions need insulation closest to the skin.",
    };
  }

  return {
    subtitle: "Recommended layer",
    whatItIs: "A suggested clothing item for today’s conditions.",
    whyToday:
      "It fits the current temperature, wind, rain, and comfort preferences.",
  };
}

function whyTodayFor(
  key: string,
  weather: WeatherData | undefined,
  fallback: string,
): string {
  if (!weather) return fallback;

  if (key.includes("linen")) {
    if (weather.humidity >= 70) {
      return "Humidity is high, so breathable fabric will feel better than heavier cotton.";
    }
    if (weather.feelsLike >= 76) {
      return "It’s warm out — light fabric will keep you cooler.";
    }
  }
  if (
    key.includes("rain") ||
    key.includes("waterproof") ||
    key.includes("shell")
  ) {
    if (weather.precipitationChance >= 40) {
      return "Rain chances are high enough that waterproof coverage is worth carrying.";
    }
  }
  if (key.includes("scarf") && weather.windSpeed >= 12) {
    return "Wind can make your neck and face feel colder than the thermometer suggests.";
  }
  if (
    (key.includes("sneaker") || key.includes("running shoe")) &&
    weather.precipitationChance < 40
  ) {
    return "Dry or mild conditions do not require boots or waterproof shoes.";
  }
  if (
    (key.includes("overshirt") ||
      key.includes("light jacket") ||
      key.includes("jacket")) &&
    !key.includes("rain") &&
    !key.includes("heavy") &&
    !key.includes("coat") &&
    (weather.windSpeed >= 10 || weather.feelsLike <= 68)
  ) {
    return "It adds warmth for cooler or breezy air without needing a full coat.";
  }
  if (
    (key.includes("chino") || key.includes("jean") || key.includes("pant")) &&
    weather.feelsLike >= 55 &&
    weather.feelsLike <= 75
  ) {
    return "They work well when the weather is mild and you do not need heavy layers.";
  }
  return fallback;
}

/** Plain-English clothing explanations for Today’s Fit item tiles. */
export function getClothingInfo(
  item: string,
  weather?: WeatherData,
): ClothingInfo {
  const key = item.toLowerCase();
  const base = match(key);
  return {
    name: item,
    subtitle: base.subtitle,
    whatItIs: base.whatItIs,
    whyToday: whyTodayFor(key, weather, base.whyToday),
  };
}
