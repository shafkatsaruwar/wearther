"use client";

import { useState } from "react";
import {
  confidenceForFit,
  formatFitTitle,
  shortExplanation,
  whyDetail,
} from "@/lib/fitCopy";
import { ClothingGlyph } from "@/components/ClothingGlyph";
import type { ComfortPreference, OutfitRecommendation } from "@/types/outfit";
import type { WeatherData } from "@/types/weather";

interface OutfitCardProps {
  outfit: OutfitRecommendation;
  weather: WeatherData;
  comfort: ComfortPreference;
}

export function OutfitCard({ outfit, weather, comfort }: OutfitCardProps) {
  const [showWhy, setShowWhy] = useState(false);
  const title = formatFitTitle(outfit);
  const confidence = confidenceForFit(outfit, weather, comfort);
  const accentRisk =
    confidence === "Rain risk" || confidence === "Evening drop";

  return (
    <section
      className="animate-fade-up rounded-[1.875rem] bg-[var(--fit-surface)] px-6 py-8 sm:px-8 sm:py-10"
      style={{ animationDelay: "80ms" }}
      aria-labelledby="todays-fit"
    >
      <div className="flex items-center justify-between gap-3">
        <p
          id="todays-fit"
          className="text-[11px] font-medium uppercase tracking-[0.22em] text-[var(--accent)]"
        >
          Today&apos;s Fit
        </p>
        <span
          className={`inline-flex items-center rounded-full px-3 py-1 text-[11px] font-semibold ${
            accentRisk
              ? "bg-[color-mix(in_srgb,var(--coral)_16%,transparent)] text-[var(--coral)]"
              : "bg-[var(--mint)] text-[var(--accent)]"
          }`}
        >
          {confidence}
        </span>
      </div>

      <h2 className="font-display mt-4 max-w-xl text-4xl leading-[1.1] tracking-tight text-[var(--ink)] sm:text-5xl">
        {title}
      </h2>

      <ul className="mt-8 flex flex-wrap gap-3 sm:gap-4">
        {outfit.items.slice(0, 3).map((item) => (
          <li
            key={item}
            className="flex min-w-[4.5rem] flex-col items-center gap-2"
          >
            <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-[var(--fit-icon-bg)] text-[var(--ink-soft)] transition-transform duration-300 hover:-translate-y-0.5">
              <ClothingGlyph label={item} className="h-7 w-7" />
            </span>
            <span className="max-w-[5.5rem] text-center text-[11px] leading-snug text-[var(--ink-muted)]">
              {item}
            </span>
          </li>
        ))}
      </ul>

      <p className="mt-8 max-w-lg text-base leading-relaxed text-[var(--ink-soft)]">
        {shortExplanation(outfit)}
      </p>

      <button
        type="button"
        onClick={() => setShowWhy((v) => !v)}
        className="mt-3 inline-flex min-h-11 items-center gap-2 text-sm font-medium text-[var(--accent)]"
        aria-expanded={showWhy}
      >
        Why?
        <span aria-hidden>{showWhy ? "▴" : "▾"}</span>
      </button>

      {showWhy && (
        <p className="mt-2 rounded-[1.125rem] bg-[var(--mint)] px-4 py-3 text-sm leading-relaxed text-[var(--ink-muted)]">
          {whyDetail(weather, outfit)}
        </p>
      )}
    </section>
  );
}
