import type {
  AlwaysPackPrefs,
  ComfortFeedback,
  ComfortPreference,
  FeelBaseline,
  StyleMode,
  TempUnits,
} from "@/types/outfit";

const STORAGE_KEY = "wearther:comfort-preference";

export const DEFAULT_ALWAYS_PACK: AlwaysPackPrefs = {
  rainJacket: false,
  lightLayer: false,
  scarf: false,
};

export const DEFAULT_COMFORT: ComfortPreference = {
  warmthBias: 0,
  feedbackCount: 0,
  updatedAt: new Date(0).toISOString(),
  feelBaseline: "average",
  style: "casual",
  alwaysPack: { ...DEFAULT_ALWAYS_PACK },
  units: "fahrenheit",
};

export function baselineOffset(baseline: FeelBaseline): number {
  if (baseline === "colder") return 4;
  if (baseline === "warmer") return -4;
  return 0;
}

/** Combined bias from baseline preference + session feedback. */
export function effectiveWarmthBias(pref: ComfortPreference): number {
  return clamp(baselineOffset(pref.feelBaseline) + pref.warmthBias, -8, 8);
}

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
    const parsed = JSON.parse(raw) as Partial<ComfortPreference>;
    return normalizePreference(parsed);
  } catch {
    return DEFAULT_COMFORT;
  }
}

export function saveComfortPreference(pref: ComfortPreference): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(pref));
}

export function updateComfortPreference(
  current: ComfortPreference,
  patch: Partial<
    Pick<ComfortPreference, "feelBaseline" | "style" | "units">
  > & {
    alwaysPack?: Partial<AlwaysPackPrefs>;
  },
): ComfortPreference {
  const next: ComfortPreference = {
    ...current,
    ...patch,
    alwaysPack: {
      ...current.alwaysPack,
      ...(patch.alwaysPack ?? {}),
    },
    updatedAt: new Date().toISOString(),
  };
  saveComfortPreference(next);
  return next;
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
    if (bias > 0) bias = Math.max(0, bias - 0.5);
    if (bias < 0) bias = Math.min(0, bias + 0.5);
  }

  const next: ComfortPreference = {
    ...current,
    warmthBias: bias,
    feedbackCount: current.feedbackCount + 1,
    lastFeedback: feedback,
    updatedAt: new Date().toISOString(),
  };

  saveComfortPreference(next);
  return next;
}

export function normalizePreference(
  parsed: Partial<ComfortPreference>,
): ComfortPreference {
  const alwaysPack = {
    ...DEFAULT_ALWAYS_PACK,
    ...(parsed.alwaysPack ?? {}),
  };

  return {
    warmthBias: clamp(parsed.warmthBias ?? 0, -8, 8),
    feedbackCount: parsed.feedbackCount ?? 0,
    lastFeedback: parsed.lastFeedback,
    updatedAt: parsed.updatedAt ?? new Date().toISOString(),
    feelBaseline: isFeelBaseline(parsed.feelBaseline)
      ? parsed.feelBaseline
      : "average",
    style: isStyleMode(parsed.style) ? parsed.style : "casual",
    alwaysPack,
    units: isTempUnits(parsed.units) ? parsed.units : "fahrenheit",
  };
}

function isFeelBaseline(v: unknown): v is FeelBaseline {
  return v === "colder" || v === "average" || v === "warmer";
}

function isStyleMode(v: unknown): v is StyleMode {
  return (
    v === "casual" ||
    v === "smart_casual" ||
    v === "athletic" ||
    v === "formal"
  );
}

function isTempUnits(v: unknown): v is TempUnits {
  return v === "fahrenheit" || v === "celsius";
}

function clamp(n: number, min: number, max: number) {
  return Math.min(max, Math.max(min, n));
}
