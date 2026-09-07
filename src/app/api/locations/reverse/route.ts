import { reverseGeocode } from "@/services/weather";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const lat = Number(request.nextUrl.searchParams.get("lat"));
  const lon = Number(request.nextUrl.searchParams.get("lon"));

  if (!Number.isFinite(lat) || !Number.isFinite(lon)) {
    return NextResponse.json({ error: "lat and lon required" }, { status: 400 });
  }

  try {
    const place = await reverseGeocode(lat, lon);
    return NextResponse.json(place);
  } catch {
    return NextResponse.json(
      { error: "Reverse geocode failed" },
      { status: 502 },
    );
  }
}
