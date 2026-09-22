# Gimmy

A gym assistant that imports a Garmin `.fit` workout plan, walks you through it one step at a
time, and keeps a streak and a calendar of everything you have done.

Everything stays on the device. There is no backend, no account, and the app makes no network
requests at all — the `.fit` file you pick is parsed locally and never leaves your phone.

| | |
| --- | --- |
| **Platforms** | iOS · Android · Web |
| **Framework** | Flutter 3.47 (Dart 3.13), Material 3 |
| **State** | Bloc (`flutter_bloc`) |
| **Storage** | Local files on mobile, browser local storage on web |
| **Tests** | 153, covering the FIT parser, the streak, the execution state machine, and full user flows |

## What it does

**Import.** Pick a Garmin workout `.fit` file. Gimmy validates it — signature, CRC, and that it is
a *workout* rather than an activity or a course — expands its repeat blocks into a flat list, and
shows you the whole thing before you commit to it. A file that is not a usable workout is rejected
with a reason, and nothing is written.

**Dashboard.** Your streak, the active plan with a one-tap start, a month calendar marking every
day you trained, and your most recent sessions.

**Workout.** One step at a time, with a countdown dial that shifts from green through amber to red
as the step runs down. Timers never start on their own — you press Play, including on the step the
app advances to when a countdown ends. Reps steps wait for you. There is a −10s control, a skip,
and a session is recorded the moment you begin, so the day counts towards your streak whether or
not you finish.

**Settings.** Theme, importing a new plan, and wiping everything.

## Running it

```bash
flutter pub get
flutter run                  # a connected device or simulator
flutter run -d chrome        # web
```

Release mode does not run on an iOS simulator; use a physical device.

```bash
flutter analyze              # static analysis
flutter test                 # the whole suite
flutter test --coverage      # writes coverage/lcov.info
flutter test --update-goldens  # after an intentional UI change
```

```bash
flutter build ios
flutter build apk
flutter build web --release
```

## How it is put together

```
lib/
  app/          AppBloc, the shell, and the pushed routes (import, execution)
  core/         design tokens, motion, shared widgets, config, formatting
  data/         models, the FIT decoder and parser, repositories, streak logic
  features/     import · dashboard · active · settings · execution
```

`AppBloc` owns what the tabs share — settings, the active plan, the session history — so switching
tabs never re-reads the disk. Feature blocs own their own flows.

Three tabs live in an `IndexedStack`: Dashboard, Workout, Settings. Import and the workout runner
are pushed routes rather than tabs. On first launch, with nothing stored, Import opens over the
shell and cannot be dismissed until a plan is saved.

Every colour, size and duration comes from `AppTheme`, `GimmyTokens` or `GimmyMotion`. No widget
hard-codes a colour, and a test enforces WCAG contrast across both themes.

### The FIT file

`docs/TotalBody_Sett2-4.fit` is the reference workout the tests are written against: 28 stored
steps containing 8 repeat blocks, which expand to 54 flat steps and 52m45s of timers.

Gimmy decodes FIT itself (`lib/data/fit/fit_decoder.dart`) rather than using a package — see
[ADR-0003](docs/adr/0003-own-fit-decoder.md) for why.

## Decisions

The reasoning behind the choices that shaped this app is in [`docs/adr/`](docs/adr/):

| | |
| --- | --- |
| [0001](docs/adr/0001-bloc-for-state-management.md) | Bloc for state management |
| [0002](docs/adr/0002-json-documents-over-a-database.md) | JSON documents instead of a database |
| [0003](docs/adr/0003-own-fit-decoder.md) | Decoding FIT ourselves |
| [0004](docs/adr/0004-unfiltered-file-picker.md) | An unfiltered file picker |
| [0005](docs/adr/0005-light-palette-contrast.md) | Departing from the design system's light palette |
| [0006](docs/adr/0006-single-active-plan.md) | One active plan, not a library |
| [0007](docs/adr/0007-fractional-timer-thresholds.md) | Fractional timer colour thresholds |
| [0008](docs/adr/0008-compile-time-feature-flags.md) | Compile-time flags for metrics with no data |
| [0009](docs/adr/0009-platform-split-storage.md) | Platform-split storage behind one interface |

## Known gaps

- **The file picker itself is not covered by tests.** Everything either side of it is; the
  platform channel is roughly fifteen lines of glue that needs a human tap.
- **No audio cues, haptics, accent colours, or Garmin Connect sync.** These appear in the design
  and are shown in Settings marked as unavailable.
- **BPM, calories and effort** are built and wired but hidden behind flags, because nothing in the
  app can measure them honestly.
- **No licence yet** — see below.

## Licence

This repository does not carry a licence file yet. Without one, default copyright applies and
nobody may reuse the code. Add one before making the repository public if that is not what you
intend.
