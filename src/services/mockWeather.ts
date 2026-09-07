import type {
  HourlyWeather,
  LocationResult,
  WeatherData,
  WeatherProvider,
} from "@/types/weather";

const MOCK_CITIES: LocationResult[] = [
  {
    id: "boston-us",
    name: "Boston",
    region: "Massachusetts",
    country: "United States",
    latitude: 42.3601,
    longitude: -71.0589,
  },
  {
    id: "new-york-us",
    name: "New York",
    region: "New York",
    country: "United States",
    latitude: 40.7128,
    longitude: -74.006,
  },
  {
    id: "san-francisco-us",
    name: "San Francisco",
    region: "California",
    country: "United States",
    latitude: 37.7749,
    longitude: -122.4194,
  },
  {
    id: "chicago-us",
    name: "Chicago",
    region: "Illinois",
    country: "United States",
    latitude: 41.8781,
    longitude: -87.6298,
  },
  {
    id: "london-gb",
    name: "London",
    region: "England",
    country: "United Kingdom",
    latitude: 51.5074,
    longitude: -0.1278,
  },
  {
    id: "tokyo-jp",
    name: "Tokyo",
    region: "Tokyo",
    country: "Japan",
    latitude: 35.6762,
    longitude: 139.6503,
  },
  {
    id: "miami-us",
    name: "Miami",
    region: "Florida",
    country: "United States",
    latitude: 25.7617,
    longitude: -80.1918,
  },
  {
    id: "seattle-us",
    name: "Seattle",
    region: "Washington",
    country: "United States",
    latitude: 47.6062,
    longitude: -122.3321,
  },
];

function buildHourly(baseTemp: number, baseFeels: number): HourlyWeather[] {
  const now = new Date();
  const slots = [15, 18, 21];
  const offsets = [7, 0, -6];

  return slots.map((hour, i) => {
    const time = new Date(now);
    time.setHours(hour, 0, 0, 0);
    if (time.getTime() < now.getTime()) {
      time.setDate(time.getDate() + 1);
    }
    const temperature = Math.round(baseTemp + offsets[i]);
    return {
      time: time.toISOString(),
      temperature,
      feelsLike: Math.round(baseFeels + offsets[i] - 1),
      precipitationChance: i === 2 ? 35 : 15,
      condition: i === 2 ? "Cloudy" : "Partly Cloudy",
    };
  });
}

function mockForCity(name: string): WeatherData {
  // Deterministic-ish demo profiles by city name
  const profiles: Record<
    string,
    Omit<WeatherData, "locationName" | "hourly" | "fetchedAt" | "units">
  > = {
    Boston: {
      temperature: 61,
      feelsLike: 57,
      condition: "Cloudy",
      conditionCode: "cloudy",
      high: 67,
      low: 52,
      humidity: 68,
      windSpeed: 14,
      precipitationChance: 20,
    },
    Miami: {
      temperature: 88,
      feelsLike: 94,
      condition: "Humid",
      conditionCode: "partly-cloudy",
      high: 91,
      low: 79,
      humidity: 82,
      windSpeed: 8,
      precipitationChance: 40,
    },
    Chicago: {
      temperature: 38,
      feelsLike: 30,
      condition: "Windy",
      conditionCode: "windy",
      high: 42,
      low: 28,
      humidity: 55,
      windSpeed: 22,
      precipitationChance: 10,
    },
    London: {
      temperature: 54,
      feelsLike: 50,
      condition: "Light Rain",
      conditionCode: "rain",
      high: 58,
      low: 46,
      humidity: 78,
      windSpeed: 12,
      precipitationChance: 70,
    },
    "San Francisco": {
      temperature: 64,
      feelsLike: 60,
      condition: "Foggy",
      conditionCode: "fog",
      high: 68,
      low: 55,
      humidity: 72,
      windSpeed: 16,
      precipitationChance: 5,
    },
  };

  const base =
    profiles[name] ??
    ({
      temperature: 72,
      feelsLike: 70,
      condition: "Partly Cloudy",
      conditionCode: "partly-cloudy",
      high: 76,
      low: 62,
      humidity: 55,
      windSpeed: 9,
      precipitationChance: 10,
    } as const);

  return {
    locationName: name,
    ...base,
    units: "imperial",
    hourly: buildHourly(base.temperature, base.feelsLike),
    fetchedAt: new Date().toISOString(),
    isMock: true,
  };
}

export const mockProvider: WeatherProvider = {
  async getWeather(_lat, _lon, locationName) {
    // Simulate network latency for a realistic UI
    await new Promise((r) => setTimeout(r, 280));
    return mockForCity(locationName);
  },

  async searchLocations(query) {
    const q = query.toLowerCase();
    return MOCK_CITIES.filter(
      (c) =>
        c.name.toLowerCase().includes(q) ||
        c.region?.toLowerCase().includes(q) ||
        c.country.toLowerCase().includes(q),
    );
  },
};
