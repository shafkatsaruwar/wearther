const ONBOARDING_KEY = "wearther:onboarding-complete";
const LOCATION_KEY = "wearther:selected-location";

import type { LocationResult } from "@/types/weather";
import { DEFAULT_CITY } from "@/services/weather";

export function loadSavedLocation(): LocationResult {
  if (typeof window === "undefined") return DEFAULT_CITY;
  try {
    const raw = localStorage.getItem(LOCATION_KEY);
    if (!raw) return DEFAULT_CITY;
    return JSON.parse(raw) as LocationResult;
  } catch {
    return DEFAULT_CITY;
  }
}

export function saveLocation(location: LocationResult): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(LOCATION_KEY, JSON.stringify(location));
}

export function hasCompletedOnboarding(): boolean {
  if (typeof window === "undefined") return true;
  if (localStorage.getItem(ONBOARDING_KEY) != null) {
    return localStorage.getItem(ONBOARDING_KEY) === "true";
  }
  // Existing installs that already chose a city skip first-run.
  return localStorage.getItem(LOCATION_KEY) != null;
}

export function setOnboardingComplete(complete = true): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(ONBOARDING_KEY, complete ? "true" : "false");
}
