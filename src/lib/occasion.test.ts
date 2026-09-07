import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { applyOccasionContext } from "./occasion.ts";
import type { WeatherData } from "../types/weather.ts";

const hotWeather: WeatherData = {
  locationName: "Test",
  temperature: 88,
  feelsLike: 90,
  condition: "Clear",
  conditionCode: "clear",
  high: 92,
  low: 74,
  humidity: 55,
  windSpeed: 6,
  precipitationChance: 5,
  hourly: [],
  units: "imperial",
  fetchedAt: new Date().toISOString(),
};

const rainyHot: WeatherData = {
  ...hotWeather,
  precipitationChance: 60,
  condition: "Rain",
  conditionCode: "rain",
};

const coolWeather: WeatherData = {
  ...hotWeather,
  temperature: 58,
  feelsLike: 55,
  high: 62,
  low: 48,
  precipitationChance: 10,
};

describe("occasion remapping", () => {
  it("everyday leaves casual shorts intact", () => {
    const mapped = applyOccasionContext({
      occasion: "everyday",
      items: ["Linen shirt", "Shorts", "Sneakers"],
      title: "Linen / Shorts",
      weather: hotWeather,
      reasons: [],
    });
    assert.ok(mapped.items.includes("Shorts"));
  });

  it("office never keeps shorts as a main piece on hot days", () => {
    const reasons: string[] = [];
    const mapped = applyOccasionContext({
      occasion: "office",
      items: ["Linen shirt", "Shorts", "Sneakers"],
      title: "Linen / Shorts",
      weather: hotWeather,
      reasons,
    });
    assert.ok(!mapped.items.some((i) => /shorts/i.test(i)));
    assert.ok(mapped.items.some((i) => /button|shirt/i.test(i)));
    assert.ok(mapped.items.some((i) => /chino|trouser|pant/i.test(i)));
    assert.ok(reasons.some((r) => /offices often run cool/i.test(r)));
  });

  it("meeting/formal stay polished and ban sandals", () => {
    const mapped = applyOccasionContext({
      occasion: "meeting",
      items: ["Athletic tee", "Shorts", "Sandals"],
      title: "Short Sleeve",
      weather: coolWeather,
      reasons: [],
    });
    assert.ok(!mapped.items.some((i) => /shorts|sandal/i.test(i)));
    assert.ok(mapped.items.some((i) => /dress|button|trouser|chino|shirt/i.test(i)));
  });

  it("rainy corporate days add professional rain handling", () => {
    const reasons: string[] = [];
    const mapped = applyOccasionContext({
      occasion: "office",
      items: ["Casual button-up", "Chinos", "Suede loafers", "Rain jacket"],
      title: "Button-up",
      weather: rainyHot,
      reasons,
    });
    assert.ok(mapped.items.some((i) => /umbrella|raincoat|trench|rain/i.test(i)));
    assert.ok(!mapped.items.some((i) => /suede/i.test(i)));
    assert.ok(reasons.some((r) => /professional|umbrella|raincoat/i.test(r)));
  });

  it("remote prioritizes comfort", () => {
    const mapped = applyOccasionContext({
      occasion: "remote",
      items: ["Dress shirt", "Dress trousers", "Leather shoes"],
      title: "Dress shirt",
      weather: coolWeather,
      reasons: [],
    });
    assert.ok(
      mapped.items.some((i) => /sweater|tee|jogger|slipper|sneaker|hoodie/i.test(i)),
    );
    assert.ok(
      !mapped.items.some((i) => /dress shirt|dress trousers|leather shoes/i.test(i)),
    );
  });

  it("going out slightly styles without dropping rain pieces", () => {
    const mapped = applyOccasionContext({
      occasion: "going_out",
      items: ["Athletic tee", "Jeans", "Sneakers", "Rain jacket"],
      title: "Short Sleeve",
      weather: coolWeather,
      reasons: [],
    });
    assert.ok(mapped.items.some((i) => /rain/i.test(i)));
    assert.ok(mapped.items.some((i) => /shirt|sneaker|jean|chino/i.test(i)));
  });
});
