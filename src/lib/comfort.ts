import type { ComfortFeedback, ComfortPreference } from "@/types/outfit";

const STORAGE_KEY = "wearther:comfort-preference";

export const DEFAULT_COMFORT: ComfortPreference = {
  warmthBias: 0,
  feedbackCount: 0,
  updatedAt: new Date(0).toISOString(),
};

/**
 * Local comfort preference store.
 * Swap the storage adapter later for a database-backed user profile
 * without changing recommendOutfit callers.
 */
export function loadComfortPreference(): ComfortPreference {
  if (typeof window === "undefined") return DEFAULT_COMFORT;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_COMFORT;
    const parsed = JSON.parse(raw) as ComfortPreference;
    return {
      warmthBias: clamp(parsed.warmthBias ?? 0, -8, 8),
      feedbackCount: parsed.feedbackCount ?? 0,
      lastFeedback: parsed.lastFeedback,
      updatedAt: parsed.updatedAt ?? new Date().toISOString(),
    };
  } catch {
    return DEFAULT_COMFORT;
  }
}

export function saveComfortPreference(pref: ComfortPreference): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(pref));
}

/**
 * Apply outfit feedback to the comfort score.
 * too_cold → dress warmer next time (+bias)
 * too_hot  → dress cooler next time (−bias)
 * perfect  → gently decay bias toward 0 (reinforce current)
 */
export function applyComfortFeedback(
  current: ComfortPreference,
  feedback: ComfortFeedback,
): ComfortPreference {
  let bias = current.warmthBias;

  if (feedback === "too_cold") {
    bias = clamp(bias + 2, -8, 8);
  } else if (feedback === "too_hot") {
    bias = clamp(bias - 2, -8, 8);
  } else {
    // Perfect: nudge bias slightly toward zero
    if (bias > 0) bias = Math.max(0, bias - 0.5);
    if (bias < 0) bias = Math.min(0, bias + 0.5);
  }

  const next: ComfortPreference = {
    warmthBias: bias,
    feedbackCount: current.feedbackCount + 1,
    lastFeedback: feedback,
    updatedAt: new Date().toISOString(),
  };

  saveComfortPreference(next);
  return next;
}

function clamp(n: number, min: number, max: number) {
  return Math.min(max, Math.max(min, n));
}
