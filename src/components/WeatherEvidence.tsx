import type { TempUnits } from "@/types/outfit";
import type { WeatherData } from "@/types/weather";
import { WeatherIcon } from "@/components/WeatherIcon";
import { displayTemp, windLabel } from "@/lib/units";

interface WeatherEvidenceProps {
  weather: WeatherData;
  units: TempUnits;
}

export function WeatherEvidence({ weather, units }: WeatherEvidenceProps) {
  return (
    <section
      className="animate-fade-up rounded-[1.75rem] bg-[var(--surface)] px-5 py-5 ring-1 ring-[var(--line)]"
      style={{ animationDelay: "160ms" }}
      aria-label="Weather evidence"
    >
      <div className="flex items-start gap-3">
        <p className="font-display text-5xl leading-none tracking-tight text-[var(--ink)]">
          {displayTemp(weather.temperature, units)}°
        </p>
        <div className="min-w-0 flex-1 pt-1">
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-medium text-[var(--ink)]">
              {weather.condition}
            </p>
            <WeatherIcon
              code={weather.conditionCode}
              className="h-6 w-6 text-[var(--accent)] opacity-90"
            />
          </div>
          <p className="mt-1 text-sm text-[var(--ink-muted)]">
            Feels {displayTemp(weather.feelsLike, units)}° · Wind{" "}
            {windLabel(weather.windSpeed, units)}
          </p>
        </div>
      </div>

      <dl className="mt-4 grid grid-cols-3 gap-2">
        <div className="rounded-[1.25rem] bg-[var(--fit-surface)] px-3 py-3 ring-1 ring-[var(--line)]">
          <dt className="text-[10px] font-semibold uppercase tracking-[0.12em] text-[var(--ink-muted)]">
            High / Low
          </dt>
          <dd className="mt-1 text-sm font-medium text-[var(--ink)]">
            {displayTemp(weather.high, units)}° /{" "}
            {displayTemp(weather.low, units)}°
          </dd>
        </div>
        <div className="rounded-[1.25rem] bg-[var(--fit-surface)] px-3 py-3 ring-1 ring-[var(--line)]">
          <dt className="text-[10px] font-semibold uppercase tracking-[0.12em] text-[var(--ink-muted)]">
            Humidity
          </dt>
          <dd className="mt-1 text-sm font-medium text-[var(--ink)]">
            {weather.humidity}%
          </dd>
        </div>
        <div className="rounded-[1.25rem] bg-[var(--fit-surface)] px-3 py-3 ring-1 ring-[var(--line)]">
          <dt className="text-[10px] font-semibold uppercase tracking-[0.12em] text-[var(--ink-muted)]">
            Rain
          </dt>
          <dd className="mt-1 text-sm font-medium text-[var(--ink)]">
            {weather.precipitationChance}%
          </dd>
        </div>
      </dl>
    </section>
  );
}
