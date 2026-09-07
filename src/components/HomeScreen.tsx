"use client";

import { useCallback, useEffect, useState, useTransition } from "react";
import { BrandMark } from "@/components/BrandMark";
import { CitySearch } from "@/components/CitySearch";
import { ComfortFeedbackBar } from "@/components/ComfortFeedback";
import { CustomizePanel } from "@/components/CustomizePanel";
import { HourlyForecast } from "@/components/HourlyForecast";
import { Onboarding } from "@/components/Onboarding";
import { OutfitCard } from "@/components/OutfitCard";
import { PackLane } from "@/components/PackLane";
import { WeatherEvidence } from "@/components/WeatherEvidence";
import {
  applyComfortFeedback,
  DEFAULT_COMFORT,
  loadComfortPreference,
  saveComfortPreference,
} from "@/lib/comfort";
import { isWeatherStale, updatedLabel } from "@/lib/fitCopy";
import { recommendOutfit } from "@/lib/recommendOutfit";
import {
  hasCompletedOnboarding,
  loadSavedLocation,
  saveLocation,
} from "@/lib/storage";
import { DEFAULT_CITY } from "@/services/weather";
import type {
  ComfortFeedback,
  ComfortPreference,
  OutfitRecommendation,
} from "@/types/outfit";
import type { LocationResult, WeatherData } from "@/types/weather";

function formatDateLabel(date = new Date()) {
  return date.toLocaleDateString(undefined, {
    weekday: "long",
    month: "long",
    day: "numeric",
  });
}

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

export function HomeScreen() {
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [ready, setReady] = useState(false);
  const [location, setLocation] = useState<LocationResult>(DEFAULT_CITY);
  const [weather, setWeather] = useState<WeatherData | null>(null);
  const [outfit, setOutfit] = useState<OutfitRecommendation | null>(null);
  const [comfort, setComfort] = useState<ComfortPreference>(DEFAULT_COMFORT);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [customizeOpen, setCustomizeOpen] = useState(false);
  const [, startTransition] = useTransition();

  const applyWeather = useCallback((data: WeatherData, pref: ComfortPreference) => {
    setWeather(data);
    setComfort(pref);
    setOutfit(recommendOutfit({ weather: data, comfort: pref }));
    setError(null);
  }, []);

  const loadWeather = useCallback(
    async (loc: LocationResult, mode: "full" | "soft") => {
      if (mode === "full") setLoading(true);
      else setRefreshing(true);
      try {
        const data = await fetchWeather(loc);
        const pref = loadComfortPreference();
        applyWeather(data, pref);
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
      setLocation(loc);
      setComfort(pref);
      setReady(true);

      try {
        const data = await fetchWeather(loc);
        if (cancelled) return;
        applyWeather(data, loadComfortPreference());
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
      void loadWeather(loc, "full");
    },
    [loadWeather],
  );

  const handleFeedback = useCallback(
    (feedback: ComfortFeedback) => {
      const next = applyComfortFeedback(comfort, feedback);
      setComfort(next);
      if (weather) {
        setOutfit(recommendOutfit({ weather, comfort: next }));
      }
    },
    [comfort, weather],
  );

  const handlePreferenceChange = useCallback(
    (next: ComfortPreference) => {
      saveComfortPreference(next);
      setComfort(next);
      if (weather) {
        setOutfit(recommendOutfit({ weather, comfort: next }));
      }
    },
    [weather],
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

  return (
    <div className="relative min-h-dvh overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-atmosphere" aria-hidden />
      <div
        className="pointer-events-none absolute -left-24 top-[-10%] h-[28rem] w-[28rem] rounded-full bg-[radial-gradient(circle,var(--glow)_0%,transparent_70%)] opacity-70 blur-2xl animate-drift"
        aria-hidden
      />
      <div
        className="pointer-events-none absolute -right-16 bottom-[10%] h-[22rem] w-[22rem] rounded-full bg-[radial-gradient(circle,var(--glow-2)_0%,transparent_70%)] opacity-60 blur-2xl animate-drift-slow"
        aria-hidden
      />

      <main className="relative mx-auto flex w-full max-w-lg flex-col px-5 pb-16 pt-10 sm:max-w-xl sm:px-6 sm:pt-14">
        <header className="mb-2 flex items-start justify-between gap-4">
          <div className="min-w-0 flex-1">
            <CitySearch selected={location} onSelect={handleSelectLocation} />
          </div>
          <button
            type="button"
            onClick={() => setCustomizeOpen((v) => !v)}
            className="mt-1 inline-flex min-h-11 shrink-0 items-center rounded-full bg-[var(--surface)] px-4 text-sm text-[var(--ink-soft)] ring-1 ring-[var(--line)] transition-colors hover:text-[var(--ink)]"
            aria-expanded={customizeOpen}
          >
            Tune
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
          <div className="mt-12 flex flex-col items-center gap-6">
            <BrandMark className="h-14 w-14" />
            <div className="w-full space-y-4 animate-pulse">
              <div className="h-64 rounded-[1.875rem] bg-[var(--fit-surface)]" />
              <div className="h-12 rounded-full bg-[var(--surface)]" />
              <div className="h-36 rounded-[1.75rem] bg-[var(--surface)]" />
            </div>
          </div>
        )}

        {!loading && error && !weather && (
          <div className="mt-16 flex flex-col items-center gap-4 text-center">
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
          <div className="mt-6 flex flex-col gap-6">
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-xs text-[var(--ink-muted)]">
                  {formatDateLabel()}
                </p>
                <p
                  className={`mt-1 text-xs ${
                    stale || weather.isMock
                      ? "text-[var(--coral)]"
                      : "text-[var(--ink-soft)]"
                  }`}
                >
                  {updatedLabel(weather.fetchedAt)}
                  {weather.isMock
                    ? " · Demo weather"
                    : stale
                      ? " · May be stale"
                      : ""}
                </p>
              </div>
              <button
                type="button"
                disabled={refreshing}
                onClick={() => void loadWeather(location, "soft")}
                className="inline-flex h-11 w-11 items-center justify-center rounded-full bg-[var(--surface)] text-[var(--accent)] ring-1 ring-[var(--line)] disabled:opacity-60"
                aria-label="Refresh weather"
              >
                <span className={refreshing ? "inline-block animate-spin" : ""}>
                  ↻
                </span>
              </button>
            </div>

            <OutfitCard outfit={outfit} weather={weather} comfort={comfort} />
            <PackLane outfit={outfit} weather={weather} />
            <WeatherEvidence weather={weather} units={comfort.units} />
            <HourlyForecast hours={weather.hourly} comfort={comfort} />
            <ComfortFeedbackBar
              lastFeedback={comfort.lastFeedback}
              onFeedback={handleFeedback}
            />
          </div>
        )}
      </main>
    </div>
  );
}
