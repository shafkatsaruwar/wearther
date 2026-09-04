import type { TempUnits } from "@/types/outfit";

/** Weather pipeline stores imperial (°F, mph). Convert for display only. */
export function displayTemp(fahrenheit: number, units: TempUnits): number {
  if (units === "celsius") {
    return Math.round(((fahrenheit - 32) * 5) / 9);
  }
  return Math.round(fahrenheit);
}

export function tempSymbol(units: TempUnits): string {
  return units === "celsius" ? "C" : "F";
}

export function windLabel(mph: number, units: TempUnits): string {
  if (units === "celsius") {
    return `${Math.round(mph * 1.609)} km/h`;
  }
  return `${Math.round(mph)} mph`;
}
