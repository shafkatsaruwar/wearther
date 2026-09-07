import type {
  ComfortFeedback,
  ComfortPreference,
  FitConfidence,
  OutfitRecommendation,
} from "@/types/outfit";
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
  if (comfort.feedbackCount > 0 || comfort.lastFeedback) return "Tuned for you";
  if (weather.precipitationChance >= 45) return "Rain risk";
  if (outfit.bringLater) return "Evening drop";
  const tip = packTip(outfit, weather);
  if (tip.toLowerCase() !== "travel light") return "Bring backup";
  return "Confident";
}

export function packTip(outfit: OutfitRecommendation, weather: WeatherData): string {
  if (outfit.bringLater) {
    const short = outfit.bringLater
      .replace(/^bring\s+/i, "")
      .replace(/\.$/, "")
      .trim();
    return short.charAt(0).toUpperCase() + short.slice(1);
  }
  if (weather.precipitationChance >= 40) return "Rain layer";
  if (weather.high - weather.low >= 12) return "Light layer";
  return "Travel light";
}

export function packLaneItems(
  outfit: OutfitRecommendation,
  weather: WeatherData,
): string[] {
  const items: string[] = [];

  if (outfit.bringLater) {
    const short = outfit.bringLater
      .replace(/^bring\s+(a\s+)?/i, "")
      .replace(/\.$/, "")
      .trim();
    items.push(short.charAt(0).toUpperCase() + short.slice(1));
  }

  if (weather.precipitationChance >= 40) {
    if (!items.some((i) => /rain/i.test(i))) items.push("Rain shell");
  }

  if (
    weather.high - weather.low >= 12 &&
    !items.some((i) => /layer|jacket/i.test(i))
  ) {
    items.push("Light layer");
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

  const parts: string[] = [`Feels like ${weather.feelsLike}°`];

  if (weather.humidity >= 70) {
    parts.push(`humidity is high (${weather.humidity}%)`);
  } else if (weather.humidity <= 35) {
    parts.push(`humidity is low (${weather.humidity}%)`);
  } else {
    parts.push(`humidity is moderate (${weather.humidity}%)`);
  }

  if (weather.windSpeed >= 12) {
    parts.push(`wind is strong (${weather.windSpeed} mph)`);
  } else if (weather.windSpeed >= 8) {
    parts.push(`wind is breezy (${weather.windSpeed} mph)`);
  } else {
    parts.push(`wind is mild (${weather.windSpeed} mph)`);
  }

  if (weather.precipitationChance >= 45) {
    parts.push(`rain chance is ${weather.precipitationChance}%`);
  }

  if (weather.hourly.length) {
    const coldest = Math.min(...weather.hourly.map((h) => h.feelsLike));
    const drop = Math.max(0, weather.feelsLike - coldest);
    parts.push(
      drop >= 10
        ? `evening drops about ${drop}°`
        : `evening only drops ${drop}°`,
    );
  }

  return `${parts.join(", ")}.`;
}

export function feedbackResponse(feedback: ComfortFeedback): string {
  if (feedback === "too_cold") return "Got it. Tomorrow will lean warmer.";
  if (feedback === "too_hot") return "Got it. Tomorrow will lighten up.";
  return "Nice. Keeping this baseline.";
}

export function updatedLabel(fetchedAt: string): string {
  const date = new Date(fetchedAt);
  if (Number.isNaN(date.getTime())) return "Updated just now";
  return `Updated ${date.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })}`;
}

export function isWeatherStale(fetchedAt: string): boolean {
  const date = new Date(fetchedAt);
  if (Number.isNaN(date.getTime())) return true;
  return Date.now() - date.getTime() > 90 * 60 * 1000;
}
