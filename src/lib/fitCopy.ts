import type {
  ComfortFeedback,
  ComfortPreference,
  FitConfidence,
  OutfitRecommendation,
} from "@/types/outfit";
import { getRemoteConfig } from "./remoteConfig";
import type { WeatherData } from "@/types/weather";

export function formatFitTitle(outfit: OutfitRecommendation): string {
  const hasJacket = outfit.items.some((i) => /jacket|coat|bring/i.test(i));
  if (hasJacket || /jacket|coat|bring/i.test(outfit.title)) return outfit.title;
  if (/no jacket/i.test(outfit.title)) return outfit.title;
  return `${outfit.title}, No Jacket`;
}

export function confidenceForFit(
  outfit: OutfitRecommendation,
  weather: WeatherData,
  comfort: ComfortPreference,
): FitConfidence {
  const { thresholds, copy } = getRemoteConfig();
  if (comfort.feedbackCount > 0 || comfort.lastFeedback) {
    return copy.confidence.tunedForYou as FitConfidence;
  }
  if (weather.precipitationChance >= thresholds.highRainChance) {
    return copy.confidence.rainRisk as FitConfidence;
  }
  if (outfit.bringLater) {
    return copy.confidence.eveningDrop as FitConfidence;
  }
  const tip = packTip(outfit, weather);
  if (tip.toLowerCase() !== copy.packTips.travelLight.toLowerCase()) {
    return copy.confidence.bringBackup as FitConfidence;
  }
  return copy.confidence.confident as FitConfidence;
}

export function packTip(outfit: OutfitRecommendation, weather: WeatherData): string {
  const { thresholds, copy } = getRemoteConfig();
  if (outfit.bringLater) {
    const short = outfit.bringLater
      .replace(/^bring\s+/i, "")
      .replace(/\.$/, "")
      .trim();
    return short.charAt(0).toUpperCase() + short.slice(1);
  }
  if (weather.precipitationChance >= thresholds.packRainChance) {
    return copy.packTips.rainLayer;
  }
  if (weather.high - weather.low >= thresholds.diurnalSpanF) {
    return copy.packTips.lightLayer;
  }
  return copy.packTips.travelLight;
}

export function packLaneItems(
  outfit: OutfitRecommendation,
  weather: WeatherData,
): string[] {
  const { thresholds, copy } = getRemoteConfig();
  const items: string[] = [];

  if (outfit.bringLater) {
    const short = outfit.bringLater
      .replace(/^bring\s+(a\s+)?/i, "")
      .replace(/\.$/, "")
      .trim();
    items.push(short.charAt(0).toUpperCase() + short.slice(1));
  }

  if (weather.precipitationChance >= thresholds.packRainChance) {
    if (!items.some((i) => /rain/i.test(i))) items.push("Rain shell");
  }

  if (
    weather.high - weather.low >= thresholds.diurnalSpanF &&
    !items.some((i) => /layer|jacket/i.test(i))
  ) {
    items.push(copy.packTips.lightLayer);
  }

  return items;
}

export function shortExplanation(outfit: OutfitRecommendation): string {
  const first = outfit.explanation.split(".")[0]?.trim();
  if (!first) return outfit.explanation;
  return first.endsWith(".") ? first : `${first}.`;
}

export function whyDetail(
  weather: WeatherData,
  outfit: OutfitRecommendation,
): string {
  if (outfit.whyDetail) return outfit.whyDetail;

  const t = getRemoteConfig().thresholds;
  const parts: string[] = [`Feels like ${weather.feelsLike}°`];

  if (weather.humidity >= t.highHumidity) {
    parts.push(`humidity is high (${weather.humidity}%)`);
  } else if (weather.humidity <= t.lowHumidity) {
    parts.push(`humidity is low (${weather.humidity}%)`);
  } else {
    parts.push(`humidity is moderate (${weather.humidity}%)`);
  }

  if (weather.windSpeed >= t.strongWindMph) {
    parts.push(`wind is strong (${weather.windSpeed} mph)`);
  } else if (weather.windSpeed >= 8) {
    parts.push(`wind is breezy (${weather.windSpeed} mph)`);
  } else {
    parts.push(`wind is mild (${weather.windSpeed} mph)`);
  }

  if (weather.precipitationChance >= t.highRainChance) {
    parts.push(`rain chance is ${weather.precipitationChance}%`);
  }

  if (weather.hourly.length) {
    const coldest = Math.min(...weather.hourly.map((h) => h.feelsLike));
    const drop = Math.max(0, weather.feelsLike - coldest);
    parts.push(
      drop >= t.significantDropF
        ? `evening drops about ${drop}°`
        : `evening only drops ${drop}°`,
    );
  }

  return `${parts.join(", ")}.`;
}

export function feedbackResponse(feedback: ComfortFeedback): string {
  const { feedback: copy } = getRemoteConfig().copy;
  if (feedback === "too_cold") return copy.too_cold;
  if (feedback === "too_hot") return copy.too_hot;
  return copy.perfect;
}

export function updatedLabel(fetchedAt: string): string {
  const date = new Date(fetchedAt);
  if (Number.isNaN(date.getTime())) return "Updated just now";
  return `Updated ${date.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}`;
}

export function isWeatherStale(fetchedAt: string): boolean {
  const date = new Date(fetchedAt);
  if (Number.isNaN(date.getTime())) return true;
  const minutes = getRemoteConfig().timing.weatherStaleMinutes;
  return Date.now() - date.getTime() > minutes * 60 * 1000;
}
