# Steady

Calm, friendly habit tracker (Expo).

## App icon

| Asset | Path | Size | Use |
|-------|------|------|-----|
| Master icon | `assets/icon.png` | 1024×1024 | iOS + Android legacy |
| Adaptive foreground | `assets/adaptive-icon.png` | 1024×1024 (transparent) | Android adaptive icon |
| Splash | `assets/splash-icon.png` | 1024×1024 | Splash screen |
| Favicon | `assets/favicon.png` | 48×48 | Web |

Configured in `app.json`:

- **iOS** — `expo.icon` / `ios.icon` → `./assets/icon.png`
- **Android** — `android.adaptiveIcon.foregroundImage` + `backgroundColor` `#E8F0EA`
- **Splash** — soft sage background `#E8F0EA` with centered mark
- **Web** — `web.favicon`

Mark: open progress ring + check, sage `#4A7868` on mist `#E8F0EA`.

## Run

```bash
cd habit-tracker
npm install
npx expo start
```
