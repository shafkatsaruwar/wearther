import { effectiveWarmthBias } from "@/lib/comfort";
import {
  applyOccasionContext,
  DEFAULT_OCCASION,
} from "@/lib/occasion";
import { getRemoteConfig } from "./remoteConfig";
import type {
  AlwaysPackPrefs,
  ComfortPreference,
  OccasionContext,
  OutfitRecommendation,
  StyleMode,
} from "@/types/outfit";
import type { HourlyWeather, WeatherData } from "@/types/weather";

export interface RecommendInput {
  weather: WeatherData;
  comfort?: ComfortPreference;
  /** Daily occasion — remaps after style. Defaults to everyday. */
  occasion?: OccasionContext;
}

/**
 * Clothing recommendation engine.
 * Pure function — no React, no I/O. Thresholds come from remote config.
 */
export function recommendOutfit({
  weather,
  comfort,
  occasion = DEFAULT_OCCASION,
}: RecommendInput): OutfitRecommendation {
  const t = getRemoteConfig().thresholds;
  const bias = comfort ? effectiveWarmthBias(comfort) : 0;
  const style: StyleMode = comfort?.style ?? "casual";
  const alwaysPack = comfort?.alwaysPack;
  const adjustedFeels = weather.feelsLike + bias;

  const windy = weather.windSpeed >= t.strongWindMph;
  const rainy = weather.precipitationChance >= t.highRainChance;
  const humid = weather.humidity >= t.highHumidity;

  let effective = adjustedFeels;
  if (windy && adjustedFeels < t.windChillBelowF) {
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

  if (windy && effective >= t.windJacketMinF && effective <= t.windJacketMaxF) {
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
    } else if (!/bring/i.test(title) && later.drop >= t.significantDropF) {
      title = joinTitle(stripBring(title), "Bring a Jacket");
    }
    reasons.push(later.message);
  }

  if (humid && weather.feelsLike >= t.humidHotFeelsF) {
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

  ({ items, title, bringLater } = applyOccasionContext({
    occasion,
    items,
    title,
    bringLater,
    weather,
    reasons,
  }));

  const explanation = craftExplanation(reasons, weather, windy, rainy);
  const why = whyDetailText(weather, windy, rainy, later);

  return {
    title,
    items: dedupe(items),
    explanation,
    warmthLevel,
    bringLater,
    whyDetail: why,
  };
}

/** Snapshot recommendation for a single hourly slot (Later Today). */
export function recommendForHour(
  hour: HourlyWeather,
  comfort?: ComfortPreference,
): string {
  const bands = getRemoteConfig().thresholds.tempBandsF;
  const rainCut = getRemoteConfig().thresholds.highRainChance;
  const bias = comfort ? effectiveWarmthBias(comfort) : 0;
  const temp = hour.feelsLike + bias;
  const rainy = hour.precipitationChance >= rainCut;
  const tip = (() => {
    if (temp >= bands[0]) return rainy ? "Linen + rain layer" : "Linen / shorts";
    if (temp >= bands[1]) return rainy ? "Short sleeve + rain jacket" : "Short sleeve";
    if (temp >= bands[2]) return rainy ? "Light layers + rain jacket" : "Jacket optional";
    if (temp >= bands[3]) return "Long sleeve";
    if (temp >= bands[4]) return "Long sleeve + light jacket";
    if (temp >= bands[5]) return "Sweater + jacket";
    if (temp >= bands[6]) return "Sweater + coat";
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
  const [b0, b1, b2, b3, b4, b5, b6] = getRemoteConfig().thresholds.tempBandsF;

  if (temp >= b0) {
    return {
      title: humid ? "Linen + Shorts" : "Linen or Short Sleeve + Shorts",
      items: humid
        ? ["Linen shirt", "Shorts", "Sneakers"]
        : ["Linen or lightweight short sleeve", "Shorts", "Sneakers"],
      warmthLevel: 1,
      reason: "It's hot out — keep it light and breathable.",
    };
  }

  if (temp >= b1) {
    return {
      title: humid ? "Linen" : "Short Sleeve or Linen",
      items: humid
        ? ["Linen shirt", "Shorts or light pants", "Sneakers"]
        : ["Short sleeve or linen", "Shorts or light pants", "Sneakers"],
      warmthLevel: 2,
      reason: "Warm weather calls for light, easy layers.",
    };
  }

  if (temp >= b2) {
    return {
      title: "Short Sleeve or Thin Long Sleeve",
      items: ["Short sleeve or thin long sleeve", "Pants or chinos", "Sneakers"],
      warmthLevel: 3,
      reason: "Mild and comfortable — a thin top should be enough.",
    };
  }

  if (temp >= b3) {
    return {
      title: "Long Sleeve",
      items: ["Long sleeve shirt", "Jeans or chinos", "Sneakers"],
      warmthLevel: 4,
      reason: "Cool enough for long sleeves without a jacket.",
    };
  }

  if (temp >= b4) {
    return {
      title: "Long Sleeve + Light Jacket",
      items: ["Long sleeve shirt", "Light jacket", "Jeans or chinos", "Sneakers"],
      warmthLevel: 5,
      reason: "A light jacket should keep you comfortable.",
    };
  }

  if (temp >= b5) {
    return {
      title: "Sweater + Jacket",
      items: ["Sweater", "Light jacket", "Pants", "Sneakers"],
      warmthLevel: 6,
      reason: "Chilly air — sweater plus a jacket works well.",
    };
  }

  if (temp >= b6) {
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

  const dropCut = getRemoteConfig().thresholds.significantDropF;
  const mildBand = getRemoteConfig().thresholds.tempBandsF[2] ?? 68;

  if (drop < dropCut) return undefined;
  if (coldest >= mildBand) return undefined;

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

function whyDetailText(
  weather: WeatherData,
  windy: boolean,
  rainy: boolean,
  later: { drop: number; message: string; short: string } | undefined,
): string {
  const parts: string[] = [`Feels like ${weather.feelsLike}°`];

  if (weather.humidity >= 70) {
    parts.push(`humidity is high (${weather.humidity}%)`);
  } else if (weather.humidity <= 35) {
    parts.push(`humidity is low (${weather.humidity}%)`);
  } else {
    parts.push(`humidity is moderate (${weather.humidity}%)`);
  }

  parts.push(
    windy
      ? `wind is breezy (${weather.windSpeed} mph)`
      : `wind is mild (${weather.windSpeed} mph)`,
  );

  if (rainy) {
    parts.push(`rain chance is ${weather.precipitationChance}%`);
  }

  if (later) {
    parts.push(`evening drops about ${later.drop}°`);
  } else if (weather.hourly.length) {
    const coldest = Math.min(...weather.hourly.map((h) => h.feelsLike));
    const drop = Math.max(0, weather.feelsLike - coldest);
    parts.push(`evening only drops ${drop}°`);
  }

  return `${parts.join(", ")}.`;
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
