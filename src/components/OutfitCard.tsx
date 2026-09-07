"use client";

import { useEffect, useId, useRef, useState } from "react";
import {
  confidenceForFit,
  formatFitTitle,
  shortExplanation,
  whyDetail,
} from "@/lib/fitCopy";
import { getClothingInfo } from "@/lib/clothingInfo";
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
  const [selectedItem, setSelectedItem] = useState<string | null>(null);
  const title = formatFitTitle(outfit);
  const confidence = confidenceForFit(outfit, weather, comfort);
  const accentRisk =
    confidence === "Rain risk" || confidence === "Evening drop";
  const selectedInfo = selectedItem
    ? getClothingInfo(selectedItem, weather)
    : null;

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

      <ul className="mt-8 grid grid-cols-3 gap-2 sm:gap-3">
        {outfit.items.slice(0, 3).map((item) => {
          const info = getClothingInfo(item, weather);
          return (
            <li key={item}>
              <button
                type="button"
                onClick={() => setSelectedItem(item)}
                aria-label={`Learn about ${item}`}
                className="flex min-h-11 w-full flex-col items-center gap-2 rounded-2xl px-1 py-2 text-center transition-colors hover:bg-[var(--fit-icon-bg)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--accent)]"
              >
                <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-[var(--fit-icon-bg)] text-[var(--ink-soft)]">
                  <ClothingGlyph label={item} className="h-7 w-7" />
                </span>
                <span className="max-w-[6.5rem] text-[12px] font-medium leading-snug text-[var(--ink)]">
                  {item}
                </span>
                <span className="max-w-[6.5rem] text-[11px] leading-snug text-[var(--ink-muted)]">
                  {info.subtitle}
                </span>
              </button>
            </li>
          );
        })}
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

      {selectedInfo && (
        <ClothingInfoDialog
          info={selectedInfo}
          onClose={() => setSelectedItem(null)}
        />
      )}
    </section>
  );
}

function ClothingInfoDialog({
  info,
  onClose,
}: {
  info: ReturnType<typeof getClothingInfo>;
  onClose: () => void;
}) {
  const titleId = useId();
  const closeRef = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    closeRef.current?.focus();
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") onClose();
    }
    document.addEventListener("keydown", onKey);
    return () => document.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
      <button
        type="button"
        className="absolute inset-0 bg-[rgba(23,32,39,0.42)]"
        aria-label="Close clothing details"
        onClick={onClose}
      />
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        className="relative z-10 w-full max-w-md rounded-t-[1.75rem] bg-[var(--fit-surface)] px-6 pb-8 pt-5 shadow-[0_-20px_50px_-24px_rgba(20,24,28,0.45)] sm:rounded-[1.75rem] sm:pb-6"
      >
        <div className="mx-auto mb-4 h-1 w-10 rounded-full bg-[var(--line)] sm:hidden" />
        <div className="flex items-start justify-between gap-3">
          <h3
            id={titleId}
            className="font-display text-2xl tracking-tight text-[var(--ink)]"
          >
            {info.name}
          </h3>
          <button
            ref={closeRef}
            type="button"
            onClick={onClose}
            className="inline-flex h-11 w-11 items-center justify-center rounded-full text-[var(--ink-muted)] ring-1 ring-[var(--line)] hover:text-[var(--ink)]"
            aria-label="Close"
          >
            ×
          </button>
        </div>

        <div className="mt-5 space-y-4">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-[var(--ink-muted)]">
              What it is
            </p>
            <p className="mt-1 text-sm leading-relaxed text-[var(--ink-soft)]">
              {info.whatItIs}
            </p>
          </div>
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-[var(--ink-muted)]">
              Why today
            </p>
            <p className="mt-1 text-sm leading-relaxed text-[var(--ink-soft)]">
              {info.whyToday}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
