/**
 * Weather service abstraction.
 *
 * Configure a provider via env (server-side):
 *   WEATHER_PROVIDER=mock | open-meteo | openweather
 *   OPENWEATHER_API_KEY=your_key_here
 *
 * Default: open-meteo (free, no key). Falls back to mock on failure.
 * Set provider to "mock" for offline demos.
 *
 * Insert your OpenWeatherMap API key in `.env.local`:
 *   WEATHER_PROVIDER=openweather
 *   OPENWEATHER_API_KEY=xxxxxxxx
 */

import type { LocationResult, WeatherData, WeatherProvider } from "@/types/weather";
import { mockProvider } from "@/services/mockWeather";
import { openMeteoProvider } from "@/services/openMeteo";
import { openWeatherProvider } from "@/services/openWeather";

export type WeatherProviderName = "mock" | "open-meteo" | "openweather";

export const DEFAULT_CITY: LocationResult = {
  id: "boston-us",
  name: "Boston",
  region: "Massachusetts",
  country: "United States",
  latitude: 42.3601,
  longitude: -71.0589,
};

function resolveProvider(): WeatherProvider {
  const name = (process.env.WEATHER_PROVIDER ??
    process.env.NEXT_PUBLIC_WEATHER_PROVIDER ??
    "open-meteo") as WeatherProviderName;

  if (name === "mock") return mockProvider;

  if (name === "openweather") {
    const key =
      process.env.OPENWEATHER_API_KEY ??
      process.env.NEXT_PUBLIC_OPENWEATHER_API_KEY;
    if (!key) {
      console.warn(
        "[Wearther] OPENWEATHER_API_KEY is not set — using mock weather.",
      );
      return mockProvider;
    }
    return openWeatherProvider(key);
  }

  return openMeteoProvider;
}

export async function getWeatherForLocation(
  location: LocationResult,
): Promise<WeatherData> {
  const provider = resolveProvider();
  try {
    return await provider.getWeather(
      location.latitude,
      location.longitude,
      location.name,
    );
  } catch (error) {
    console.warn("[Wearther] Weather fetch failed, using mock data.", error);
    return mockProvider.getWeather(
      location.latitude,
      location.longitude,
      location.name,
    );
  }
}

export async function searchCities(query: string): Promise<LocationResult[]> {
  const trimmed = query.trim();
  if (trimmed.length < 2) return [];

  const provider = resolveProvider();
  try {
    return await provider.searchLocations(trimmed);
  } catch (error) {
    console.warn("[Wearther] Location search failed, using mock cities.", error);
    return mockProvider.searchLocations(trimmed);
  }
}

export type { WeatherData, LocationResult, HourlyWeather } from "@/types/weather";
