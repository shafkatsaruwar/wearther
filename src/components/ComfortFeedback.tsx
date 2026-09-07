"use client";

import type { ComfortFeedback } from "@/types/outfit";
import { feedbackResponse } from "@/lib/fitCopy";

interface ComfortFeedbackProps {
  disabled?: boolean;
  lastFeedback?: ComfortFeedback;
  onFeedback: (feedback: ComfortFeedback) => void;
}

const OPTIONS: Array<{
  id: ComfortFeedback;
  label: string;
}> = [
  { id: "too_cold", label: "Too Cold" },
  { id: "perfect", label: "Perfect" },
  { id: "too_hot", label: "Too Hot" },
];

export function ComfortFeedbackBar({
  disabled,
  lastFeedback,
  onFeedback,
}: ComfortFeedbackProps) {
  return (
    <section
      className="animate-fade-up border-t border-[var(--line)] pt-8"
      style={{ animationDelay: "280ms" }}
      aria-labelledby="how-feel"
    >
      <h3
        id="how-feel"
        className="text-center text-[11px] font-medium uppercase tracking-[0.18em] text-[var(--ink-muted)]"
      >
        How would this feel?
      </h3>

      <div className="mt-4 flex flex-wrap justify-center gap-2 sm:gap-3">
        {OPTIONS.map((opt) => {
          const selected = lastFeedback === opt.id;
          const primary = opt.id === "perfect";
          return (
            <button
              key={opt.id}
              type="button"
              disabled={disabled}
              onClick={() => onFeedback(opt.id)}
              className={[
                "inline-flex min-h-11 min-w-[6.5rem] items-center justify-center rounded-full px-4 py-2.5 text-sm font-medium transition-all duration-200",
                selected
                  ? primary
                    ? "bg-[var(--accent)] text-white"
                    : "bg-[var(--ink)] text-white"
                  : primary
                    ? "bg-[color-mix(in_srgb,var(--accent)_12%,transparent)] text-[var(--accent)] ring-1 ring-[color-mix(in_srgb,var(--accent)_28%,transparent)]"
                    : "bg-[var(--surface)] text-[var(--ink-soft)] ring-1 ring-[var(--line)] hover:bg-[var(--surface-hover)]",
                disabled ? "opacity-60" : "",
              ].join(" ")}
            >
              {opt.label}
            </button>
          );
        })}
      </div>

      {lastFeedback && (
        <p className="mt-3 text-center text-sm font-medium text-[var(--accent)]">
          {feedbackResponse(lastFeedback)}
        </p>
      )}
    </section>
  );
}
