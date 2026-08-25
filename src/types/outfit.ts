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
}

export type ComfortFeedback = "too_cold" | "perfect" | "too_hot";

/**
 * Comfort bias applied to feels-like temperature (°F).
 * Positive = user runs cold (dress warmer).
 * Negative = user runs hot (dress cooler).
 * Designed to move to a database later without changing call sites.
 */
export interface ComfortPreference {
  warmthBias: number;
  feedbackCount: number;
  lastFeedback?: ComfortFeedback;
  updatedAt: string;
}
