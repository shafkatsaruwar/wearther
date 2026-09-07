import assert from "node:assert/strict";
import { describe, it, afterEach } from "node:test";
import {
  DEFAULT_REMOTE_CONFIG,
  __setRemoteConfigForTests,
  getRemoteConfig,
  mergeRemoteConfig,
} from "./remoteConfig.ts";

describe("remoteConfig", () => {
  afterEach(() => {
    __setRemoteConfigForTests(null);
  });

  it("merges partial thresholds over defaults", () => {
    const merged = mergeRemoteConfig({
      thresholds: { highRainChance: 30, strongWindMph: 20 },
      copy: { feedback: { too_cold: "Bundle more tomorrow." } },
    });
    assert.equal(merged.thresholds.highRainChance, 30);
    assert.equal(merged.thresholds.strongWindMph, 20);
    assert.equal(merged.thresholds.packRainChance, 40);
    assert.equal(merged.copy.feedback.too_cold, "Bundle more tomorrow.");
    assert.equal(
      merged.copy.feedback.too_hot,
      DEFAULT_REMOTE_CONFIG.copy.feedback.too_hot,
    );
  });

  it("rejects invalid temp band lengths", () => {
    const merged = mergeRemoteConfig({
      thresholds: { tempBandsF: [90, 80] },
    });
    assert.deepEqual(
      merged.thresholds.tempBandsF,
      DEFAULT_REMOTE_CONFIG.thresholds.tempBandsF,
    );
  });

  it("applies test overrides via setter", () => {
    __setRemoteConfigForTests({
      ...DEFAULT_REMOTE_CONFIG,
      thresholds: { ...DEFAULT_REMOTE_CONFIG.thresholds, packRainChance: 5 },
      copy: {
        ...DEFAULT_REMOTE_CONFIG.copy,
        feedback: {
          too_cold: "Warmer tomorrow.",
          too_hot: "Cooler tomorrow.",
          perfect: "Locked in.",
        },
      },
    });
    assert.equal(getRemoteConfig().thresholds.packRainChance, 5);
    assert.equal(getRemoteConfig().copy.feedback.too_cold, "Warmer tomorrow.");
  });

  it("keeps flags defaults when omitted", () => {
    const merged = mergeRemoteConfig({ version: 2 });
    assert.equal(merged.version, 2);
    assert.equal(merged.flags.enableOccasionPicker, true);
    assert.equal(merged.flags.enableTripPack, true);
  });
});
