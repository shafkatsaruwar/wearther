"use client";

import type { ReactNode } from "react";
import type {
  AlwaysPackPrefs,
  ComfortPreference,
  FeelBaseline,
  StyleMode,
  TempUnits,
} from "@/types/outfit";

interface CustomizePanelProps {
  preference: ComfortPreference;
  onChange: (next: ComfortPreference) => void;
  onClose: () => void;
}

const FEEL_OPTIONS: { id: FeelBaseline; label: string }[] = [
  { id: "colder", label: "Colder than most" },
  { id: "average", label: "Average" },
  { id: "warmer", label: "Warmer than most" },
];

const STYLE_OPTIONS: { id: StyleMode; label: string }[] = [
  { id: "casual", label: "Casual" },
  { id: "smart_casual", label: "Smart casual" },
  { id: "athletic", label: "Athletic" },
  { id: "formal", label: "Formal" },
];

const PACK_OPTIONS: { key: keyof AlwaysPackPrefs; label: string }[] = [
  { key: "rainJacket", label: "Rain jacket" },
  { key: "lightLayer", label: "Light layer for later" },
  { key: "scarf", label: "Scarf" },
];

export function CustomizePanel({
  preference,
  onChange,
  onClose,
}: CustomizePanelProps) {
  function patch(
    partial: Partial<Pick<ComfortPreference, "feelBaseline" | "style" | "units">> & {
      alwaysPack?: Partial<AlwaysPackPrefs>;
    },
  ) {
    onChange({
      ...preference,
      ...partial,
      alwaysPack: {
        ...preference.alwaysPack,
        ...(partial.alwaysPack ?? {}),
      },
      updatedAt: new Date().toISOString(),
    });
  }

  return (
    <section
      className="animate-fade-up mt-6 space-y-4"
      aria-labelledby="your-preferences"
    >
      <div className="flex items-center justify-between gap-3">
        <h2
          id="your-preferences"
          className="text-[11px] font-medium uppercase tracking-[0.22em] text-[var(--accent)]"
        >
          Your Preferences
        </h2>
        <button
          type="button"
          onClick={onClose}
          className="text-sm text-[var(--ink-muted)] transition-colors hover:text-[var(--ink)]"
        >
          Done
        </button>
      </div>

      <PrefCard title="I usually feel">
        <div className="flex flex-wrap gap-2">
          {FEEL_OPTIONS.map((opt) => (
            <Chip
              key={opt.id}
              label={opt.label}
              selected={preference.feelBaseline === opt.id}
              onClick={() => patch({ feelBaseline: opt.id })}
            />
          ))}
        </div>
      </PrefCard>

      <PrefCard title="Style">
        <div className="flex flex-wrap gap-2">
          {STYLE_OPTIONS.map((opt) => (
            <Chip
              key={opt.id}
              label={opt.label}
              selected={preference.style === opt.id}
              onClick={() => patch({ style: opt.id })}
            />
          ))}
        </div>
      </PrefCard>

      <PrefCard title="Always pack">
        <ul className="space-y-3">
          {PACK_OPTIONS.map((opt) => (
            <li
              key={opt.key}
              className="flex items-center justify-between gap-3"
            >
              <span className="text-sm text-[var(--ink-soft)]">{opt.label}</span>
              <Toggle
                checked={preference.alwaysPack[opt.key]}
                onChange={(checked) =>
                  patch({ alwaysPack: { [opt.key]: checked } })
                }
                label={opt.label}
              />
            </li>
          ))}
        </ul>
      </PrefCard>

      <PrefCard title="Units">
        <div className="inline-flex rounded-full bg-[var(--fit-icon-bg)] p-1">
          {(["fahrenheit", "celsius"] as TempUnits[]).map((unit) => {
            const selected = preference.units === unit;
            return (
              <button
                key={unit}
                type="button"
                onClick={() => patch({ units: unit })}
                className={`rounded-full px-4 py-1.5 text-sm transition-colors ${
                  selected
                    ? "bg-[var(--ink)] text-white"
                    : "text-[var(--ink-muted)] hover:text-[var(--ink)]"
                }`}
              >
                {unit === "fahrenheit" ? "°F" : "°C"}
              </button>
            );
          })}
        </div>
      </PrefCard>
    </section>
  );
}

function PrefCard({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <div className="rounded-[1.5rem] bg-[var(--fit-surface)] px-5 py-5">
      <p className="mb-3 text-sm font-medium text-[var(--ink)]">{title}</p>
      {children}
    </div>
  );
}

function Chip({
  label,
  selected,
  onClick,
}: {
  label: string;
  selected: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-full px-3.5 py-2 text-sm transition-colors ${
        selected
          ? "bg-[var(--ink)] text-white"
          : "bg-[var(--surface)] text-[var(--ink-soft)] hover:bg-[var(--surface-hover)]"
      }`}
    >
      {label}
    </button>
  );
}

function Toggle({
  checked,
  onChange,
  label,
}: {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange(!checked)}
      className={`relative h-7 w-12 rounded-full transition-colors ${
        checked ? "bg-[var(--accent)]" : "bg-[var(--fit-icon-bg)]"
      }`}
    >
      <span
        className={`absolute top-0.5 h-6 w-6 rounded-full bg-white shadow-sm transition-transform ${
          checked ? "left-5" : "left-0.5"
        }`}
      />
    </button>
  );
}
