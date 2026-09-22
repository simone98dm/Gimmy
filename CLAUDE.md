# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

`gimmy` is a Flutter app (Dart SDK `^3.13.4`, Flutter 3.47.5 stable, bundle id
`com.simone98dm.gimmy`) that imports a Garmin `.fit` workout plan, guides the user through it
step by step, and tracks a streak and a calendar of past sessions. Everything is local: no
backend, no account, no network calls at all.

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

- **Design tokens.** Colors, sizes and type all come from `AppTheme` or `GimmyTokens.of(context)`.
  No widget hard-codes a color. The light palette's accents are deliberately darker than the
  design doc states — the documented values fail WCAG contrast as foregrounds, and
  `test/core/theme/contrast_test.dart` enforces that.
- **The FIT decoder is ours** (`lib/data/fit/fit_decoder.dart`), not a package. The official port,
  `fit_dart_sdk`, cannot compile for the web: it contains `int` literals too large for a JavaScript
  number, which is a hard error on dart2js *and* dart2wasm. Ours reads only `file_id`, `workout`
  and `workout_step` — the parser tests against the real sample file are its contract.
- **The file picker is deliberately unfiltered** (`FileType.any`). iOS has no UTI for `.fit`, and
  filtering to it leaves the picker with an empty type list where nothing is selectable. The
  parser does the rejecting instead.
- **Storage is platform-split** behind `DocumentStore`: a file with an atomic rename on mobile,
  `shared_preferences` (local storage) on the web, chosen by conditional import in
  `open_document_store.dart`. `path_provider` has no web implementation, so nothing outside
  `document_store_io.dart` may import it.
- **Widget tests run under fake async**, so `dart:io` futures never complete: seeding a repository
  in a widget test hangs rather than fails. Do it inside `tester.runAsync`.
- **Goldens need fonts loaded.** Call `loadAppFonts()` from `test/support/test_fonts.dart` in
  `setUpAll`, or every glyph renders as a box and overflow goes unnoticed.
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
- **Do not put `InkSparkle` back.** It compiles a fragment shader on first use and stalls the
  first tap. The theme uses `InkRipple`.
- **Tab pages are all alive** inside the `IndexedStack`, so `context.watch` on `AppBloc` rebuilds
  every one of them, the 54-row list included. Use `context.select` and take only what the page
  draws.

`docs/TotalBody_Sett2-4.fit` is the reference workout: 28 stored steps and 8 repeat blocks that
expand to **54 flat steps**, 52m45s of timers. Several tests assert those numbers.

## Commands

```bash
flutter pub get                      # install deps (after any pubspec.yaml edit)
flutter run                          # run on connected device/simulator (debug only on a simulator)
flutter analyze                      # lint + static analysis
flutter test                         # all tests
flutter test test/data/fit/          # one directory
flutter test --update-goldens        # after an intentional UI change
flutter test --coverage              # writes coverage/lcov.info
flutter build apk / flutter build ios
flutter build web --release        # dart2js; `--wasm` also compiles
dart run flutter_launcher_icons    # after changing assets/icon/
```

`analysis_options.yaml` excludes `build/`, `android/`, `ios/` from the analyzer — `flutter analyze`
only covers `lib/` and `test/`. `prefer_initializing_formals` is off: Dart forbids named parameters
starting with an underscore, so constructors injecting into private fields cannot satisfy it.

## Notes

- Release mode does not run on an iOS simulator; use a physical device.
- `.gitignore` used to exclude `test/features` and `test/app`, which silently hid most of the
  suite. If tests seem to vanish from a diff, check there first.
- On the web the layout is capped at phone width and centred (`_PhoneFrame`); the design is a
  4-column mobile grid and gains nothing from a desktop's width.
- BPM, calories and effort are built but hidden behind `FeatureFlags`, off by default, because
  there is no real data source for them.

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
