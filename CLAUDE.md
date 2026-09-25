# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

`gimmy` is a Flutter app (Dart SDK `^3.13.4`, Flutter 3.47.5 stable, bundle id
`com.simone98dm.gimmy`) that imports a Garmin `.fit` workout plan, guides the user through it
step by step, and tracks a streak and a calendar of past sessions. Everything is local: no
backend, no account. The one network call is downloading exercise demos when a plan is saved,
and that feature ships switched off (`FeatureFlags.showExerciseDemos`). Live BPM comes from a paired Bluetooth
heart-rate sensor (a Garmin watch or strap).

Platforms: **android, ios and web** (no macos/linux/windows). Adding one requires
`flutter create --platforms=<name> .`.

### Architecture

State management is **Bloc** throughout (`flutter_bloc`). `AppBloc` owns what the tabs share —
settings, the active plan, the session history — so switching tabs never re-reads the disk.
Feature blocs (`ImportBloc`, `ExecutionBloc`) own their own flows.

```
lib/
  app/          AppBloc, the shell, and the pushed routes (import, execution)
  core/         theme tokens, shared widgets, config, formatting
  data/         models, the FIT parser, the repositories, streak logic
  features/     import · dashboard · active · settings · execution
```

Navigation is three tabs — Dashboard, Workout, Settings — in an `IndexedStack`. Import and the
execution runner are **pushed routes, not tabs**: import is reached from Settings, and on first
launch it opens over the shell and cannot be dismissed until a plan is saved.

Motion lives in `GimmyMotion` (`core/theme/motion.dart`): press/release, tab change and page
transition durations, the curves, and the 0.98 press scale the design system specifies. Controls
wrap in `PressableScale`, CTAs use `GimmyCta`, and pushed pages use `GimmyPageRoute`. Every one of
them checks `GimmyMotion.isReduced(context)` and stays still when the platform asks.

### Things that will bite you

- **Design tokens.** Read `DESIGN.md` before drawing any UI: it is the visual and UX contract
  (tokens, type ramp, spacing, motion, components, do's and don'ts).
  Colors, sizes and type all come from `AppTheme` or `GimmyTokens.of(context)`.
  No widget hard-codes a color. The light palette's accents are deliberately darker than the
  design doc states — the documented values fail WCAG contrast as foregrounds, and
  `test/core/theme/contrast_test.dart` enforces that.
- **The FIT decoder is ours** (`lib/data/fit/fit_decoder.dart`), not a package. The official port,
  `fit_dart_sdk`, cannot compile for the web: it contains `int` literals too large for a JavaScript
  number, which is a hard error on dart2js *and* dart2wasm. Ours reads only `file_id`, `workout`
  and `workout_step` — the parser tests against the reference workout are its contract.
- **The file picker is deliberately unfiltered** (`FileType.any`). iOS has no UTI for `.fit`, and
  filtering to it leaves the picker with an empty type list where nothing is selectable. The
  parser does the rejecting instead.
- **Storage is platform-split** behind `DocumentStore`: a file with an atomic rename on mobile,
  `shared_preferences` (local storage) on the web, chosen by conditional import in
  `open_document_store.dart`. `path_provider` has no web implementation, so nothing outside
  the `*_io.dart` files behind a conditional import (`document_store_io.dart`,
  `exercise_media_store_io.dart`) may import it.
- **Exercise demos** (`lib/data/exercises/`, `ExerciseDemos`) are behind
  `FeatureFlags.showExerciseDemos`, **off** until the media licence is in place. The one gate is
  `ExerciseDemos.isEnabled` (defaults to the flag): off, `match`/`prefetch`/`demoFor` are no-ops,
  the import card and its spacing are gone, and Legal §3/§6 drop the download and media copy.
  Tests that exercise demos pass `isEnabled: true` (`oneDemo` does). `assets/exercises/catalog.json` is
  **generated** by `tool/build_exercise_catalog.dart` from
  [exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset), pinned to the commit in
  `AppConfig.exerciseMediaBaseUrl`; never edit it by hand, and bump the two together. On import
  each working step is matched by name (`matchExercise`; its table test is the contract) and the
  pick, overridable in the preview, is stored as `PlanStep.exerciseId`. Saving fetches the media
  in the background (files on mobile; the web loads it on demand). Nothing about demos may throw:
  a miss or a failed download just leaves the step with its dial.
  The dataset is MIT (its `LICENSE` ships in `assets/exercises/` and is listed on the licences
  page), but **the GIFs and JPGs are © Gym visual** and need their own licence: never commit
  them to this repo, and every screen that shows one carries `AppConfig.exerciseMediaCredit`.
  In widget tests the catalog asset read never completes under fake async: use
  `withExerciseDemos` (no demos) or `oneDemo` from `test/support/fake_exercise_demos.dart`, or
  load the catalog in `setUpAll`. Animated GIFs do not decode in tests at all, so goldens show
  the layout, not the picture.
- **Session history must never lose old sessions.** `SessionRepository` parses entry by
  entry: an unreadable session is skipped (logged), and `upsert` writes the raw entries back
  so it survives on disk. New fields on `WorkoutSession` must be optional in `fromJson`;
  step records (`plannedSteps`, `steps`, heart rate) exist only on sessions recorded after
  they were added, and `hasStepRecords` tells them apart. Keep a test that loads the old
  JSON shape.
- **Widget tests run under fake async**, so `dart:io` futures never complete: seeding a repository
  in a widget test hangs rather than fails. Do it inside `tester.runAsync`.
- **Goldens need fonts loaded.** Call `loadAppFonts()` from `test/support/test_fonts.dart` in
  `setUpAll`, or every glyph renders as a box and overflow goes unnoticed.
- **Audio cues need silencing in tests.** `WorkoutCues` touches audioplayers, which
  opens a platform event stream the moment it is used; under `flutter_test` the missing
  plugin is reported through `FlutterError`, out of reach of any try/catch, and fails
  whatever test happened to advance a step. Call `silenceWorkoutCues()` from
  `test/support/silent_cues.dart` in any test that runs the execution page.
- **Do not `pumpAndSettle` on the execution page.** The live dot pulses for as long as the timer
  is running, so there is never a settled frame. Pump fixed durations instead.
- **Flow tests must wait on a condition**, not a fixed number of pumps — see
  `test/support/pump_until.dart`. A fixed count passes on an idle machine and flakes on a busy
  one. Note that a `SliverList` builds its children over several frames, so waiting for the first
  thing on a page does not mean the rest of it exists yet.
- **Ink needs a `Material` above the background it splashes on.** A `Material` whose child paints
  an opaque decoration hides its own splash, which reads as a dead button. Cards, nav tabs,
  calendar days and the workout controls all had this.
- `AppConfig.chromeBlurSigma` controls the frosted header/nav blur, which is the most expensive
  thing drawn per frame. It ships at 0; raise it to 8–16 on hardware that can afford it.
- **Log through `AppLog`** (`core/logging/app_log.dart`), never `print`/`debugPrint`/
  `dart:developer` directly — `developer.log` is a no-op on dart2js, so the web would log
  nothing. Bloc events are logged by `LoggingBlocObserver` and routes by
  `LoggingNavigatorObserver`, so only log *outcomes* by hand. Give every route, dialog and
  sheet a `RouteSettings(name:)` so the log can say what opened. Pass the stack trace to
  `addError`.
- **Do not put `InkSparkle` back.** It compiles a fragment shader on first use and stalls the
  first tap. The theme uses `InkRipple`.
- **Tab pages are all alive** inside the `IndexedStack`, so `context.watch` on `AppBloc` rebuilds
  every one of them, the step list included. Use `context.select` and take only what the page
  draws.

The reference workout is built in memory by `test/support/sample_fit.dart` (a small FIT
encoder with its own CRC): 13 stored steps and 3 repeat blocks that expand to **22 flat steps**,
20m15s of timers. Tests assert those numbers through its `sampleFit*` constants — change the
fixture and they follow, but the goldens need `--update-goldens`. No `.fit` file lives in the repo.

## Commands

```bash
flutter pub get                      # install deps (after any pubspec.yaml edit)
flutter run                          # run on connected device/simulator (debug only on a simulator)
flutter analyze                      # lint + static analysis
flutter test                         # all tests
flutter test test/data/fit/          # one directory
flutter test --update-goldens        # after an intentional UI change, and once after a fresh clone
flutter test --exclude-tags golden   # what CI runs: golden PNGs are local-only, never in git
flutter test --coverage              # writes coverage/lcov.info
flutter build apk / flutter build ios
flutter build web --release        # dart2js; `--wasm` also compiles
dart run flutter_launcher_icons    # after changing assets/icon/
```

`analysis_options.yaml` excludes `build/`, `android/`, `ios/` from the analyzer — `flutter analyze`
only covers `lib/` and `test/`. `prefer_initializing_formals` is off: Dart forbids named parameters
starting with an underscore, so constructors injecting into private fields cannot satisfy it.

## Notes

- **Releases are automated** by release-please (`.github/workflows/release.yml`,
  `release-please-config.json`). Commit with Conventional Commits: `fix:` bumps the patch,
  `feat:` the minor, `feat!:` or a `BREAKING CHANGE:` footer the major; `chore:`, `docs:`,
  `test:`, `ci:` and `refactor:` never release on their own. Merging the release PR bumps
  `pubspec.yaml` (build number included), `AppConfig.appVersion` and `CHANGELOG.md`, and tags
  `vX.Y.Z`. Never bump the version by hand — `test/core/config/app_version_test.dart` fails
  if the two version strings drift.

- Release mode does not run on an iOS simulator; use a physical device.
- `.gitignore` used to exclude `test/features` and `test/app`, which silently hid most of the
  suite. If tests seem to vanish from a diff, check there first.
- On the web, from `GimmyLayout.desktopBreakpoint` (1200px) the shell swaps the bottom nav for
  a sidebar and pages use their `*_desktop.dart` layouts. Below it, the phone layout is capped at
  560px and centred (`_PhoneFrame`). Prose pages (About, Legal) cap at `GimmyLayout.readingWidth`.
- Calories and effort are built but hidden behind `FeatureFlags`, off by default, because
  there is no real data source for them. BPM shows whenever a heart-rate sensor is paired.
- **Heart rate is standard BLE only** (`flutter_blue_plus`, Heart Rate Service 0x180D). A Garmin
  watch only appears while "Broadcast Heart Rate" is on; HRM straps always do. Nothing else from
  Garmin (calories, pace) is reachable without the Connect IQ SDK. The paired id lives in
  `AppSettings`; a `BlocListener` in `GimmyApp` turns it into `HeartRateMonitorChanged`, which is
  what reconnects at launch. Pairing is hidden on the web. Any test that builds Settings or the
  Execution page must wrap it in `withHeartRate` from `test/support/fake_heart_rate_monitor.dart`.
- `flutter_blue_plus` is licensed free for personal use only, and its Android Gradle plugin
  POSTs the app id/name/version to the author's license endpoint on every Android build. The
  app itself makes no network calls at runtime beyond the (flagged-off) exercise demo downloads.

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
