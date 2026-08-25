"use client";

import type { ComfortFeedback } from "@/types/outfit";

interface ComfortFeedbackProps {
  disabled?: boolean;
  lastFeedback?: ComfortFeedback;
  onFeedback: (feedback: ComfortFeedback) => void;
}

const OPTIONS: Array<{
  id: ComfortFeedback;
  emoji: string;
  label: string;
}> = [
  { id: "too_cold", emoji: "🥶", label: "Too Cold" },
  { id: "perfect", emoji: "🙂", label: "Perfect" },
  { id: "too_hot", emoji: "🥵", label: "Too Hot" },
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
        className="text-center text-sm text-[var(--ink-muted)]"
      >
        How did this outfit feel?
      </h3>

      <div className="mt-4 flex flex-wrap justify-center gap-2 sm:gap-3">
        {OPTIONS.map((opt) => {
          const selected = lastFeedback === opt.id;
          return (
            <button
              key={opt.id}
              type="button"
              disabled={disabled}
              onClick={() => onFeedback(opt.id)}
              className={[
                "inline-flex items-center gap-2 rounded-full px-4 py-2.5 text-sm transition-all duration-200",
                selected
                  ? "bg-[var(--ink)] text-white dark:text-[#0f1215]"
                  : "bg-[var(--surface)] text-[var(--ink-soft)] ring-1 ring-[var(--line)] hover:bg-[var(--surface-hover)]",
                disabled ? "opacity-60" : "",
              ].join(" ")}
            >
              <span aria-hidden>{opt.emoji}</span>
              {opt.label}
            </button>
          );
        })}
      </div>

      {lastFeedback && (
        <p className="mt-3 text-center text-xs text-[var(--ink-faint)]">
          Saved locally — future fits will adapt slightly.
        </p>
      )}
    </section>
  );
}
