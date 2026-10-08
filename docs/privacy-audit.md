# Privacy & cookie audit

Audited 2026-10-08 against v1.3.0. Scope: `lib/`, `web/`, `pubspec.yaml`, `.github/workflows/`,
and the release web build (`flutter build web --release`).

## Stack

- Flutter 3.47.5 app; targets android, ios, web. Single-page app rendered to a canvas.
- No i18n: every string is English, hard-coded in the widgets. No `flutter_localizations`, no ARB.
- No backend, no account, no forms, no payments, no analytics, no error tracking.
- Hosting of the web build is not defined in the repo (CI only builds it).
- Existing legal copy: `lib/features/about/view/legal_page.dart` (terms + "Your data" section).
  No cookie banner or consent tool of any kind.

## Inventory

| Item | Provider | Where | Purpose | Category | Identifiers | Transfer | Legal basis |
|---|---|---|---|---|---|---|---|
| App storage (plan, sessions, settings, paired sensor id) | first party | `data/storage/document_store_web.dart`, `settings_repository.dart` (`shared_preferences` → `localStorage`, keys prefixed `flutter.`) | Keep the user's own data on the device | Strictly necessary | localStorage entries; persistent until "Wipe profile" or site data cleared; never sent anywhere | none | Exempt from consent (ePrivacy art. 5(3), service explicitly requested); GDPR not engaged for the owner, data never leaves the device |
| App storage, mobile | first party | `document_store_io.dart` (file in app documents dir) | Same | Strictly necessary | file on device | none | as above |
| CanvasKit / Skwasm renderer | Google (`www.gstatic.com/flutter-canvaskit/…`) | `build/web/flutter_bootstrap.js`, `main.dart.js` — Flutter default | Download the web rendering engine at startup | Not a cookie; third-party request | **No cookies.** Transmits IP address + user agent to Google on every first load | possible (Google LLC, US; EU-US DPF) | Avoidable: `--no-web-resources-cdn` serves it from our own origin |
| Roboto + fallback fonts (Noto) | Google (`fonts.gstatic.com/s/`) | `main.dart.js` — Flutter engine default `fontFallbackBaseUrl` | Roboto is fetched on **every** start; Noto only for glyphs missing from Inter/JetBrains Mono (e.g. emoji) | Not a cookie; third-party request | **No cookies.** IP + user agent to Google on every first load | possible (as above) | Avoidable: set `fontFallbackBaseUrl` to a self-hosted path, or ensure no fallback glyphs |
| Exercise demos | GitHub (`raw.githubusercontent.com`) | `data/exercises/exercise_media_store*.dart`, `AppConfig.exerciseMediaBaseUrl` | Download GIF/JPG demos on plan save | Functional; **flag off** (`FeatureFlags.showExerciseDemos = false`) | No cookies; IP to GitHub (Microsoft, US; EU-US DPF) | yes, when enabled | Requested by the user's action; disclose if the flag is turned on |
| Heart-rate sensor | local Bluetooth (`flutter_blue_plus`) | `features/heart_rate/` | Read live BPM | n/a | sensor id stored locally; health-adjacent data (BPM) only in local sessions | none | Data stays on device; hidden on web |
| Build-time licence ping | `flutter_blue_plus` Gradle plugin | Android build only | Licence check | n/a | app id/name/version from the **developer's** machine; no user data | — | Not a user-facing processing |
| Web hosting server logs | unknown | not in repo | Serving the files | Strictly necessary | IP, user agent, timestamp (provider-dependent) | depends on host | Legitimate interest; must be named in the privacy policy |

Not found: `document.cookie`, cookies of any kind, `sessionStorage`, IndexedDB, analytics,
pixels, tag managers, embeds/iframes, chat widgets, captchas, Google Fonts CSS, other CDNs,
Sentry/LogRocket, forms, auth, payments.

## Conclusion

The app sets **no cookies** and uses only strictly-necessary local storage. A consent banner is
**not required** (Garante guidelines 10 June 2021, § 7: only technical cookies → information
notice only, no consent).

The one real issue is that the Flutter web runtime contacts Google (`gstatic.com`) by default,
sending the visitor's IP to a third party without any need. That is a GDPR transfer/minimisation
problem, not a cookie one: a consent banner would not fix it (and could not gate it — the banner
itself needs CanvasKit to render). Self-hosting the two resources removes it.

## Remediation (2026-10-08)

- `web/flutter_bootstrap.js` sets `canvasKitBaseUrl: "canvaskit/"` and
  `fontFallbackBaseUrl: "fonts/fallback/"`; Roboto is self-hosted in `web/fonts/fallback/`.
  Verified on a release build in Chromium: first visit sets no cookies and makes no request
  outside the site's origin; console clean. Known ceiling: other fallback glyphs (emoji, CJK)
  render as boxes instead of being fetched.
- Privacy policy (cookies section included): `lib/features/about/view/privacy_page.dart`,
  linked from Settings, About and Legal §3. No consent banner: nothing requires consent.
- If exercise demos are switched on, GitHub becomes a third party again; the policy's §6
  already follows `FeatureFlags.showExerciseDemos`.
