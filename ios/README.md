# Wearther (iOS / SwiftUI)

Native iOS app that answers: **What should I wear today based on the weather?**

> This environment cannot compile or upload to TestFlight (Linux, no Xcode).
> Open the project on a Mac with Xcode 15+ to run on Simulator / device and ship via TestFlight.

## Open in Xcode

```bash
open ios/Wearther/Wearther.xcodeproj
```

1. Select the **Wearther** target
2. Set your **Team** under Signing & Capabilities
3. Change `PRODUCT_BUNDLE_IDENTIFIER` if needed (default: `com.wearther.app`)
4. Run on an iPhone simulator or device (iOS 17+)

## Architecture

| Path | Role |
|------|------|
| `Wearther/Recommendation/OutfitRecommender.swift` | Pure clothing recommendation engine |
| `Wearther/Services/WeatherService.swift` | Provider abstraction + API key hook |
| `Wearther/Services/OpenMeteoProvider.swift` | Live weather (no API key) |
| `Wearther/Services/MockWeatherProvider.swift` | Offline / fallback mock data |
| `Wearther/Services/ComfortStore.swift` | UserDefaults comfort bias + saved city |
| `Wearther/Services/NotificationService.swift` | Local notifications for tomorrow weather alerts |
| `Wearther/Models/WeatherAlert.swift` | Alert copy for rain, snow, cold, heat, wind |
| `Wearther/ViewModels/HomeViewModel.swift` | Screen state |
| `Wearther/Views/*` | SwiftUI UI |

Flow: **Weather → OutfitRecommender → feedback → warmthBias → next recommendation**.

Includes a **Plan for Tomorrow** section that fetches the next-day forecast and recommends suitable clothing ahead of time.

**Tomorrow alerts** — optional local notifications (default ~7 PM) when rain, snow, or extreme temps are expected, e.g. *"It's gonna rain tomorrow! Make sure to pack an umbrella or rain wear."*

**Sweata Weatha** — when it's classic sweater weather (52–68° feels-like, dry skies), a Boston-accent banner pops up: *"Pahfect sweata weatha — grab ya fleece!"*

## Weather API key

In `Wearther/Info.plist`:

- `WEATHER_PROVIDER` = `open-meteo` (default) | `mock` | `openweather`
- `OPENWEATHER_API_KEY` = your key (when using OpenWeather)

Open-Meteo works without a key. Network failures fall back to mock data.

## TestFlight (on your Mac)

1. Archive in Xcode: **Product → Archive**
2. **Distribute App → App Store Connect → Upload**
3. In [App Store Connect](https://appstoreconnect.apple.com), create the app with the same bundle ID
4. Open **TestFlight**, add internal/external testers once processing finishes

You need an Apple Developer Program membership for device installs and TestFlight.
