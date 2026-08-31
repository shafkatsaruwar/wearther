import { searchCities } from "@/services/weather";
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const query = request.nextUrl.searchParams.get("q") ?? "";

  if (query.trim().length < 2) {
    return NextResponse.json([]);
  }

  try {
    const results = await searchCities(query);
    return NextResponse.json(results);
  } catch {
    return NextResponse.json(
      { error: "Location search failed" },
      { status: 502 },
    );
  }
}
