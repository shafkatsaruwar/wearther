export type ClothingCategory =
  | "Linen"
  | "Short sleeve"
  | "Long sleeve"
  | "Sweater"
  | "Light jacket"
  | "Heavy jacket / coat"
  | "Shorts"
  | "Pants"
  | "Rain jacket"
  | "Scarf"
  | "Gloves"
  | "Sneakers"
  | "Bring a jacket";

export interface OutfitRecommendation {
  title: string;
  items: string[];
  explanation: string;
  warmthLevel: number;
  bringLater?: string;
  whyDetail?: string;
}

export type ComfortFeedback = "too_cold" | "perfect" | "too_hot";

export type FeelBaseline = "colder" | "average" | "warmer";
export type StyleMode = "casual" | "smart_casual" | "athletic" | "formal";
export type TempUnits = "fahrenheit" | "celsius";

export type FitConfidence =
  | "Confident"
  | "Bring backup"
  | "Rain risk"
  | "Evening drop"
  | "Tuned for you";

export interface AlwaysPackPrefs {
  rainJacket: boolean;
  lightLayer: boolean;
  scarf: boolean;
}

/**
 * Comfort + style preference store.
 * Positive warmthBias = user runs cold (dress warmer).
 * Designed to move to a database later without changing call sites.
 */
export interface ComfortPreference {
  warmthBias: number;
  feedbackCount: number;
  lastFeedback?: ComfortFeedback;
  updatedAt: string;
  feelBaseline: FeelBaseline;
  style: StyleMode;
  alwaysPack: AlwaysPackPrefs;
  units: TempUnits;
}
