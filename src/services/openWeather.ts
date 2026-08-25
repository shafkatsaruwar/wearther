import type {
  HourlyWeather,
  LocationResult,
  WeatherData,
  WeatherProvider,
} from "@/types/weather";

/**
 * OpenWeatherMap provider (One Call + Geocoding).
 *
 * Set in `.env.local`:
 *   WEATHER_PROVIDER=openweather
 *   OPENWEATHER_API_KEY=your_key_here
 *
 * Docs: https://openweathermap.org/api
 */

function mapCondition(main: string): { label: string; key: string } {
  const m = main.toLowerCase();
  if (m.includes("thunder")) return { label: "Thunderstorm", key: "storm" };
  if (m.includes("drizzle")) return { label: "Drizzle", key: "rain" };
  if (m.includes("rain")) return { label: "Rain", key: "rain" };
  if (m.includes("snow")) return { label: "Snow", key: "snow" };
  if (m.includes("mist") || m.includes("fog") || m.includes("haze"))
    return { label: "Foggy", key: "fog" };
  if (m.includes("cloud")) return { label: "Cloudy", key: "cloudy" };
  if (m.includes("clear")) return { label: "Clear", key: "clear" };
  return { label: main, key: "cloudy" };
}

export function openWeatherProvider(apiKey: string): WeatherProvider {
  return {
    async getWeather(lat, lon, locationName) {
      // One Call API 3.0 — swap path if your plan uses 2.5
      const params = new URLSearchParams({
        lat: String(lat),
        lon: String(lon),
        units: "imperial",
        exclude: "minutely,alerts",
        appid: apiKey,
      });

      const res = await fetch(
        `https://api.openweathermap.org/data/3.0/onecall?${params}`,
      );

      if (!res.ok) {
        throw new Error(`OpenWeather forecast failed: ${res.status}`);
      }

      const data = (await res.json()) as {
        current: {
          temp: number;
          feels_like: number;
          humidity: number;
          wind_speed: number;
          weather: Array<{ main: string; description: string }>;
        };
        hourly: Array<{
          dt: number;
          temp: number;
          feels_like: number;
          pop: number;
          weather: Array<{ main: string }>;
        }>;
        daily: Array<{
          temp: { max: number; min: number };
          pop: number;
        }>;
      };

      const { label, key } = mapCondition(data.current.weather[0]?.main ?? "Clouds");
      const now = Date.now() / 1000;
      const targetHours = [15, 18, 21];

      const hourly: HourlyWeather[] = [];
      for (const th of targetHours) {
        const match = data.hourly.find((h) => {
          const d = new Date(h.dt * 1000);
          return h.dt > now && d.getHours() === th;
        });
        if (!match) continue;
        const c = mapCondition(match.weather[0]?.main ?? "Clouds");
        hourly.push({
          time: new Date(match.dt * 1000).toISOString(),
          temperature: Math.round(match.temp),
          feelsLike: Math.round(match.feels_like),
          precipitationChance: Math.round(match.pop * 100),
          condition: c.label,
        });
      }

      return {
        locationName,
        temperature: Math.round(data.current.temp),
        feelsLike: Math.round(data.current.feels_like),
        condition: label,
        conditionCode: key,
        high: Math.round(data.daily[0].temp.max),
        low: Math.round(data.daily[0].temp.min),
        humidity: Math.round(data.current.humidity),
        windSpeed: Math.round(data.current.wind_speed),
        precipitationChance: Math.round((data.daily[0]?.pop ?? 0) * 100),
        hourly,
        units: "imperial",
        fetchedAt: new Date().toISOString(),
      } satisfies WeatherData;
    },

    async searchLocations(query) {
      const params = new URLSearchParams({
        q: query,
        limit: "6",
        appid: apiKey,
      });

      const res = await fetch(
        `https://api.openweathermap.org/geo/1.0/direct?${params}`,
      );

      if (!res.ok) {
        throw new Error(`OpenWeather geocoding failed: ${res.status}`);
      }

      const data = (await res.json()) as Array<{
        name: string;
        state?: string;
        country: string;
        lat: number;
        lon: number;
      }>;

      return data.map(
        (r, i): LocationResult => ({
          id: `${r.name}-${r.lat}-${r.lon}-${i}`,
          name: r.name,
          region: r.state,
          country: r.country,
          latitude: r.lat,
          longitude: r.lon,
        }),
      );
    },
  };
}
