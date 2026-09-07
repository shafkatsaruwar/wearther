"use client";

import { useCallback, useEffect, useState, useTransition } from "react";
import { BrandMark } from "@/components/BrandMark";
import { CitySearch } from "@/components/CitySearch";
import { ClothingGlyph } from "@/components/ClothingGlyph";
import { CustomizePanel } from "@/components/CustomizePanel";
import { Onboarding } from "@/components/Onboarding";
import {
  applyComfortFeedback,
  DEFAULT_COMFORT,
  loadComfortPreference,
  saveComfortPreference,
} from "@/lib/comfort";
import { getClothingInfo } from "@/lib/clothingInfo";
import {
  confidenceForFit,
  formatFitTitle,
  isWeatherStale,
  packLaneItems,
  shortExplanation,
  updatedLabel,
  whyDetail,
} from "@/lib/fitCopy";
import {
  loadOccasionContext,
  occasionPillLabel,
  OCCASION_OPTIONS,
  saveOccasionContext,
} from "@/lib/occasion";
import { recommendOutfit } from "@/lib/recommendOutfit";
import {
  hasCompletedOnboarding,
  loadSavedLocation,
  saveLocation,
} from "@/lib/storage";
import { getRemoteConfig, refreshRemoteConfig } from "@/lib/remoteConfig";
import { DEFAULT_CITY } from "@/services/weather";
import type {
  ComfortFeedback,
  ComfortPreference,
  OccasionContext,
  OutfitRecommendation,
} from "@/types/outfit";
import type { LocationResult, WeatherData } from "@/types/weather";

async function fetchWeather(loc: LocationResult): Promise<WeatherData> {
  const params = new URLSearchParams({
    lat: String(loc.latitude),
    lon: String(loc.longitude),
    name: loc.name,
    id: loc.id,
  });
  if (loc.region) params.set("region", loc.region);
  if (loc.country) params.set("country", loc.country);

  const res = await fetch(`/api/weather?${params}`);
  if (!res.ok) throw new Error("Weather request failed");
  return (await res.json()) as WeatherData;
}

function formatHour(iso: string) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleTimeString(undefined, { hour: "numeric" });
}

export function HomeScreen() {
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [ready, setReady] = useState(false);
  const [location, setLocation] = useState<LocationResult>(DEFAULT_CITY);
  const [weather, setWeather] = useState<WeatherData | null>(null);
  const [outfit, setOutfit] = useState<OutfitRecommendation | null>(null);
  const [comfort, setComfort] = useState<ComfortPreference>(DEFAULT_COMFORT);
  const [occasion, setOccasion] = useState<OccasionContext>("everyday");
  const [occasionOpen, setOccasionOpen] = useState(false);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [locating, setLocating] = useState(false);
  const [locateError, setLocateError] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [customizeOpen, setCustomizeOpen] = useState(false);
  const [showWhy, setShowWhy] = useState(false);
  const [selectedItem, setSelectedItem] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const applyWeather = useCallback(
    (data: WeatherData, pref: ComfortPreference, ctx: OccasionContext) => {
      setWeather(data);
      setComfort(pref);
      setOutfit(recommendOutfit({ weather: data, comfort: pref, occasion: ctx }));
      setError(null);
    },
    [],
  );

  const loadWeather = useCallback(
    async (loc: LocationResult, mode: "full" | "soft") => {
      if (mode === "full") setLoading(true);
      else setRefreshing(true);
      try {
        const data = await fetchWeather(loc);
        const pref = loadComfortPreference();
        const ctx = loadOccasionContext();
        setOccasion(ctx);
        applyWeather(data, pref, ctx);
      } catch {
        setError("Couldn’t load weather. Try another city.");
        if (mode === "full") {
          setWeather(null);
          setOutfit(null);
        }
      } finally {
        setLoading(false);
        setRefreshing(false);
      }
    },
    [applyWeather],
  );

  useEffect(() => {
    let cancelled = false;

    void (async () => {
      await refreshRemoteConfig();
      if (cancelled) return;

      const onboarded = hasCompletedOnboarding();
      if (cancelled) return;

      if (!onboarded) {
        setShowOnboarding(true);
        setReady(true);
        setLoading(false);
        return;
      }

      const loc = loadSavedLocation();
      const pref = loadComfortPreference();
      const ctx = loadOccasionContext();
      setLocation(loc);
      setComfort(pref);
      setOccasion(ctx);
      setReady(true);

      try {
        const data = await fetchWeather(loc);
        if (cancelled) return;
        applyWeather(data, loadComfortPreference(), loadOccasionContext());
      } catch {
        if (cancelled) return;
        setError("Couldn’t load weather. Try another city.");
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [applyWeather]);

  const handleSelectLocation = useCallback(
    (loc: LocationResult) => {
      saveLocation(loc);
      setLocation(loc);
      setLocateError(null);
      void loadWeather(loc, "full");
    },
    [loadWeather],
  );

  const handleLocateMe = useCallback(async () => {
    if (!navigator.geolocation) {
      setLocateError("Location isn’t available in this browser.");
      return;
    }
    setLocating(true);
    setLocateError(null);
    try {
      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: false,
          timeout: 12000,
          maximumAge: 60_000,
        });
      });
      const { latitude, longitude } = position.coords;
      const res = await fetch(
        `/api/locations/reverse?lat=${encodeURIComponent(String(latitude))}&lon=${encodeURIComponent(String(longitude))}`,
      );
      if (!res.ok) throw new Error("reverse failed");
      const place = (await res.json()) as LocationResult;
      handleSelectLocation(place);
    } catch {
      setLocateError("Couldn’t find your location. Try searching a city.");
    } finally {
      setLocating(false);
    }
  }, [handleSelectLocation]);

  const handleFeedback = useCallback(
    (feedback: ComfortFeedback) => {
      const next = applyComfortFeedback(comfort, feedback);
      setComfort(next);
      if (weather) {
        setOutfit(recommendOutfit({ weather, comfort: next, occasion }));
      }
    },
    [comfort, weather, occasion],
  );

  const handlePreferenceChange = useCallback(
    (next: ComfortPreference) => {
      saveComfortPreference(next);
      setComfort(next);
      if (weather) {
        setOutfit(recommendOutfit({ weather, comfort: next, occasion }));
      }
    },
    [weather, occasion],
  );

  const handleOccasionChange = useCallback(
    (next: OccasionContext) => {
      saveOccasionContext(next);
      setOccasion(next);
      setOccasionOpen(false);
      if (weather) {
        setOutfit(recommendOutfit({ weather, comfort, occasion: next }));
      }
    },
    [weather, comfort],
  );

  const finishOnboarding = useCallback(() => {
    startTransition(() => {
      const loc = loadSavedLocation();
      const pref = loadComfortPreference();
      setComfort(pref);
      setLocation(loc);
      setShowOnboarding(false);
      setLoading(true);
      void loadWeather(loc, "full");
    });
  }, [loadWeather]);

  if (!ready) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-[var(--bg)]">
        <BrandMark className="h-16 w-16 animate-pulse" />
      </div>
    );
  }

  if (showOnboarding) {
    return <Onboarding onFinished={finishOnboarding} />;
  }

  const stale = weather ? isWeatherStale(weather.fetchedAt) : false;
  const packs = weather && outfit ? packLaneItems(outfit, weather) : [];
  const confidence =
    weather && outfit ? confidenceForFit(outfit, weather, comfort) : null;
  const selectedInfo =
    selectedItem && weather ? getClothingInfo(selectedItem, weather) : null;
  const laterLine =
    weather?.hourly
      .slice(0, 3)
      .map((h) => `${formatHour(h.time)} ${h.temperature}°`)
      .join("  ·  ") ?? "";

  return (
    <div className="relative flex min-h-dvh flex-col overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-atmosphere" aria-hidden />
      <div
        className="pointer-events-none absolute -left-24 top-[-10%] h-[28rem] w-[28rem] rounded-full bg-[radial-gradient(circle,var(--glow)_0%,transparent_70%)] opacity-70 blur-2xl animate-drift"
        aria-hidden
      />

      <main className="relative mx-auto flex w-full max-w-lg flex-1 flex-col px-4 pb-4 pt-6 sm:max-w-xl sm:px-5">
        <header className="mb-3 flex items-center gap-2">
          <div className="min-w-0 flex-1">
            <CitySearch selected={location} onSelect={handleSelectLocation} />
          </div>
          <button
            type="button"
            onClick={() => void handleLocateMe()}
            disabled={locating}
            className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[var(--mint)] text-[var(--accent)] disabled:opacity-60"
            aria-label="Locate Me"
          >
            {locating ? "…" : "◎"}
          </button>
          <button
            type="button"
            onClick={() => setCustomizeOpen((v) => !v)}
            className="inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-[var(--surface)] text-[var(--ink-soft)] ring-1 ring-[var(--line)]"
            aria-expanded={customizeOpen}
            aria-label="Tune preferences"
          >
            ☰
          </button>
        </header>

        {customizeOpen && (
          <CustomizePanel
            preference={comfort}
            onChange={handlePreferenceChange}
            onClose={() => setCustomizeOpen(false)}
          />
        )}

        {loading && (
          <div className="flex flex-1 flex-col items-center justify-center gap-4">
            <BrandMark className="h-14 w-14" />
            <p className="text-sm text-[var(--ink-muted)]">Checking what to wear…</p>
          </div>
        )}

        {!loading && error && !weather && (
          <div className="flex flex-1 flex-col items-center justify-center gap-4 text-center">
            <BrandMark className="h-16 w-16" />
            <p className="text-[var(--ink-muted)]">{error}</p>
            <button
              type="button"
              onClick={() => void loadWeather(location, "full")}
              className="min-h-11 rounded-full bg-[var(--accent)] px-5 text-sm font-medium text-white"
            >
              Try again
            </button>
          </div>
        )}

        {!loading && weather && outfit && !customizeOpen && (
          <section className="flex min-h-0 flex-1 flex-col rounded-[1.75rem] bg-[var(--fit-surface)] px-5 py-5 shadow-[0_16px_40px_-24px_rgba(20,24,28,0.35)]">
            {locateError && (
              <p className="mb-2 text-xs text-[var(--coral)]">{locateError}</p>
            )}

            <div className="mb-3 flex flex-wrap items-center gap-2">
              <p className="text-[11px] font-medium uppercase tracking-[0.16em] text-[var(--accent)]">
                Wear this today
              </p>
              {getRemoteConfig().flags.enableOccasionPicker && (
              <button
                type="button"
                onClick={() => setOccasionOpen(true)}
                className="inline-flex items-center gap-1 rounded-full bg-[var(--mint)] px-3 py-1 text-[11px] font-semibold text-[var(--accent)]"
                aria-haspopup="dialog"
                aria-expanded={occasionOpen}
              >
                {occasionPillLabel(occasion)}
                <span aria-hidden>▾</span>
              </button>
              )}
              {confidence && (
                <span className="text-[11px] font-semibold text-[var(--accent)]">
                  {confidence}
                </span>
              )}
            </div>

            <div className="flex items-start justify-between gap-3">
              <h1 className="font-display text-[1.75rem] leading-tight tracking-tight text-[var(--ink)] sm:text-[2rem]">
                {formatFitTitle(outfit)}
              </h1>
            </div>

            <p className="mt-2 line-clamp-2 text-sm text-[var(--ink-soft)]">
              {shortExplanation(outfit)}
            </p>

            <div className="mt-4 flex gap-2">
              {outfit.items.slice(0, 3).map((item) => (
                <button
                  key={item}
                  type="button"
                  onClick={() => setSelectedItem(item)}
                  className="flex min-w-0 flex-1 items-center justify-center gap-1.5 rounded-full bg-[color-mix(in_srgb,var(--accent)_7%,transparent)] px-2 py-2 text-xs font-semibold text-[var(--ink)]"
                >
                  <ClothingGlyph label={item} className="h-3.5 w-3.5 text-[var(--accent)]" />
                  <span className="truncate">{item}</span>
                </button>
              ))}
            </div>

            <div className="mt-4 space-y-1 text-sm">
              <div className="flex items-center gap-2">
                <p className="font-medium text-[var(--ink)]">
                  {weather.temperature}° {weather.condition}
                </p>
                <span className="text-[var(--ink-faint)]">·</span>
                <p className="text-xs text-[var(--ink-muted)]">
                  Feels {weather.feelsLike}°
                </p>
                <button
                  type="button"
                  disabled={refreshing}
                  onClick={() => void loadWeather(location, "soft")}
                  className="ml-auto text-[var(--accent)] disabled:opacity-50"
                  aria-label="Refresh weather"
                >
                  {refreshing ? "…" : "↻"}
                </button>
              </div>
              <p className="truncate text-xs text-[var(--ink-muted)]">
                Wind {weather.windSpeed} mph · H {weather.high}° / L {weather.low}°
                {packs[0] ? ` · Pack ${packs[0].toLowerCase()}` : ""}
              </p>
              {(weather.isMock || stale) && (
                <p className="text-xs text-[var(--coral)]">
                  {weather.isMock
                    ? "Demo weather"
                    : `${updatedLabel(weather.fetchedAt)} · May be stale`}
                </p>
              )}
            </div>

            {(laterLine) && (
              <div className="mt-3 space-y-1 text-xs text-[var(--ink-soft)]">
                <p className="line-clamp-2">{laterLine}</p>
              </div>
            )}

            <div className="mt-auto flex items-center gap-4 pt-4">
              <button
                type="button"
                onClick={() => setShowWhy(true)}
                className="text-sm font-medium text-[var(--accent)]"
              >
                Why?
              </button>
            </div>

            <div className="mt-3">
              <p className="text-[10px] font-medium uppercase tracking-[0.16em] text-[var(--ink-muted)]">
                How does this feel?
              </p>
              <div className="mt-2 flex gap-2">
                {(
                  [
                    ["too_cold", "Too Cold", false],
                    ["perfect", "Perfect", true],
                    ["too_hot", "Too Hot", false],
                  ] as const
                ).map(([id, label, primary]) => {
                  const selected = comfort.lastFeedback === id;
                  return (
                    <button
                      key={id}
                      type="button"
                      onClick={() => handleFeedback(id)}
                      className={`min-h-10 flex-1 rounded-full text-xs font-semibold ${
                        selected
                          ? primary
                            ? "bg-[var(--accent)] text-white"
                            : "bg-[var(--ink)] text-white"
                          : primary
                            ? "bg-[color-mix(in_srgb,var(--accent)_12%,transparent)] text-[var(--accent)] ring-1 ring-[color-mix(in_srgb,var(--accent)_28%,transparent)]"
                            : "bg-[var(--surface)] text-[var(--ink-soft)] ring-1 ring-[var(--line)]"
                      }`}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>
            </div>
          </section>
        )}
      </main>

      {occasionOpen && (
        <div className="fixed inset-0 z-40 flex items-end justify-center bg-black/25 p-4 sm:items-center">
          <div className="w-full max-w-md rounded-3xl bg-[var(--fit-surface)] p-5 shadow-xl">
            <div className="flex items-center justify-between gap-3">
              <h2 className="font-display text-xl text-[var(--ink)]">Today&apos;s context</h2>
              <button
                type="button"
                onClick={() => setOccasionOpen(false)}
                className="text-sm text-[var(--ink-muted)]"
              >
                Done
              </button>
            </div>
            <p className="mt-1 text-sm text-[var(--ink-muted)]">
              Changes today&apos;s outfit without replacing your style preference.
            </p>
            <ul className="mt-4 space-y-2">
              {OCCASION_OPTIONS.map((opt) => {
                const selected = occasion === opt.id;
                return (
                  <li key={opt.id}>
                    <button
                      type="button"
                      onClick={() => handleOccasionChange(opt.id)}
                      className={`flex w-full flex-col rounded-2xl px-4 py-3 text-left ring-1 ${
                        selected
                          ? "bg-[var(--mint)] ring-[color-mix(in_srgb,var(--accent)_35%,transparent)]"
                          : "bg-[var(--surface)] ring-[var(--line)]"
                      }`}
                    >
                      <span className="text-sm font-semibold text-[var(--ink)]">
                        {opt.label}
                      </span>
                      <span className="text-xs text-[var(--ink-muted)]">{opt.hint}</span>
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>
        </div>
      )}

      {showWhy && weather && outfit && (
        <div className="fixed inset-0 z-40 flex items-end justify-center bg-black/25 p-4 sm:items-center">
          <div className="w-full max-w-md rounded-3xl bg-[var(--fit-surface)] p-5 shadow-xl">
            <div className="flex items-center justify-between gap-3">
              <h2 className="font-display text-xl text-[var(--ink)]">Why this fit</h2>
              <button
                type="button"
                onClick={() => setShowWhy(false)}
                className="text-sm text-[var(--ink-muted)]"
              >
                Done
              </button>
            </div>
            <p className="mt-3 text-sm leading-relaxed text-[var(--ink-soft)]">
              {whyDetail(weather, outfit)}
            </p>
          </div>
        </div>
      )}

      {selectedInfo && (
        <div className="fixed inset-0 z-40 flex items-end justify-center bg-black/25 p-4 sm:items-center">
          <div className="w-full max-w-md rounded-3xl bg-[var(--fit-surface)] p-5 shadow-xl">
            <div className="flex items-center justify-between gap-3">
              <h2 className="font-display text-xl text-[var(--ink)]">
                {selectedInfo.name}
              </h2>
              <button
                type="button"
                onClick={() => setSelectedItem(null)}
                className="text-sm text-[var(--ink-muted)]"
              >
                Done
              </button>
            </div>
            <p className="mt-4 text-[10px] font-medium uppercase tracking-[0.16em] text-[var(--ink-muted)]">
              What it is
            </p>
            <p className="mt-1 text-sm text-[var(--ink-soft)]">{selectedInfo.whatItIs}</p>
            <p className="mt-4 text-[10px] font-medium uppercase tracking-[0.16em] text-[var(--ink-muted)]">
              Why today
            </p>
            <p className="mt-1 text-sm text-[var(--ink-soft)]">{selectedInfo.whyToday}</p>
          </div>
        </div>
      )}
    </div>
  );
}
