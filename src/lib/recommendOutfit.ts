import { effectiveWarmthBias } from "@/lib/comfort";
import type {
  AlwaysPackPrefs,
  ComfortPreference,
  OutfitRecommendation,
  StyleMode,
} from "@/types/outfit";
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
  const bias = comfort ? effectiveWarmthBias(comfort) : 0;
  const style: StyleMode = comfort?.style ?? "casual";
  const alwaysPack = comfort?.alwaysPack;
  const adjustedFeels = weather.feelsLike + bias;

  const windy = weather.windSpeed >= STRONG_WIND_MPH;
  const rainy = weather.precipitationChance >= HIGH_RAIN_CHANCE;
  const humid = weather.humidity >= HIGH_HUMIDITY;

  let effective = adjustedFeels;
  if (windy && adjustedFeels < 75) {
    effective -= Math.min(6, Math.round(weather.windSpeed / 4));
  }

  const base = baseLayerForTemp(effective, humid);
  const later = laterDropAdvice(weather, effective);

  let items = [...base.items];
  let title = base.title;
  let warmthLevel = base.warmthLevel;
  const reasons: string[] = [base.reason];
  let bringLater = later?.short;

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

  ({ items, title, bringLater } = applyAlwaysPack({
    items,
    title,
    bringLater,
    alwaysPack,
    reasons,
  }));

  ({ items, title } = applyStyle(style, items, title));

  if (style !== "casual") {
    reasons.push(`Styled for a ${styleLabel(style)} look.`);
  }

  const explanation = craftExplanation(reasons, weather, windy, rainy);

  return {
    title,
    items: dedupe(items),
    explanation,
    warmthLevel,
    bringLater,
  };
}

/** Snapshot recommendation for a single hourly slot (Later Today). */
export function recommendForHour(
  hour: HourlyWeather,
  comfort?: ComfortPreference,
): string {
  const bias = comfort ? effectiveWarmthBias(comfort) : 0;
  const t = hour.feelsLike + bias;
  const rainy = hour.precipitationChance >= HIGH_RAIN_CHANCE;
  const tip = (() => {
    if (t >= 85) return rainy ? "Linen + rain layer" : "Linen / shorts";
    if (t >= 76) return rainy ? "Short sleeve + rain jacket" : "Short sleeve";
    if (t >= 68) return rainy ? "Light layers + rain jacket" : "Jacket optional";
    if (t >= 60) return "Long sleeve";
    if (t >= 52) return "Long sleeve + light jacket";
    if (t >= 42) return "Sweater + jacket";
    if (t >= 32) return "Sweater + coat";
    return "Heavy coat + layers";
  })();

  return styleHourTip(comfort?.style ?? "casual", tip);
}

function applyAlwaysPack({
  items,
  title,
  bringLater,
  alwaysPack,
  reasons,
}: {
  items: string[];
  title: string;
  bringLater?: string;
  alwaysPack?: AlwaysPackPrefs;
  reasons: string[];
}): { items: string[]; title: string; bringLater?: string } {
  if (!alwaysPack) return { items, title, bringLater };

  const nextItems = [...items];
  let nextTitle = title;
  let nextBring = bringLater;

  if (
    alwaysPack.rainJacket &&
    !nextItems.some((i) => /rain|waterproof/i.test(i))
  ) {
    nextItems.push("Rain jacket");
    reasons.push("You asked to always pack a rain jacket.");
  }

  if (alwaysPack.lightLayer) {
    nextBring = nextBring ?? "Bring a light layer for later.";
    if (!/bring/i.test(nextTitle)) {
      nextTitle = joinTitle(stripBring(nextTitle), "Bring a Jacket");
    }
    reasons.push("Keeping a light layer handy, as you prefer.");
  }

  if (alwaysPack.scarf && !nextItems.some((i) => /scarf/i.test(i))) {
    nextItems.push("Scarf");
    reasons.push("You asked to always pack a scarf.");
  }

  return { items: nextItems, title: nextTitle, bringLater: nextBring };
}

function applyStyle(
  style: StyleMode,
  items: string[],
  title: string,
): { items: string[]; title: string } {
  if (style === "casual") return { items, title };

  const mappedItems = items.map((item) => styleItem(style, item));
  const mappedTitle = styleTitle(style, title);
  return { items: mappedItems, title: mappedTitle };
}

function styleItem(style: StyleMode, item: string): string {
  const lower = item.toLowerCase();

  if (style === "smart_casual") {
    if (lower.includes("linen") && lower.includes("shirt")) return "Linen button-up";
    if (lower.includes("short sleeve") || lower.includes("lightweight short"))
      return "Casual button-up";
    if (lower.includes("long sleeve")) return "Oxford shirt";
    if (lower.includes("shorts") && !lower.includes("pants")) return "Chinos or tailored shorts";
    if (lower.includes("jeans") || lower.includes("pants") || lower.includes("chinos"))
      return "Chinos";
    if (lower.includes("sneaker")) return "Clean sneakers or loafers";
    if (lower.includes("light jacket")) return "Unstructured blazer or overshirt";
    return item;
  }

  if (style === "athletic") {
    if (lower.includes("linen") || lower.includes("short sleeve") || lower.includes("lightweight short"))
      return "Breathable athletic tee";
    if (lower.includes("long sleeve")) return "Performance long sleeve";
    if (lower.includes("sweater")) return "Light training hoodie";
    if (lower.includes("shorts")) return "Athletic shorts";
    if (lower.includes("pants") || lower.includes("jeans") || lower.includes("chinos"))
      return "Joggers";
    if (lower.includes("sneaker") || lower.includes("shoe")) return "Running shoes";
    if (lower.includes("light jacket") || lower.includes("rain"))
      return lower.includes("rain") ? "Packable rain shell" : "Lightweight running jacket";
    if (lower.includes("coat") || lower.includes("heavy")) return "Insulated training jacket";
    return item;
  }

  // formal
  if (lower.includes("linen")) return "Dress shirt (light fabric)";
  if (lower.includes("short sleeve") || lower.includes("lightweight short"))
    return "Short-sleeve dress shirt";
  if (lower.includes("long sleeve") || lower.includes("oxford")) return "Dress shirt";
  if (lower.includes("sweater")) return "Fine-knit sweater";
  if (lower.includes("shorts")) return "Dress trousers";
  if (lower.includes("pants") || lower.includes("jeans") || lower.includes("chinos"))
    return "Dress trousers";
  if (lower.includes("sneaker") || lower.includes("shoe")) return "Leather shoes";
  if (lower.includes("light jacket")) return "Blazer";
  if (lower.includes("rain")) return "Tailored raincoat";
  if (lower.includes("coat") || lower.includes("heavy")) return "Wool overcoat";
  return item;
}

function styleTitle(style: StyleMode, title: string): string {
  if (style === "smart_casual") {
    return title
      .replace(/Short Sleeve or Linen/gi, "Button-up")
      .replace(/Short Sleeve or Thin Long Sleeve/gi, "Button-up or knit")
      .replace(/Linen \+ Shorts/gi, "Linen button-up + chinos")
      .replace(/Linen or Short Sleeve \+ Shorts/gi, "Button-up + chinos")
      .replace(/\bLinen\b/gi, "Linen button-up")
      .replace(/Long Sleeve/gi, "Oxford")
      .replace(/Light Jacket/gi, "Overshirt");
  }
  if (style === "athletic") {
    return title
      .replace(/Short Sleeve or Linen/gi, "Athletic tee")
      .replace(/Short Sleeve or Thin Long Sleeve/gi, "Performance tee")
      .replace(/Linen \+ Shorts/gi, "Tee + athletic shorts")
      .replace(/Linen or Short Sleeve \+ Shorts/gi, "Tee + athletic shorts")
      .replace(/\bLinen\b/gi, "Athletic tee")
      .replace(/Long Sleeve/gi, "Performance top")
      .replace(/Light Jacket/gi, "Running jacket")
      .replace(/Sweater/gi, "Hoodie")
      .replace(/Heavy Jacket \/ Coat|Heavy Jacket/gi, "Insulated jacket");
  }
  return title
    .replace(/Short Sleeve or Linen/gi, "Dress shirt")
    .replace(/Short Sleeve or Thin Long Sleeve/gi, "Dress shirt")
    .replace(/Linen \+ Shorts/gi, "Dress shirt + trousers")
    .replace(/Linen or Short Sleeve \+ Shorts/gi, "Dress shirt + trousers")
    .replace(/\bLinen\b/gi, "Dress shirt")
    .replace(/Long Sleeve/gi, "Dress shirt")
    .replace(/Light Jacket/gi, "Blazer")
    .replace(/Sweater/gi, "Fine knit")
    .replace(/Heavy Jacket \/ Coat|Heavy Jacket/gi, "Overcoat")
    .replace(/Winter Coat \+ Warm Layers/gi, "Overcoat + layers");
}

function styleHourTip(style: StyleMode, tip: string): string {
  if (style === "casual") return tip;
  if (style === "smart_casual") {
    return tip
      .replace(/Linen/gi, "Button-up")
      .replace(/Short sleeve/gi, "Button-up")
      .replace(/Long sleeve/gi, "Oxford")
      .replace(/shorts/gi, "chinos");
  }
  if (style === "athletic") {
    return tip
      .replace(/Linen/gi, "Athletic tee")
      .replace(/Short sleeve/gi, "Athletic tee")
      .replace(/Long sleeve/gi, "Perf. top")
      .replace(/Jacket optional/gi, "Light shell optional")
      .replace(/light jacket/gi, "running jacket")
      .replace(/Sweater/gi, "Hoodie")
      .replace(/coat/gi, "insulated jacket");
  }
  return tip
    .replace(/Linen/gi, "Dress shirt")
    .replace(/Short sleeve/gi, "Dress shirt")
    .replace(/Long sleeve/gi, "Dress shirt")
    .replace(/Jacket optional/gi, "Blazer optional")
    .replace(/light jacket/gi, "blazer")
    .replace(/Sweater/gi, "Fine knit")
    .replace(/coat/gi, "overcoat");
}

function styleLabel(style: StyleMode): string {
  if (style === "smart_casual") return "smart casual";
  return style;
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
  if (windy && weather.feelsLike < 70 && !rainy) {
    const rest = reasons
      .filter((r) => !/wind/i.test(r))
      .slice(0, 1)
      .join(" ");
    return `It's cool and breezy today. The jacket will help with the wind.${rest ? ` ${rest}` : ""}`.trim();
  }

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
