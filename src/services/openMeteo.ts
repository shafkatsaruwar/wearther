import type {
  HourlyWeather,
  LocationResult,
  WeatherData,
  WeatherProvider,
} from "@/types/weather";

/** WMO weather interpretation codes → human labels */
function conditionFromCode(code: number): { label: string; key: string } {
  if (code === 0) return { label: "Clear", key: "clear" };
  if (code <= 3) return { label: "Partly Cloudy", key: "partly-cloudy" };
  if (code <= 48) return { label: "Foggy", key: "fog" };
  if (code <= 57) return { label: "Drizzle", key: "rain" };
  if (code <= 67) return { label: "Rain", key: "rain" };
  if (code <= 77) return { label: "Snow", key: "snow" };
  if (code <= 82) return { label: "Showers", key: "rain" };
  if (code <= 86) return { label: "Snow Showers", key: "snow" };
  if (code <= 99) return { label: "Thunderstorm", key: "storm" };
  return { label: "Cloudy", key: "cloudy" };
}

interface OpenMeteoForecast {
  current: {
    temperature_2m: number;
    apparent_temperature: number;
    relative_humidity_2m: number;
    weather_code: number;
    wind_speed_10m: number;
  };
  daily: {
    temperature_2m_max: number[];
    temperature_2m_min: number[];
    precipitation_probability_max: number[];
  };
  hourly: {
    time: string[];
    temperature_2m: number[];
    apparent_temperature: number[];
    precipitation_probability: number[];
    weather_code: number[];
  };
}

function pickLaterHours(hourly: OpenMeteoForecast["hourly"]): HourlyWeather[] {
  const now = Date.now();
  const targetHours = [15, 18, 21];
  const results: HourlyWeather[] = [];

  for (const target of targetHours) {
    const matchIndex = hourly.time.findIndex((iso) => {
      const d = new Date(iso);
      return d.getTime() > now && d.getHours() === target;
    });

    if (matchIndex === -1) continue;

    const code = hourly.weather_code[matchIndex];
    const { label } = conditionFromCode(code);
    results.push({
      time: new Date(hourly.time[matchIndex]).toISOString(),
      temperature: Math.round(hourly.temperature_2m[matchIndex]),
      feelsLike: Math.round(hourly.apparent_temperature[matchIndex]),
      precipitationChance: hourly.precipitation_probability[matchIndex] ?? 0,
      condition: label,
    });
  }

  // Fallback: next 3 slots at ~3h intervals
  if (results.length === 0) {
    const future = hourly.time
      .map((iso, i) => ({ iso, i, t: new Date(iso).getTime() }))
      .filter((x) => x.t > now)
      .filter((_, idx) => idx % 3 === 2)
      .slice(0, 3);

    for (const f of future) {
      const { label } = conditionFromCode(hourly.weather_code[f.i]);
      results.push({
        time: new Date(f.iso).toISOString(),
        temperature: Math.round(hourly.temperature_2m[f.i]),
        feelsLike: Math.round(hourly.apparent_temperature[f.i]),
        precipitationChance: hourly.precipitation_probability[f.i] ?? 0,
        condition: label,
      });
    }
  }

  return results;
}

export const openMeteoProvider: WeatherProvider = {
  async getWeather(lat, lon, locationName) {
    const params = new URLSearchParams({
      latitude: String(lat),
      longitude: String(lon),
      current:
        "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m",
      hourly:
        "temperature_2m,apparent_temperature,precipitation_probability,weather_code",
      daily:
        "temperature_2m_max,temperature_2m_min,precipitation_probability_max",
      temperature_unit: "fahrenheit",
      wind_speed_unit: "mph",
      timezone: "auto",
      forecast_days: "1",
    });

    const res = await fetch(`https://api.open-meteo.com/v1/forecast?${params}`, {
      next: { revalidate: 600 },
    });

    if (!res.ok) {
      throw new Error(`Open-Meteo forecast failed: ${res.status}`);
    }

    const data = (await res.json()) as OpenMeteoForecast;
    const { label, key } = conditionFromCode(data.current.weather_code);

    return {
      locationName,
      temperature: Math.round(data.current.temperature_2m),
      feelsLike: Math.round(data.current.apparent_temperature),
      condition: label,
      conditionCode: key,
      high: Math.round(data.daily.temperature_2m_max[0]),
      low: Math.round(data.daily.temperature_2m_min[0]),
      humidity: Math.round(data.current.relative_humidity_2m),
      windSpeed: Math.round(data.current.wind_speed_10m),
      precipitationChance: data.daily.precipitation_probability_max[0] ?? 0,
      hourly: pickLaterHours(data.hourly),
      units: "imperial",
      fetchedAt: new Date().toISOString(),
    } satisfies WeatherData;
  },

  async searchLocations(query) {
    const params = new URLSearchParams({
      name: query,
      count: "6",
      language: "en",
      format: "json",
    });

    const res = await fetch(
      `https://geocoding-api.open-meteo.com/v1/search?${params}`,
    );

    if (!res.ok) {
      throw new Error(`Open-Meteo geocoding failed: ${res.status}`);
    }

    const data = (await res.json()) as {
      results?: Array<{
        id: number;
        name: string;
        admin1?: string;
        country: string;
        latitude: number;
        longitude: number;
      }>;
    };

    return (data.results ?? []).map(
      (r): LocationResult => ({
        id: String(r.id),
        name: r.name,
        region: r.admin1,
        country: r.country,
        latitude: r.latitude,
        longitude: r.longitude,
      }),
    );
  },
};
