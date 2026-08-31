import { getWeatherForLocation } from "@/services/weather";
import type { LocationResult } from "@/types/weather";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;

  const lat = Number(searchParams.get("lat"));
  const lon = Number(searchParams.get("lon"));
  const name = searchParams.get("name");
  const id = searchParams.get("id");

  if (!Number.isFinite(lat) || !Number.isFinite(lon) || !name || !id) {
    return NextResponse.json(
      { error: "Missing or invalid lat, lon, name, or id" },
      { status: 400 },
    );
  }

  const location: LocationResult = {
    id,
    name,
    latitude: lat,
    longitude: lon,
    country: searchParams.get("country") ?? "",
    region: searchParams.get("region") ?? undefined,
  };

  try {
    const weather = await getWeatherForLocation(location);
    return NextResponse.json(weather);
  } catch {
    return NextResponse.json(
      { error: "Weather request failed" },
      { status: 502 },
    );
  }
}
