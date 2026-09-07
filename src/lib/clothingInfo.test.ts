import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { getClothingInfo } from "./clothingInfo.ts";
import type { WeatherData } from "../types/weather.ts";

const sampleWeather: WeatherData = {
  locationName: "Boston",
  temperature: 68,
  feelsLike: 66,
  condition: "Cloudy",
  conditionCode: "cloudy",
  high: 72,
  low: 58,
  humidity: 78,
  windSpeed: 14,
  precipitationChance: 55,
  hourly: [],
  units: "imperial",
  fetchedAt: new Date().toISOString(),
};

describe("getClothingInfo", () => {
  it("maps oxford shirt copy", () => {
    const info = getClothingInfo("Oxford shirt");
    assert.equal(info.subtitle, "Textured button-up");
    assert.match(info.whatItIs, /button-up shirt/i);
    assert.match(info.whyToday, /light coverage/i);
  });

  it("uses humidity-aware whyToday for linen", () => {
    const info = getClothingInfo("Linen shirt", sampleWeather);
    assert.equal(info.subtitle, "Light breathable fabric");
    assert.match(info.whyToday, /Humidity is high/i);
  });

  it("maps rain shell with precip-aware copy", () => {
    const info = getClothingInfo("Rain shell", sampleWeather);
    assert.equal(info.subtitle, "Thin waterproof layer");
    assert.match(info.whyToday, /Rain chances are high/i);
  });

  it("maps chinos, overshirt, scarf, and sneakers", () => {
    assert.equal(getClothingInfo("Chinos").subtitle, "Clean casual pants");
    assert.equal(
      getClothingInfo("Overshirt").subtitle,
      "Light jacket-like shirt",
    );
    assert.equal(getClothingInfo("Scarf").subtitle, "Warm neck layer");
    assert.equal(
      getClothingInfo("Sneakers").subtitle,
      "Everyday walking shoes",
    );
  });

  it("returns safe fallback for unknown items", () => {
    const info = getClothingInfo("Mystery wrap");
    assert.equal(info.subtitle, "Recommended layer");
    assert.match(info.whatItIs, /suggested clothing item/i);
    assert.match(info.whyToday, /temperature, wind, rain/i);
  });

  it("covers formal and athletic vocabulary", () => {
    assert.equal(
      getClothingInfo("Dress shirt").subtitle,
      "Polished collared shirt",
    );
    assert.equal(
      getClothingInfo("Breathable athletic tee").subtitle,
      "Breathable athletic top",
    );
    assert.equal(getClothingInfo("Joggers").subtitle, "Soft athletic pants");
  });
});
