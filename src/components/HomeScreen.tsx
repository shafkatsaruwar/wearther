"use client";

import { useCallback, useEffect, useState } from "react";
import { CitySearch } from "@/components/CitySearch";
import { ComfortFeedbackBar } from "@/components/ComfortFeedback";
import { CustomizePanel } from "@/components/CustomizePanel";
import { HourlyForecast } from "@/components/HourlyForecast";
import { OutfitCard } from "@/components/OutfitCard";
import { WeatherSummary } from "@/components/WeatherSummary";
import {
  applyComfortFeedback,
  DEFAULT_COMFORT,
  loadComfortPreference,
  saveComfortPreference,
} from "@/lib/comfort";
import { recommendOutfit } from "@/lib/recommendOutfit";
import { loadSavedLocation, saveLocation } from "@/lib/storage";
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
  const [location, setLocation] = useState<LocationResult>(DEFAULT_CITY);
  const [weather, setWeather] = useState<WeatherData | null>(null);
  const [outfit, setOutfit] = useState<OutfitRecommendation | null>(null);
  const [comfort, setComfort] = useState<ComfortPreference>(DEFAULT_COMFORT);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [hydrated, setHydrated] = useState(false);
  const [customizeOpen, setCustomizeOpen] = useState(false);

  useEffect(() => {
    let cancelled = false;

    void Promise.resolve().then(() => {
      if (cancelled) return;
      setLocation(loadSavedLocation());
      setComfort(loadComfortPreference());
      setHydrated(true);
    });

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!hydrated) return;

    let cancelled = false;

    void (async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await fetchWeather(location);
        if (cancelled) return;
        const pref = loadComfortPreference();
        setWeather(data);
        setComfort(pref);
        setOutfit(recommendOutfit({ weather: data, comfort: pref }));
      } catch {
        if (cancelled) return;
        setError("Couldn’t load weather. Try another city.");
        setWeather(null);
        setOutfit(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [hydrated, location]);

  const handleSelectLocation = useCallback((loc: LocationResult) => {
    saveLocation(loc);
    setLocation(loc);
  }, []);

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
            className="mt-2 shrink-0 text-sm text-[var(--ink-muted)] transition-colors hover:text-[var(--ink)]"
            aria-expanded={customizeOpen}
          >
            Customize
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
          <div className="mt-16 space-y-6 animate-pulse">
            <div className="h-20 w-40 rounded-2xl bg-[var(--surface)]" />
            <div className="h-4 w-56 rounded bg-[var(--surface)]" />
            <div className="mt-10 h-56 rounded-[1.75rem] bg-[var(--fit-surface)]" />
          </div>
        )}

        {!loading && error && (
          <p className="mt-16 text-center text-[var(--ink-muted)]">{error}</p>
        )}

        {!loading && weather && outfit && !customizeOpen && (
          <div className="mt-8 flex flex-col gap-10">
            <WeatherSummary
              weather={weather}
              dateLabel={formatDateLabel()}
              units={comfort.units}
            />

            <div className="h-px w-full bg-[var(--line)]" />

            <OutfitCard outfit={outfit} />

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
