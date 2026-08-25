# Wearther

What should I wear today based on the weather?

## Projects

| Path | Stack |
|------|--------|
| `ios/Wearther/` | **Native SwiftUI iOS app (primary)** |
| `/` (this folder) | Earlier Next.js web MVP |

### iOS (Swift)

```bash
open ios/Wearther/Wearther.xcodeproj
```

See [`ios/README.md`](ios/README.md) for signing, weather keys, and TestFlight steps.

### Web (Next.js)

```bash
npm install
npm run dev
```

## Shared idea

Weather → recommendation engine → local comfort feedback.

The Swift `OutfitRecommender` mirrors the web `lib/recommendOutfit.ts` rules.
