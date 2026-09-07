import { readFile } from "node:fs/promises";
import path from "node:path";
import { NextResponse } from "next/server";
import { mergeRemoteConfig } from "@/lib/remoteConfig";

/**
 * GET /api/config — live remote config for web + iOS clients.
 * Source of truth: `public/remote-config.json` (edit + deploy = OTA knobs).
 */
export async function GET() {
  try {
    const filePath = path.join(process.cwd(), "public", "remote-config.json");
    const raw = await readFile(filePath, "utf8");
    const parsed: unknown = JSON.parse(raw);
    const config = mergeRemoteConfig(parsed);
    return NextResponse.json(config, {
      headers: {
        "Cache-Control": "public, max-age=60, stale-while-revalidate=300",
      },
    });
  } catch {
    return NextResponse.json(mergeRemoteConfig(null), {
      headers: {
        "Cache-Control": "public, max-age=60",
      },
    });
  }
}
