/**
 * Remote config — Expo-style knobs without shipping a new binary.
 *
 * Edit `public/remote-config.json` and deploy / push to main.
 * Clients fetch `/api/config` (web) or WEARTHER_CONFIG_URL (iOS),
 * merge over bundled defaults, and cache locally.
 */

export interface RemoteThresholds {
  strongWindMph: number;
  highRainChance: number;
  packRainChance: number;
  highHumidity: number;
  lowHumidity: number;
  significantDropF: number;
  diurnalSpanF: number;
  windChillBelowF: number;
  windJacketMinF: number;
  windJacketMaxF: number;
  humidHotFeelsF: number;
  /** Descending °F cutoffs: hot → freezing. Length 7. */
  tempBandsF: number[];
}

export interface RemoteTiming {
  weatherStaleMinutes: number;
  widgetRefreshMinutes: number;
  widgetStaleHours: number;
  configCacheMinutes: number;
}

export interface RemoteCopy {
  confidence: {
    confident: string;
    bringBackup: string;
    rainRisk: string;
    eveningDrop: string;
    tunedForYou: string;
  };
  packTips: {
    rainLayer: string;
    lightLayer: string;
    travelLight: string;
  };
  feedback: {
    too_cold: string;
    too_hot: string;
    perfect: string;
  };
  notificationTitle: string;
}

export interface RemoteFlags {
  enableOccasionPicker: boolean;
  enableTripPack: boolean;
  enableMorningNotifications: boolean;
}

export interface RemoteConfig {
  version: number;
  thresholds: RemoteThresholds;
  timing: RemoteTiming;
  copy: RemoteCopy;
  flags: RemoteFlags;
}

export const DEFAULT_REMOTE_CONFIG: RemoteConfig = {
  version: 1,
  thresholds: {
    strongWindMph: 12,
    highRainChance: 45,
    packRainChance: 40,
    highHumidity: 70,
    lowHumidity: 35,
    significantDropF: 10,
    diurnalSpanF: 12,
    windChillBelowF: 75,
    windJacketMinF: 52,
    windJacketMaxF: 75,
    humidHotFeelsF: 76,
    tempBandsF: [85, 76, 68, 60, 52, 42, 32],
  },
  timing: {
    weatherStaleMinutes: 90,
    widgetRefreshMinutes: 30,
    widgetStaleHours: 3,
    configCacheMinutes: 60,
  },
  copy: {
    confidence: {
      confident: "Confident",
      bringBackup: "Bring backup",
      rainRisk: "Rain risk",
      eveningDrop: "Evening drop",
      tunedForYou: "Tuned for you",
    },
    packTips: {
      rainLayer: "Rain layer",
      lightLayer: "Light layer",
      travelLight: "Travel light",
    },
    feedback: {
      too_cold: "Got it. Tomorrow will lean warmer.",
      too_hot: "Got it. Tomorrow will lighten up.",
      perfect: "Nice. Keeping this baseline.",
    },
    notificationTitle: "Today’s Fit",
  },
  flags: {
    enableOccasionPicker: true,
    enableTripPack: true,
    enableMorningNotifications: true,
  },
};

const STORAGE_KEY = "wearther:remote-config";
const FETCHED_AT_KEY = "wearther:remote-config-fetched-at";

let memory: RemoteConfig = DEFAULT_REMOTE_CONFIG;

function isObject(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function num(v: unknown, fallback: number): number {
  return typeof v === "number" && Number.isFinite(v) ? v : fallback;
}

function str(v: unknown, fallback: string): string {
  return typeof v === "string" && v.length > 0 ? v : fallback;
}

function bool(v: unknown, fallback: boolean): boolean {
  return typeof v === "boolean" ? v : fallback;
}

/** Deep-merge a partial payload onto defaults (unknown keys ignored). */
export function mergeRemoteConfig(partial: unknown): RemoteConfig {
  const base = DEFAULT_REMOTE_CONFIG;
  if (!isObject(partial)) return structuredClone(base);

  const t = isObject(partial.thresholds) ? partial.thresholds : {};
  const timing = isObject(partial.timing) ? partial.timing : {};
  const copy = isObject(partial.copy) ? partial.copy : {};
  const confidence = isObject(copy.confidence) ? copy.confidence : {};
  const packTips = isObject(copy.packTips) ? copy.packTips : {};
  const feedback = isObject(copy.feedback) ? copy.feedback : {};
  const flags = isObject(partial.flags) ? partial.flags : {};

  const bandsRaw = t.tempBandsF;
  const tempBandsF =
    Array.isArray(bandsRaw) &&
    bandsRaw.length === 7 &&
    bandsRaw.every((n) => typeof n === "number" && Number.isFinite(n))
      ? (bandsRaw as number[])
      : base.thresholds.tempBandsF;

  return {
    version: num(partial.version, base.version),
    thresholds: {
      strongWindMph: num(t.strongWindMph, base.thresholds.strongWindMph),
      highRainChance: num(t.highRainChance, base.thresholds.highRainChance),
      packRainChance: num(t.packRainChance, base.thresholds.packRainChance),
      highHumidity: num(t.highHumidity, base.thresholds.highHumidity),
      lowHumidity: num(t.lowHumidity, base.thresholds.lowHumidity),
      significantDropF: num(t.significantDropF, base.thresholds.significantDropF),
      diurnalSpanF: num(t.diurnalSpanF, base.thresholds.diurnalSpanF),
      windChillBelowF: num(t.windChillBelowF, base.thresholds.windChillBelowF),
      windJacketMinF: num(t.windJacketMinF, base.thresholds.windJacketMinF),
      windJacketMaxF: num(t.windJacketMaxF, base.thresholds.windJacketMaxF),
      humidHotFeelsF: num(t.humidHotFeelsF, base.thresholds.humidHotFeelsF),
      tempBandsF,
    },
    timing: {
      weatherStaleMinutes: num(
        timing.weatherStaleMinutes,
        base.timing.weatherStaleMinutes,
      ),
      widgetRefreshMinutes: num(
        timing.widgetRefreshMinutes,
        base.timing.widgetRefreshMinutes,
      ),
      widgetStaleHours: num(timing.widgetStaleHours, base.timing.widgetStaleHours),
      configCacheMinutes: num(
        timing.configCacheMinutes,
        base.timing.configCacheMinutes,
      ),
    },
    copy: {
      confidence: {
        confident: str(confidence.confident, base.copy.confidence.confident),
        bringBackup: str(confidence.bringBackup, base.copy.confidence.bringBackup),
        rainRisk: str(confidence.rainRisk, base.copy.confidence.rainRisk),
        eveningDrop: str(confidence.eveningDrop, base.copy.confidence.eveningDrop),
        tunedForYou: str(confidence.tunedForYou, base.copy.confidence.tunedForYou),
      },
      packTips: {
        rainLayer: str(packTips.rainLayer, base.copy.packTips.rainLayer),
        lightLayer: str(packTips.lightLayer, base.copy.packTips.lightLayer),
        travelLight: str(packTips.travelLight, base.copy.packTips.travelLight),
      },
      feedback: {
        too_cold: str(feedback.too_cold, base.copy.feedback.too_cold),
        too_hot: str(feedback.too_hot, base.copy.feedback.too_hot),
        perfect: str(feedback.perfect, base.copy.feedback.perfect),
      },
      notificationTitle: str(copy.notificationTitle, base.copy.notificationTitle),
    },
    flags: {
      enableOccasionPicker: bool(
        flags.enableOccasionPicker,
        base.flags.enableOccasionPicker,
      ),
      enableTripPack: bool(flags.enableTripPack, base.flags.enableTripPack),
      enableMorningNotifications: bool(
        flags.enableMorningNotifications,
        base.flags.enableMorningNotifications,
      ),
    },
  };
}

function readCached(): RemoteConfig | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    return mergeRemoteConfig(JSON.parse(raw) as unknown);
  } catch {
    return null;
  }
}

function writeCached(config: RemoteConfig) {
  if (typeof window === "undefined") return;
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
    localStorage.setItem(FETCHED_AT_KEY, String(Date.now()));
  } catch {
    // ignore quota / private mode
  }
}

function cacheIsFresh(config: RemoteConfig): boolean {
  if (typeof window === "undefined") return false;
  const raw = localStorage.getItem(FETCHED_AT_KEY);
  const fetchedAt = raw ? Number(raw) : 0;
  if (!fetchedAt) return false;
  const ttlMs = config.timing.configCacheMinutes * 60 * 1000;
  return Date.now() - fetchedAt < ttlMs;
}

/** Sync accessor used by recommenders / copy helpers. */
export function getRemoteConfig(): RemoteConfig {
  return memory;
}

/** Hydrate memory from localStorage (call once on client boot). */
export function hydrateRemoteConfigFromCache(): RemoteConfig {
  const cached = readCached();
  if (cached) memory = cached;
  return memory;
}

/**
 * Fetch latest config from `/api/config` when cache is stale.
 * Always resolves; failures keep the last known / default config.
 */
export async function refreshRemoteConfig(
  url = "/api/config",
): Promise<RemoteConfig> {
  hydrateRemoteConfigFromCache();
  if (cacheIsFresh(memory)) return memory;

  try {
    const res = await fetch(url, { cache: "no-store" });
    if (!res.ok) return memory;
    const json: unknown = await res.json();
    memory = mergeRemoteConfig(json);
    writeCached(memory);
  } catch {
    // keep defaults / cache
  }
  return memory;
}

/** Test helper — replace in-memory config. */
export function __setRemoteConfigForTests(config: RemoteConfig | null) {
  memory = config ? mergeRemoteConfig(config) : structuredClone(DEFAULT_REMOTE_CONFIG);
}
