# Exercise media in the runner — plan

Show an animated demo of the current exercise during a workout. On the phone runner the user
swipes the dial (timer / reps) right→left to see the demo and left→right to return. No match →
no swipe, the runner looks exactly as today.

Source: [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset),
pinned at `7455efae41b330c265e7cd4b78dfa848e7ce5ebd`.

## Status (2026-09-25)

Steps 1–8 implemented, 351 tests green. Not yet checked on a device: real GIFs on screen,
preview thumbnails over the network, the background download. **Release blocked on the Gym
visual licence.**

Deviations from the design below, found while building:

- Matching ranks extra *movement* words, not extra words: equipment words are free, so
  `Squat` → `dumbbell squat`, not `jump squat`. Plurals are folded.
- Demos are downloaded **after** the plan is saved, not before: with a 20 s timeout per file a
  bad network could hold the import screen for minutes.
- Matching, media and the catalog sit behind one `ExerciseDemos` repository.
- Import preview thumbnails are one card per exercise, not per step row; the picker sheet is
  text-only.
- Desktop shows the demo beside the dial without repeating the figure.
- The dataset `LICENSE` ships in `assets/exercises/` and is on the licences page (MIT requires
  the notice); Legal §3 no longer claims zero network requests.

## Decisions (2026-09-25)

| Question | Decision |
|---|---|
| Media licence | Owner obtains a licence from Gym visual. **Blocks release, not development.** Every screen that shows a GIF carries `© Gym visual — https://gymvisual.com/`. |
| Delivery | Ship only a trimmed catalog (~150 KB). GIFs are fetched **at plan import** and cached; the workout itself stays offline. |
| Matching | Auto-match on import, shown in the import preview, overridable per exercise. The choice is stored on the step. |

## Dataset facts that shape the design

- `data/exercises.json`: 1,324 records, 17 MB (10 languages of instructions). We need 4 fields:
  `id`, `name` (lowercase, e.g. `dumbbell biceps curl`), `equipment`, `gif_url` (`videos/0001-2gPfomN.gif`).
- GIFs are 180×180, median 91 KB, max 228 KB. 125 MB in total, which is why nothing is bundled.
- Names are verbose, FIT step names are short. Of 18 common names only 4 match exactly
  (`push-up`, `burpee`, `pull-up`, `mountain climber`); `squat` is contained in 75 names,
  `curl` in 179; `jumping jack` in none. Matching is fuzzy by necessity, and a miss is normal.
- `raw.githubusercontent.com` serves `access-control-allow-origin: *`, so the web can load GIFs directly.

## Design

### Catalog (build time)

`tool/build_exercise_catalog.dart` reads a local checkout of the dataset and writes
`assets/exercises/catalog.json`: `[{id, name, equipment, gif}]`. Committed, so the app build never
touches the network. Rerun only to bump the pinned commit.

### Matching — `lib/data/exercises/exercise_matcher.dart`

Pure function, no I/O: `ExerciseMatch? match(String stepName, List<CatalogEntry> catalog)`.

1. Normalise: lowercase, strip side/set suffixes (`left`, `right`, `sx`, `dx`, `x2`, digits),
   collapse punctuation (`push up` = `push-up` = `pushup`).
2. Exact name → done.
3. Every query token contained in the candidate's tokens → rank by: fewest extra tokens,
   then equipment preference (`body weight` > `dumbbell` > `barbell` > rest), then id.
4. Nothing → null.

Only `StepIntensity.active` steps are matched: rest / warm-up / cool-down never get a demo.

### Model — `PlanStep.exerciseId` (`String?`)

- Optional in `toJson`/`fromJson`. Old plans load unchanged and simply have no demos (per the
  "never lose old data" rule in CLAUDE.md; applies to plans too).
- Set by the import flow, not by the FIT parser: the parser stays a pure FIT reader.
- One id per distinct exercise name (`Plan.exerciseNames`), applied to every step with that name.

### Media cache — `ExerciseMediaStore`

Platform-split like `DocumentStore`, via conditional import:

- **io**: `<app documents>/exercise_media/<id>.gif`. `prefetch(ids)` downloads the missing ones
  with `dart:io` `HttpClient` (no new dependency), writing to a temp file then renaming (atomic, like
  `document_store_io.dart`). `imageFor(id)` → `FileImage` or null if not on disk.
- **web**: no prefetch (local storage caps at ~5 MB); `imageFor(id)` → `NetworkImage(rawUrl)`,
  and the browser HTTP cache does the rest.
- Base URL is the pinned raw GitHub URL, held in `AppConfig`. Once the licence is in place, consider
  hosting the GIFs yourself (e.g. a GitHub release asset in this repo) so a third party's repo
  going away doesn't break the feature. Only that constant changes.

A failed download is never an import failure: the plan saves, that step shows the dial only, and
the result is logged through `AppLog`.

### Import flow

`ImportBloc`: after parse → run matcher over `plan.exerciseNames` → preview state carries
`Map<String name, String? exerciseId>`.

Import preview: each exercise row gets a small 48px thumbnail (or none) and a "change" action
opening a searchable sheet over the catalog (plain `TextField` filter + `ListView`, with a
"No demo" option at the top). `ImportConfirmed` → apply ids to the steps → `prefetch` → save.
Settings reopening the active plan for re-matching: **not in v1**.

### Runner — phone (`phone_runner.dart` `_Stage`)

Replace the `StepDial` slot with `StepDialPager`:

- `exerciseId == null` or `imageFor` null → the plain `StepDial`, as today.
- Otherwise a 2-page `PageView` (dial, demo) of the same size + a 2-dot indicator underneath.
  Demo page: GIF in a rounded square at the dial's diameter, `FilterQuality.none` scaled up (it's
  180px), credit line under it in `labelMono`.
- `PageController` keyed by `state.currentIndex` → each new step opens on the dial (the timer is
  what the user must see when a step starts).
- The timer keeps running while the demo shows; a small readout of the remaining time / reps sits
  on the demo page so the user is never blind to the clock.
- Reduced motion (`GimmyMotion.isReduced`): `animateToPage` becomes `jumpToPage`, and the demo
  shows the dataset's static `.jpg` (~8 KB) instead of the GIF. So `prefetch` fetches both
  files per exercise, and the catalog carries the `image` path too.
- Semantics: dots are a button, "Show exercise demo" / "Show timer", so the swipe is not the only
  way in (accessibility).

### Runner — desktop (`execution_desktop.dart`)

No swipe on desktop. Show the demo beside the dial when there is width, otherwise nothing. Low
priority; can ship after phone.

## Tasks

Each ends green on `flutter analyze` + `flutter test`.

1. **Catalog script + asset.** `tool/build_exercise_catalog.dart`, generated `catalog.json`,
   `pubspec.yaml` asset entry. → verify: test loads the asset, 1,324 entries, ids unique.
2. **Matcher.** TDD. Table test: `Squat`, `Push-up`, `Push up`, `Row left`, `Plank`,
   `Leg extension`, `Biceps curl`, `Jumping jack`→null, `Rest`→(not called). → verify: table passes.
3. **`PlanStep.exerciseId`.** JSON round-trip + a test that loads the old plan JSON shape. → verify.
4. **`ExerciseMediaStore`** io + web + conditional import, `AppConfig` base URL. Test io with a
   fake `HttpClient` / temp dir inside `tester.runAsync` rules. → verify: missing → download,
   present → no request, failure → null + logged.
5. **Import: auto-match + preview thumbnails + override sheet.** Bloc tests for match / override /
   confirm-applies-ids. Widget test for the sheet. → verify.
6. **Phone runner pager.** Widget tests: no id → no `PageView`; id + image → swipe shows demo and
   credit; next step → back on dial; semantics button toggles. Golden for the demo page
   (`loadAppFonts`, `silenceWorkoutCues`, `withHeartRate`, no `pumpAndSettle`). → verify.
7. **Desktop side-by-side.** Optional.
8. **Docs.** CLAUDE.md: media licence + pinned commit + "catalog is generated", About/Legal
   page credit for Gym visual and the MIT dataset.

## Out of scope (v1)

Showing instructions text (the dataset has Italian; easy follow-up on the demo page), re-matching an
already-saved plan, cache eviction (a plan's GIFs are ~1–2 MB total), bundling any GIFs.

## Risks

- **Licence** not obtained → feature can ship with media off (catalog + matching still useful for a
  text-only follow-up). Do not release with GIFs before it.
- **Wrong auto-match** → override in import preview mitigates it; the matcher table test is the contract.
- **Upstream repo changes/disappears** → pinned commit mitigates changes; self-hosting mitigates removal.
