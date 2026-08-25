import type { WeatherData } from "@/types/weather";
import { WeatherIcon } from "@/components/WeatherIcon";

interface WeatherSummaryProps {
  weather: WeatherData;
  dateLabel: string;
}

export function WeatherSummary({ weather, dateLabel }: WeatherSummaryProps) {
  return (
    <section className="animate-fade-up" style={{ animationDelay: "60ms" }}>
      <p className="mb-6 text-sm tracking-wide text-[var(--ink-muted)]">
        {dateLabel}
      </p>

      <div className="flex items-start gap-4">
        <div className="min-w-0 flex-1">
          <div className="flex items-center gap-3">
            <p className="font-display text-7xl leading-none tracking-tight text-[var(--ink)] sm:text-8xl">
              {weather.temperature}°
            </p>
            <WeatherIcon
              code={weather.conditionCode}
              className="mt-2 h-9 w-9 text-[var(--accent)] opacity-90"
            />
          </div>
          <p className="mt-3 text-base text-[var(--ink-soft)]">
            Feels like {weather.feelsLike}°
          </p>
          <p className="mt-1 text-sm text-[var(--ink-muted)]">
            {weather.condition}
            <span className="mx-1.5 text-[var(--ink-faint)]">•</span>
            Wind {weather.windSpeed} mph
          </p>
        </div>
      </div>

      <dl className="mt-6 grid grid-cols-3 gap-3 text-sm sm:max-w-md">
        <div>
          <dt className="text-[var(--ink-faint)]">High / Low</dt>
          <dd className="mt-0.5 text-[var(--ink-soft)]">
            {weather.high}° / {weather.low}°
          </dd>
        </div>
        <div>
          <dt className="text-[var(--ink-faint)]">Humidity</dt>
          <dd className="mt-0.5 text-[var(--ink-soft)]">{weather.humidity}%</dd>
        </div>
        <div>
          <dt className="text-[var(--ink-faint)]">Rain</dt>
          <dd className="mt-0.5 text-[var(--ink-soft)]">
            {weather.precipitationChance}%
          </dd>
        </div>
      </dl>
    </section>
  );
}
