import {
  packLaneItems,
} from "@/lib/fitCopy";
import type { OutfitRecommendation } from "@/types/outfit";
import type { WeatherData } from "@/types/weather";

interface PackLaneProps {
  outfit: OutfitRecommendation;
  weather: WeatherData;
}

export function PackLane({ outfit, weather }: PackLaneProps) {
  const items = packLaneItems(outfit, weather);
  if (!items.length) return null;

  return (
    <section
      className="animate-fade-up"
      style={{ animationDelay: "120ms" }}
      aria-labelledby="pack-later"
    >
      <h3
        id="pack-later"
        className="text-[11px] font-medium uppercase tracking-[0.18em] text-[var(--ink-muted)]"
      >
        Pack later
      </h3>
      <ul className="mt-3 flex flex-wrap gap-2">
        {items.map((item) => (
          <li
            key={item}
            className="inline-flex min-h-11 items-center rounded-full bg-[var(--accent)] px-4 text-sm font-medium text-white shadow-[0_10px_24px_-16px_rgba(11,79,73,0.7)]"
          >
            Pack: {item}
          </li>
        ))}
      </ul>
    </section>
  );
}
