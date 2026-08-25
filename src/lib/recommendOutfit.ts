import type { ComfortPreference, OutfitRecommendation } from "@/types/outfit";
import type { HourlyWeather, WeatherData } from "@/types/weather";

export interface RecommendInput {
  weather: WeatherData;
  comfort?: ComfortPreference;
}

const STRONG_WIND_MPH = 12;
const HIGH_RAIN_CHANCE = 45;
const HIGH_HUMIDITY = 70;
const SIGNIFICANT_DROP_F = 10;

/**
 * Clothing recommendation engine.
 * Pure function — no React, no I/O. Safe to move server-side later.
 */
export function recommendOutfit({
  weather,
  comfort,
}: RecommendInput): OutfitRecommendation {
  const bias = comfort?.warmthBias ?? 0;
  const adjustedFeels = weather.feelsLike + bias;

  const windy = weather.windSpeed >= STRONG_WIND_MPH;
  const rainy = weather.precipitationChance >= HIGH_RAIN_CHANCE;
  const humid = weather.humidity >= HIGH_HUMIDITY;

  // Wind makes it feel cooler — bump effective temp down a notch for dressing
  let effective = adjustedFeels;
  if (windy && adjustedFeels < 75) {
    effective -= Math.min(6, Math.round(weather.windSpeed / 4));
  }

  const base = baseLayerForTemp(effective, humid);
  const later = laterDropAdvice(weather, effective);

  const items = [...base.items];
  let title = base.title;
  let warmthLevel = base.warmthLevel;
  const reasons: string[] = [base.reason];

  if (rainy) {
    if (!items.some((i) => /rain|waterproof/i.test(i))) {
      items.push("Rain jacket");
    }
    reasons.push("Rain is likely, so keep a waterproof layer handy.");
    warmthLevel = Math.min(10, warmthLevel + 0.5);
  }

  if (windy && effective >= 52 && effective <= 75) {
    if (!items.some((i) => /jacket|coat|sweater/i.test(i))) {
      items.push("Light jacket");
      title = joinTitle(title, "Light Jacket");
      warmthLevel = Math.min(10, warmthLevel + 1);
    }
    reasons.push("It feels cooler because of the wind.");
  }

  if (later) {
    if (!items.some((i) => /jacket|coat|bring/i.test(i))) {
      // Soften: suggest bringing rather than wearing now
      title = joinTitle(stripBring(title), "Bring a Jacket");
    } else if (!/bring/i.test(title) && later.drop >= SIGNIFICANT_DROP_F) {
      title = joinTitle(stripBring(title), "Bring a Jacket");
    }
    reasons.push(later.message);
  }

  if (humid && weather.feelsLike >= 76) {
    reasons.push("High humidity favors breathable fabrics like linen.");
  }

  if (bias >= 2) {
    reasons.push("Based on your feedback, this leans a bit warmer.");
  } else if (bias <= -2) {
    reasons.push("Based on your feedback, this leans a bit cooler.");
  }

  const explanation = craftExplanation(reasons, weather, windy, rainy);

  return {
    title,
    items: dedupe(items),
    explanation,
    warmthLevel,
    bringLater: later?.short,
  };
}

/** Snapshot recommendation for a single hourly slot (Later Today). */
export function recommendForHour(
  hour: HourlyWeather,
  comfort?: ComfortPreference,
): string {
  const bias = comfort?.warmthBias ?? 0;
  const t = hour.feelsLike + bias;
  const rainy = hour.precipitationChance >= HIGH_RAIN_CHANCE;

  if (t >= 85) return rainy ? "Linen + rain layer" : "Linen / shorts";
  if (t >= 76) return rainy ? "Short sleeve + rain jacket" : "Short sleeve";
  if (t >= 68) return rainy ? "Light layers + rain jacket" : "Jacket optional";
  if (t >= 60) return "Long sleeve";
  if (t >= 52) return "Long sleeve + light jacket";
  if (t >= 42) return "Sweater + jacket";
  if (t >= 32) return "Sweater + coat";
  return "Heavy coat + layers";
}

function baseLayerForTemp(
  temp: number,
  humid: boolean,
): {
  title: string;
  items: string[];
  warmthLevel: number;
  reason: string;
} {
  if (temp >= 85) {
    return {
      title: humid ? "Linen + Shorts" : "Linen or Short Sleeve + Shorts",
      items: humid
        ? ["Linen shirt", "Shorts", "Sneakers"]
        : ["Linen or lightweight short sleeve", "Shorts", "Sneakers"],
      warmthLevel: 1,
      reason: "It's hot out — keep it light and breathable.",
    };
  }

  if (temp >= 76) {
    return {
      title: humid ? "Linen" : "Short Sleeve or Linen",
      items: humid
        ? ["Linen shirt", "Shorts or light pants", "Sneakers"]
        : ["Short sleeve or linen", "Shorts or light pants", "Sneakers"],
      warmthLevel: 2,
      reason: "Warm weather calls for light, easy layers.",
    };
  }

  if (temp >= 68) {
    return {
      title: "Short Sleeve or Thin Long Sleeve",
      items: ["Short sleeve or thin long sleeve", "Pants or chinos", "Sneakers"],
      warmthLevel: 3,
      reason: "Mild and comfortable — a thin top should be enough.",
    };
  }

  if (temp >= 60) {
    return {
      title: "Long Sleeve",
      items: ["Long sleeve shirt", "Jeans or chinos", "Sneakers"],
      warmthLevel: 4,
      reason: "Cool enough for long sleeves without a jacket.",
    };
  }

  if (temp >= 52) {
    return {
      title: "Long Sleeve + Light Jacket",
      items: ["Long sleeve shirt", "Light jacket", "Jeans or chinos", "Sneakers"],
      warmthLevel: 5,
      reason: "A light jacket should keep you comfortable.",
    };
  }

  if (temp >= 42) {
    return {
      title: "Sweater + Jacket",
      items: ["Sweater", "Light jacket", "Pants", "Sneakers"],
      warmthLevel: 6,
      reason: "Chilly air — sweater plus a jacket works well.",
    };
  }

  if (temp >= 32) {
    return {
      title: "Sweater + Heavy Jacket",
      items: ["Sweater", "Heavy jacket / coat", "Pants", "Closed shoes"],
      warmthLevel: 8,
      reason: "Cold enough for a heavy outer layer over a sweater.",
    };
  }

  return {
    title: "Winter Coat + Warm Layers",
    items: [
      "Warm base layer",
      "Sweater",
      "Heavy jacket / coat",
      "Scarf",
      "Gloves",
    ],
    warmthLevel: 10,
    reason: "Freezing conditions — bundle up with coat, scarf, and gloves.",
  };
}

function laterDropAdvice(
  weather: WeatherData,
  currentEffective: number,
): { drop: number; message: string; short: string } | undefined {
  if (!weather.hourly.length) return undefined;

  const eveningTemps = weather.hourly.map((h) => h.feelsLike);
  const coldest = Math.min(...eveningTemps);
  const drop = currentEffective - coldest;

  // Only nudge a jacket when it actually cools into jacket territory.
  if (drop < SIGNIFICANT_DROP_F) return undefined;
  if (coldest >= 68) return undefined;

  return {
    drop: Math.round(drop),
    message: `It drops to about ${coldest}° later — bring a jacket for later.`,
    short: "Bring a jacket for later.",
  };
}

function craftExplanation(
  reasons: string[],
  weather: WeatherData,
  windy: boolean,
  rainy: boolean,
): string {
  // Prefer a natural primary sentence
  if (windy && weather.feelsLike < 70 && !rainy) {
    const rest = reasons
      .filter((r) => !/wind/i.test(r))
      .slice(0, 1)
      .join(" ");
    return `It's cool and breezy today. The jacket will help with the wind.${rest ? ` ${rest}` : ""}`.trim();
  }

  // Deduplicate and keep 1–2 sentences
  const unique = [...new Set(reasons)].slice(0, 2);
  return unique.join(" ");
}

function joinTitle(base: string, addition: string): string {
  if (base.toLowerCase().includes(addition.toLowerCase())) return base;
  return `${base} + ${addition}`;
}

function stripBring(title: string): string {
  return title.replace(/\s*\+\s*Bring a Jacket/i, "").trim();
}

function dedupe(items: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of items) {
    const key = item.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(item);
  }
  return out;
}
