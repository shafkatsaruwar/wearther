"use client";

import { useState } from "react";
import {
  DEFAULT_COMFORT,
  saveComfortPreference,
} from "@/lib/comfort";
import { saveLocation, setOnboardingComplete } from "@/lib/storage";
import { DEFAULT_CITY } from "@/services/weather";
import type { FeelBaseline, StyleMode } from "@/types/outfit";
import type { LocationResult } from "@/types/weather";
import { BrandMark } from "@/components/BrandMark";

interface OnboardingProps {
  onFinished: () => void;
}

const FEEL: { id: FeelBaseline; label: string; hint: string }[] = [
  { id: "colder", label: "I run cold", hint: "Recommend slightly warmer outfits" },
  { id: "average", label: "Average", hint: "Balanced for most people" },
  { id: "warmer", label: "I run warm", hint: "Recommend slightly cooler outfits" },
];

const STYLES: { id: StyleMode; label: string }[] = [
  { id: "casual", label: "Casual" },
  { id: "smart_casual", label: "Smart casual" },
  { id: "athletic", label: "Athletic" },
  { id: "formal", label: "Formal" },
];

export function Onboarding({ onFinished }: OnboardingProps) {
  const [step, setStep] = useState(0);
  const [feel, setFeel] = useState<FeelBaseline>("average");
  const [style, setStyle] = useState<StyleMode>("casual");

  function finish() {
    const comfort = {
      ...DEFAULT_COMFORT,
      feelBaseline: feel,
      style,
      updatedAt: new Date().toISOString(),
    };
    saveComfortPreference(comfort);
    saveLocation(DEFAULT_CITY as LocationResult);
    setOnboardingComplete(true);
    onFinished();
  }

  return (
    <div className="relative min-h-dvh overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-atmosphere" aria-hidden />
      <main className="relative mx-auto flex min-h-dvh w-full max-w-lg flex-col px-5 pb-10 pt-8 sm:max-w-xl">
        <div className="mb-8 flex gap-2">
          {[0, 1].map((i) => (
            <span
              key={i}
              className={`h-1 flex-1 rounded-full ${
                i <= step ? "bg-[var(--accent)]" : "bg-[var(--line)]"
              }`}
            />
          ))}
        </div>

        {step === 0 ? (
          <section className="flex flex-1 flex-col">
            <BrandMark className="h-14 w-14" />
            <h1 className="font-display mt-6 text-4xl leading-tight text-[var(--ink)]">
              Do you usually run cold, average, or warm?
            </h1>
            <p className="mt-3 text-base text-[var(--ink-soft)]">
              One question. Wearther uses it to nudge today&apos;s fit.
            </p>
            <ul className="mt-8 space-y-3">
              {FEEL.map((opt) => {
                const selected = feel === opt.id;
                return (
                  <li key={opt.id}>
                    <button
                      type="button"
                      onClick={() => setFeel(opt.id)}
                      className={`flex w-full items-center justify-between rounded-[1.125rem] px-4 py-4 text-left ring-1 transition-colors ${
                        selected
                          ? "bg-[var(--surface)] ring-[color-mix(in_srgb,var(--accent)_45%,transparent)]"
                          : "bg-[var(--surface)] ring-[var(--line)]"
                      }`}
                    >
                      <span>
                        <span className="block text-sm font-medium text-[var(--ink)]">
                          {opt.label}
                        </span>
                        <span className="mt-1 block text-xs text-[var(--ink-muted)]">
                          {opt.hint}
                        </span>
                      </span>
                      <span
                        className={`text-lg ${selected ? "text-[var(--accent)]" : "text-[var(--ink-faint)]"}`}
                        aria-hidden
                      >
                        {selected ? "●" : "○"}
                      </span>
                    </button>
                  </li>
                );
              })}
            </ul>
          </section>
        ) : (
          <section className="flex flex-1 flex-col">
            <h1 className="font-display text-4xl leading-tight text-[var(--ink)]">
              What style should Wearther assume?
            </h1>
            <p className="mt-3 text-base text-[var(--ink-soft)]">
              Same weather, different wardrobe language.
            </p>
            <ul className="mt-8 space-y-3">
              {STYLES.map((opt) => {
                const selected = style === opt.id;
                return (
                  <li key={opt.id}>
                    <button
                      type="button"
                      onClick={() => setStyle(opt.id)}
                      className={`flex min-h-14 w-full items-center justify-between rounded-[1.125rem] px-4 py-4 text-left ring-1 ${
                        selected
                          ? "bg-[var(--surface)] ring-[color-mix(in_srgb,var(--accent)_45%,transparent)]"
                          : "bg-[var(--surface)] ring-[var(--line)]"
                      }`}
                    >
                      <span className="text-sm font-medium text-[var(--ink)]">
                        {opt.label}
                      </span>
                      <span
                        className={selected ? "text-[var(--accent)]" : "text-[var(--ink-faint)]"}
                        aria-hidden
                      >
                        {selected ? "●" : "○"}
                      </span>
                    </button>
                  </li>
                );
              })}
            </ul>
          </section>
        )}

        <div className="mt-8 flex gap-3">
          {step > 0 && (
            <button
              type="button"
              onClick={() => setStep(0)}
              className="min-h-12 px-4 text-sm font-medium text-[var(--ink-muted)]"
            >
              Back
            </button>
          )}
          <button
            type="button"
            onClick={() => (step === 0 ? setStep(1) : finish())}
            className="min-h-12 flex-1 rounded-full bg-[var(--accent)] text-sm font-medium text-white"
          >
            {step === 0 ? "Continue" : "Start Wearther"}
          </button>
        </div>
      </main>
    </div>
  );
}
