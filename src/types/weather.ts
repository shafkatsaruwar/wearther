export interface HourlyWeather {
  time: string;
  temperature: number;
  precipitationChance: number;
  condition: string;
  feelsLike: number;
}

export interface WeatherData {
  locationName: string;
  temperature: number;
  feelsLike: number;
  condition: string;
  conditionCode: string;
  high: number;
  low: number;
  humidity: number;
  windSpeed: number;
  precipitationChance: number;
  hourly: HourlyWeather[];
  units: "imperial" | "metric";
  fetchedAt: string;
  isMock?: boolean;
}

export interface LocationResult {
  id: string;
  name: string;
  region?: string;
  country: string;
  latitude: number;
  longitude: number;
}

export interface WeatherProvider {
  getWeather(lat: number, lon: number, locationName: string): Promise<WeatherData>;
  searchLocations(query: string): Promise<LocationResult[]>;
}
