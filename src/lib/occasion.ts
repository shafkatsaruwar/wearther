import type { OccasionContext, OutfitRecommendation } from "@/types/outfit";
import type { WeatherData } from "@/types/weather";

const STORAGE_KEY = "wearther:occasion-context";

export const DEFAULT_OCCASION: OccasionContext = "everyday";

export const OCCASION_OPTIONS: {
  id: OccasionContext;
  label: string;
  pill: string;
  hint: string;
}[] = [
  {
    id: "everyday",
    label: "Everyday",
    pill: "Everyday",
    hint: "Normal day — weather-first dressing.",
  },
  {
    id: "office",
    label: "Office",
    pill: "Office day",
    hint: "Corporate office — polished but practical.",
  },
  {
    id: "meeting",
    label: "Meeting",
    pill: "Meeting",
    hint: "Client day — more conservative and sharp.",
  },
  {
    id: "formal",
    label: "Formal",
    pill: "Formal",
    hint: "Presentation or formal work event.",
  },
  {
    id: "remote",
    label: "Remote",
    pill: "Remote",
    hint: "Work from home — comfort first, still weather-aware.",
  },
  {
    id: "going_out",
    label: "Going out",
    pill: "Going out",
    hint: "A bit more styled than Everyday.",
  },
];

export function occasionPillLabel(context: OccasionContext): string {
  return OCCASION_OPTIONS.find((o) => o.id === context)?.pill ?? "Everyday";
}

export function loadOccasionContext(): OccasionContext {
  if (typeof window === "undefined") return DEFAULT_OCCASION;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_OCCASION;
    return isOccasionContext(raw) ? raw : DEFAULT_OCCASION;
  } catch {
    return DEFAULT_OCCASION;
  }
}

export function saveOccasionContext(context: OccasionContext): void {
  if (typeof window === "undefined") return;
  localStorage.setItem(STORAGE_KEY, context);
}

export function isOccasionContext(v: unknown): v is OccasionContext {
  return (
    v === "everyday" ||
    v === "office" ||
    v === "meeting" ||
    v === "formal" ||
    v === "remote" ||
    v === "going_out"
  );
}

function isCorporate(context: OccasionContext): boolean {
  return context === "office" || context === "meeting" || context === "formal";
}

/**
 * Remap a weather+style outfit for today's occasion.
 * Pure — safe to unit test. Does not change warmth thresholds.
 */
export function applyOccasionContext({
  occasion,
  items,
  title,
  bringLater,
  weather,
  reasons,
}: {
  occasion: OccasionContext;
  items: string[];
  title: string;
  bringLater?: string;
  weather: WeatherData;
  reasons: string[];
}): Pick<OutfitRecommendation, "items" | "title" | "bringLater"> {
  if (occasion === "everyday") {
    return { items, title, bringLater };
  }

  const rainy = weather.precipitationChance >= 45;
  const hot = weather.feelsLike >= 76;
  const coolIndoor = weather.feelsLike >= 70;

  let nextItems = [...items];
  let nextTitle = title;
  let nextBring = bringLater;

  if (isCorporate(occasion)) {
    nextItems = nextItems.map((item) =>
      corporateItem(occasion, item, { rainy, hot }),
    );
    nextTitle = corporateTitle(occasion, nextTitle, { rainy, hot });

    // Never leave shorts / sandals as primary corporate pieces.
    nextItems = nextItems.filter(
      (i) => !/shorts|sandal|slide|flip.?flop/i.test(i),
    );
    if (!nextItems.some((i) => /chino|trouser|pant|skirt/i.test(i))) {
      nextItems.push(
        occasion === "formal" || occasion === "meeting"
          ? "Dress trousers"
          : "Lightweight chinos",
      );
    }
    if (!nextItems.some((i) => /shirt|button|blouse|knit/i.test(i))) {
      nextItems.unshift(
        hot
          ? occasion === "formal"
            ? "Breathable dress shirt"
            : "Breathable button-up"
          : occasion === "formal"
            ? "Dress shirt"
            : "Button-up",
      );
    }
    if (
      !nextItems.some((i) => /loafer|dress shoe|oxford|derby|boot/i.test(i))
    ) {
      nextItems.push(
        rainy
          ? "Water-resistant dress shoes"
          : occasion === "office"
            ? "Loafers or clean dress shoes"
            : "Leather dress shoes",
      );
    }

    // Indoor AC layer for warm office/meeting days.
    if (
      coolIndoor &&
      (occasion === "office" || occasion === "meeting") &&
      !nextItems.some((i) => /blazer|cardigan|sweater|jacket|coat/i.test(i))
    ) {
      nextBring =
        nextBring ??
        (occasion === "meeting"
          ? "Bring an unlined blazer for AC."
          : "Bring a light cardigan or unlined blazer for AC.");
      if (!/bring|layer|blazer|cardigan/i.test(nextTitle)) {
        nextTitle = `${nextTitle} + light layer`;
      }
    }

    if (rainy) {
      if (!nextItems.some((i) => /umbrella/i.test(i))) {
        nextItems.push("Umbrella");
      }
      if (!nextItems.some((i) => /rain|trench|waterproof/i.test(i))) {
        nextItems.push(
          occasion === "formal" ? "Tailored raincoat or trench" : "Clean raincoat",
        );
      }
      reasons.push(
        "Use an umbrella or clean raincoat so the outfit stays professional.",
      );
    }

    if (occasion === "office") {
      reasons.push(
        "Warm commute, but offices often run cool, so a light layer is worth bringing.",
      );
    } else if (occasion === "meeting" || occasion === "formal") {
      reasons.push(
        "This keeps the outfit polished while staying breathable for the weather.",
      );
    }
  } else if (occasion === "remote") {
    nextItems = nextItems.map((item) => remoteItem(item, weather.feelsLike));
    nextTitle = remoteTitle(nextTitle, weather.feelsLike);
    reasons.push("Remote day — comfort first, still weather-aware.");
  } else if (occasion === "going_out") {
    nextItems = nextItems.map(goingOutItem);
    nextTitle = goingOutTitle(nextTitle);
    reasons.push("Going out — a bit more styled, still practical for the weather.");
  }

  return {
    items: dedupe(nextItems),
    title: nextTitle,
    bringLater: nextBring,
  };
}

function corporateItem(
  occasion: OccasionContext,
  item: string,
  opts: { rainy: boolean; hot: boolean },
): string {
  const lower = item.toLowerCase();

  if (/shorts/.test(lower) && !/pants/.test(lower)) {
    return occasion === "formal" || occasion === "meeting"
      ? "Dress trousers"
      : "Lightweight chinos";
  }
  if (/sandal|slide|flip/.test(lower)) {
    return opts.rainy ? "Water-resistant dress shoes" : "Loafers";
  }
  if (/jean/.test(lower)) {
    return occasion === "formal" || occasion === "meeting"
      ? "Dress trousers"
      : "Chinos";
  }
  if (/jogger|sweat/.test(lower)) {
    return occasion === "formal" ? "Dress trousers" : "Chinos";
  }
  if (/hoodie|athletic tee|performance|training tee|tee\b|t-shirt/.test(lower)) {
    if (opts.hot) {
      return occasion === "formal"
        ? "Breathable dress shirt"
        : "Breathable button-up";
    }
    return occasion === "formal" ? "Dress shirt" : "Button-up";
  }
  if (/linen/.test(lower) && /shirt|sleeve/.test(lower)) {
    return opts.hot ? "Breathable button-up" : "Linen button-up";
  }
  if (/short sleeve/.test(lower)) {
    return opts.hot ? "Breathable button-up" : "Casual button-up";
  }
  if (/sneaker|running shoe/.test(lower)) {
    if (opts.rainy) return "Water-resistant dress shoes";
    return occasion === "office"
      ? "Loafers or clean dress shoes"
      : "Leather dress shoes";
  }
  if (/suede/.test(lower)) {
    return opts.rainy ? "Water-resistant dress shoes" : "Leather dress shoes";
  }
  if (/rain jacket|rain shell|packable rain/.test(lower)) {
    return occasion === "formal"
      ? "Tailored raincoat or trench"
      : "Clean raincoat";
  }
  if (/light jacket|overshirt/.test(lower) && !/rain|blazer/.test(lower)) {
    return occasion === "meeting" || occasion === "formal"
      ? "Unlined blazer"
      : "Unlined blazer or light cardigan";
  }
  return item;
}

function corporateTitle(
  occasion: OccasionContext,
  title: string,
  opts: { rainy: boolean; hot: boolean },
): string {
  let next = title;
  next = next.replace(/shorts/gi, occasion === "formal" ? "Trousers" : "Chinos");
  next = next.replace(/linen\s*\/\s*shorts/gi, "Breathable button-up");
  next = next.replace(/short sleeve/gi, "Button-up");
  next = next.replace(/athletic tee/gi, "Button-up");
  if (opts.hot && !/button|dress shirt|shirt/i.test(next)) {
    next = occasion === "formal" ? "Dress shirt" : "Button-up + chinos";
  }
  if (opts.rainy && !/rain|trench|umbrella/i.test(next)) {
    next = `${next} + raincoat`;
  }
  return next;
}

function remoteItem(item: string, feelsLike: number): string {
  const lower = item.toLowerCase();
  if (/dress shirt|oxford|button-up|button up/.test(lower)) {
    return feelsLike >= 72 ? "Soft tee" : "Soft sweater";
  }
  if (/chino|trouser|dress pant/.test(lower)) {
    return "Joggers";
  }
  if (/loafer|dress shoe|leather shoe|oxford/.test(lower)) {
    return feelsLike < 60 ? "Socks / slippers" : "Comfort sneakers";
  }
  if (/blazer/.test(lower)) {
    return feelsLike < 68 ? "Hoodie or cardigan" : item;
  }
  return item;
}

function remoteTitle(title: string, feelsLike: number): string {
  if (feelsLike >= 76) return "Soft tee + joggers";
  if (feelsLike >= 60) return "Comfort layers";
  return "Soft sweater + joggers";
}

function goingOutItem(item: string): string {
  const lower = item.toLowerCase();
  if (/tee\b|t-shirt|athletic tee/.test(lower)) return "Nice casual shirt";
  if (/jean/.test(lower)) return "Dark jeans or chinos";
  if (/sneaker/.test(lower)) return "Clean sneakers";
  if (/hoodie/.test(lower)) return "Light overshirt";
  return item;
}

function goingOutTitle(title: string): string {
  return title
    .replace(/athletic tee/gi, "Casual shirt")
    .replace(/short sleeve/gi, "Casual shirt");
}

function dedupe(items: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const item of items) {
    const key = item.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(item);
  }
  return out;
}
