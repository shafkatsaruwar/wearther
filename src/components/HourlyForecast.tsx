import type { ComfortPreference } from "@/types/outfit";
import type { HourlyWeather } from "@/types/weather";
import { recommendForHour } from "@/lib/recommendOutfit";
import { displayTemp } from "@/lib/units";

interface HourlyForecastProps {
  hours: HourlyWeather[];
  comfort?: ComfortPreference;
}

export function HourlyForecast({ hours, comfort }: HourlyForecastProps) {
  if (!hours.length) return null;

  const units = comfort?.units ?? "fahrenheit";

  return (
    <section
      className="animate-fade-up"
      style={{ animationDelay: "220ms" }}
      aria-labelledby="later-today"
    >
      <h3
        id="later-today"
        className="text-[11px] font-medium uppercase tracking-[0.22em] text-[var(--ink-faint)]"
      >
        Later Today
      </h3>

      <ul className="mt-4 flex gap-2 overflow-x-auto pb-1 sm:gap-3">
        {hours.map((hour) => {
          const tip = recommendForHour(hour, comfort);
          const label = new Date(hour.time).toLocaleTimeString([], {
            hour: "numeric",
          });

          return (
            <li
              key={hour.time}
              className="min-w-[5.75rem] flex-1 rounded-2xl bg-[var(--surface)] px-3 py-3"
            >
              <p className="text-xs text-[var(--ink-muted)]">{label}</p>
              <p className="mt-1 text-lg font-medium text-[var(--ink)]">
                {displayTemp(hour.temperature, units)}°
              </p>
              <p className="mt-1 text-[11px] leading-snug text-[var(--ink-faint)]">
                {tip}
              </p>
            </li>
          );
        })}
      </ul>
    </section>
  );
}
