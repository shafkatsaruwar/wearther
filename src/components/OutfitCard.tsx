import type { OutfitRecommendation } from "@/types/outfit";
import { ClothingGlyph } from "@/components/ClothingGlyph";

interface OutfitCardProps {
  outfit: OutfitRecommendation;
}

export function OutfitCard({ outfit }: OutfitCardProps) {
  return (
    <section
      className="animate-fade-up rounded-[1.75rem] bg-[var(--fit-surface)] px-6 py-8 sm:px-8 sm:py-10"
      style={{ animationDelay: "140ms" }}
      aria-labelledby="todays-fit"
    >
      <p
        id="todays-fit"
        className="text-[11px] font-medium uppercase tracking-[0.22em] text-[var(--accent)]"
      >
        Today&apos;s Fit
      </p>

      <h2 className="font-display mt-4 max-w-xl text-4xl leading-[1.1] tracking-tight text-[var(--ink)] sm:text-5xl">
        {outfit.title}
      </h2>

      <ul className="mt-8 flex flex-wrap gap-3 sm:gap-4">
        {outfit.items.map((item) => (
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
        {outfit.explanation}
      </p>

      {outfit.bringLater && (
        <p className="mt-4 text-sm font-medium text-[var(--accent)]">
          {outfit.bringLater}
        </p>
      )}
    </section>
  );
}
