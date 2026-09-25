---
name: gimmy
description: A workout runner you read from the floor, mid-set, with sweaty hands.
colors:
  # Hacker Green (default theme), dark — the mode the system was designed in.
  surface: "#131313"
  surface-container-lowest: "#0E0E0E"
  surface-container-low: "#1C1B1B"
  surface-container: "#201F1F"
  surface-container-high: "#2A2A2A"
  surface-container-highest: "#353534"
  on-surface: "#E5E2E1"
  on-surface-variant: "#BACBB9"
  outline: "#859585"
  card-border: "#2C2C2C"
  modal-surface: "#242424"
  modal-border: "#383838"
  primary: "#75FF9E"
  primary-container: "#00E676"
  on-primary-container: "#00612E"
  error: "#FFB4AB"
  accent-peak: "#00E676"
  accent-pacing: "#FFD600"
  accent-critical: "#FF3D00"
  # Light counterparts (accents darkened to hold >=4.5:1 as foregrounds).
  light-surface: "#FAFAFA"
  light-surface-container: "#FFFFFF"
  light-surface-container-high: "#F0F0F0"
  light-on-surface: "#121212"
  light-on-surface-variant: "#666666"
  light-card-border: "#E5E5E5"
  light-primary: "#006D35"
  light-primary-container: "#00C853"
  light-accent-peak: "#007A34"
  light-accent-pacing: "#8A6200"
  light-accent-critical: "#C62300"
typography:
  display:
    fontFamily: "Inter"
    fontSize: "36px"
    fontWeight: 800
    lineHeight: "44px"
    letterSpacing: "-0.5px"
  headline-lg:
    fontFamily: "Inter"
    fontSize: "28px"
    fontWeight: 800
    lineHeight: "36px"
    letterSpacing: "-0.4px"
  headline-md:
    fontFamily: "Inter"
    fontSize: "24px"
    fontWeight: 700
    lineHeight: "32px"
    letterSpacing: "-0.3px"
  headline-sm:
    fontFamily: "Inter"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: "28px"
    letterSpacing: "-0.2px"
  title:
    fontFamily: "Inter"
    fontSize: "18px"
    fontWeight: 700
    lineHeight: "24px"
  body-lg:
    fontFamily: "Inter"
    fontSize: "16px"
    fontWeight: 500
    lineHeight: "24px"
  body-md:
    fontFamily: "Inter"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: "20px"
  body-sm:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 400
    lineHeight: "16px"
  label:
    fontFamily: "Inter"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: "16px"
    letterSpacing: "0.4px"
  metric-display-mobile:
    fontFamily: "JetBrains Mono"
    fontSize: "72px"
    fontWeight: 700
    lineHeight: 1
    fontFeature: "tnum"
  metric-display:
    fontFamily: "JetBrains Mono"
    fontSize: "44px"
    fontWeight: 700
    lineHeight: "48px"
    fontFeature: "tnum"
  metric-lg:
    fontFamily: "JetBrains Mono"
    fontSize: "28px"
    fontWeight: 600
    lineHeight: 1
    fontFeature: "tnum"
  metric-md:
    fontFamily: "JetBrains Mono"
    fontSize: "20px"
    fontWeight: 600
    lineHeight: "24px"
    fontFeature: "tnum"
  label-mono:
    fontFamily: "JetBrains Mono"
    fontSize: "12px"
    fontWeight: 500
    lineHeight: "16px"
    letterSpacing: "0.5px"
    fontFeature: "tnum"
rounded:
  sm: "4px"
  md: "8px"
  lg: "12px"
  xl: "16px"
  pill: "9999px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  ms: "12px"
  md: "16px"
  lg: "24px"
  xl: "32px"
  gutter: "16px"
components:
  button-primary:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
    typography: "{typography.title}"
    rounded: "{rounded.lg}"
    height: "52px"
  button-outlined:
    textColor: "{colors.on-surface}"
    typography: "{typography.title}"
    rounded: "{rounded.lg}"
    height: "52px"
  card:
    backgroundColor: "{colors.surface-container}"
    rounded: "{rounded.xl}"
    padding: "16px"
  inset-tile:
    backgroundColor: "{colors.surface-container-low}"
    rounded: "{rounded.md}"
    padding: "8px"
  chip:
    backgroundColor: "{colors.surface-container-high}"
    typography: "{typography.label-mono}"
    rounded: "{rounded.pill}"
    padding: "2px 8px"
  control-primary-round:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-primary-container}"
    size: "64px"
  control-secondary-round:
    backgroundColor: "{colors.surface-container-high}"
    textColor: "{colors.on-surface}"
    size: "48px"
  nav-bar:
    backgroundColor: "{colors.surface-container-lowest}"
    height: "64px"
---

# Design System: gimmy

> **For agents drawing UI.** This file is the contract. Tokens above are
> normative; the Dart source of truth is `lib/core/theme/` (`tokens.dart`,
> `gimmy_tokens.dart`, `app_theme.dart`, `motion.dart`, `gimmy_colors.dart`).
> Never hard-code a value that exists there — read it through
> `Theme.of(context)` or `GimmyTokens.of(context)`. If a value you need does not
> exist, add a token, don't inline a literal. `CLAUDE.md` holds the engineering
> constraints (Bloc, logging, tests); this file holds the visual and UX ones.

## 1. Overview

**Creative North Star: "Kinetic Performance — the instrument panel on the gym floor"**

gimmy is read at arm's length or from the floor, one to two metres away,
between reps, with a raised heart rate and sweaty thumbs. Everything follows
from that scene: the number that is ticking is the biggest thing on screen, the
control you need next is the biggest thing you can touch, and nothing moves
unless the workout moved. It is a product surface, not a brand page: earned
familiarity over novelty, one tool that disappears into the set.

The system is dark-first (designed in dark; light is first-class and tested,
not an inversion) and **Restrained**: tinted neutrals carry the surface, and a
single functional accent trio — **peak** (emerald), **pacing** (amber),
**critical** (red-orange) — carries meaning, never decoration. Two color themes
ship ("Hacker Green", default; "Sophisticated Blue", `palette_blue.dart` /
`docs/DESIGN-blue.md`) and both resolve into the same roles, so a widget never
knows which theme it is in.

It explicitly rejects: SaaS dashboard templates (hero-metric blocks, identical
card grids), decorative motion, gradient text, glassmorphism, and gamified
celebration that lies about what was done.

**Key Characteristics:**
- Telemetry in **JetBrains Mono with tabular figures**; everything else in **Inter**. Two families, never a third.
- **8pt grid** with a 4pt half-step and a 12 (`ms`) step: `xxs 2 · xs 4 · sm 8 · ms 12 · md 16 · lg 24 · xl 32`. No literal outside it; no `sm + 4` arithmetic.
- **44dp minimum** hit area on everything (`GimmyLayout.minTapTarget`); 52dp CTAs; 64dp primary workout control.
- **Motion under a third of a second**, easing out, and completely still under the OS reduce-motion setting.
- **Honest copy.** Say what was saved. "Ended early", not "abandoned". "No steps done", not a trophy.

### Layout and structure (folded in here per the spec)

- **Navigation:** three tabs — Today, Workout, Settings — in an `IndexedStack`
  with a 64dp bottom bar on phones and a 288dp sidebar from 1200px
  (`GimmyLayout.desktopBreakpoint`). One destination has one name and one icon
  everywhere (`GimmyTab` is the source; the sidebar reuses its glyphs). Import,
  the workout runner, About and Legal are **pushed routes**, not tabs, via
  `GimmyPageRoute` (which keeps the native slide and edge-swipe back on iOS).
- **Phone frame:** 16dp gutter; on the web below 1200px the phone layout is
  capped at 560px and centred. Prose pages cap at `readingWidth` (680 ≈ 75ch).
  Desktop content caps at 1280.
- **Rhythm:** tight inside a group (`xxs`–`sm`), `md` between sibling cards,
  `lg` before a new section or at the end of a scroll. Equal gaps everywhere
  is the failure mode — vary them so the squint test shows groups.
- **Cards:** one level only. A card may contain *inset tiles*
  (`tokens.insetSurface`), never another card. If something is not a distinct,
  actionable object, it does not need a container — use space and a heading.
- **The phone runner** (`PhoneRunner`): no cards. A progress strip (step
  count, intensity chip, thin bar), then the step straight on the page —
  step name (headline-lg), instruction, a collapsed "Form tip" line, the dial
  centred in the height left (200–320dp; a ring only on timer steps) and the
  heart-rate strip. When the step has an exercise demo (behind
  `FeatureFlags.showExerciseDemos`, off for now), the dial is page one
  of two: swipe left for the demo (with the dial's figure and the
  © Gym visual credit under it), and two tappable dots under the pages say
  which is up. Every step opens on the dial; no demo, no pager. The controls and a one-line "Next · …" live in a **pinned
  bottom bar** (the `Scaffold` bottom slot under the runner's own
  `ScaffoldMessenger`, so the undo snackbar floats above it). Nothing may push
  or cover that bar: on a short screen or at 2x text only the stage scrolls.
  The header back arrow is the one exit, on phone and desktop alike.
- **The desktop runner** (`DesktopRunner`, ≥1200px): the same progress strip
  with "5:20 active · 1 done · 1 skipped" on the right, then two columns with
  no cards — the stage (heading, form tip line, 320 dial — sharing the
  width with the step's demo when it has one — controls with keycap hints) and the whole plan as one list (✓ done, ⤼ skipped, current
  row highlighted and scrolled into view). Keyboard, via `RunnerKeyboard`:
  Space = the big button, S = skip, − = −10 s, ⌘Z/Ctrl+Z = undo, Esc =
  leave (confirmed), Enter on the summary = back to Today. Keys go through the
  same events as the buttons.
- **Insets:** everything lays out inside `SafeArea`; the header and nav bar
  are fixed heights (64) so content can pad for them — their labels shrink
  (`FittedBox`) rather than overflow at large text sizes.

## 2. Colors

A near-black instrument panel with a single electric emerald doing all the
talking; light mode is a clean white card on #FAFAFA with the same accents
darkened until they pass as text.

### Primary
- **Signal Emerald** (`primaryContainer` #00E676 dark / #00C853 light): fills
  for the primary action — Start Workout, Play/Done, the selected segment,
  a session day on the calendar, the live dot. Fill only; its foreground
  partner is `onPrimaryContainer`.
- **Emerald Ink** (`primary` #75FF9E dark / #006D35 light): emerald *as text* —
  selected nav label, "NEXT UP", "STEP 3 OF 22". Never use the container
  value as a text color in light mode; it fails contrast.

### Functional accents (`GimmyTokens`)
- **Peak** (`accentPeak` / `timerSafe` / `intensityActive`): a working step; the
  ring above 50% remaining.
- **Pacing** (`accentPacing` / `timerWarning` / `intensityRest`): rest steps; the
  ring between 20% and 50%.
- **Critical** (`accentCritical` / `timerCritical`): the ring's last 20%; the
  countdown digits switch to `colorScheme.error` there.
- Warmup and cooldown share **`intensityEasy`** (= `onSurfaceVariant`); the
  label names which one it is.
- Thresholds live in `GimmyTokens.kTimer*Threshold`; pick colors with
  `timerColorFor(...)`, never by comparing numbers in a widget.

### Neutral
- **Panel Black** `surface` #131313 — scaffold.
- **Card Graphite** `surfaceContainer` #201F1F — cards, with `cardBorder`
  #2C2C2C 1px and `cardShadow`.
- **Recess** `tokens.insetSurface` — a tile *inside* a card, sheet or dialog.
  Dark: `surfaceContainerLow` (darker than the card). Light:
  `surfaceContainerHigh` (#F0F0F0), because light cards are already white and
  a "lower" white vanishes.
- **Modal** `tokens.modalSurface` / `modalBorder` — dialogs, sheets, snackbars.
- **Text:** `onSurface` for content, `onSurfaceVariant` for secondary. `outline`
  is a stroke color, **never text** (it fails 4.5:1 in light).

### Rules
- Contrast is enforced by `test/core/theme/contrast_test.dart`: body ≥ 4.5:1,
  large text and graphics ≥ 3:1, in both brightnesses and both themes. A new
  role gets a line in that test.
- **Sophisticated Blue, light mode:** accent fills carry **white** labels
  (`onPrimaryContainer` #FFFFFF on #0270D6, 4.89:1), not the doc's near-black —
  dark text on mid blue read as muddy. The fill is one step deeper than the
  doc's #037CE7 so white holds AA.
- Amber is reserved for rest and warnings. Material defaults some selected
  states to `secondaryContainer` (amber here); the theme overrides them to
  primary. Don't reintroduce it.
- Alpha on a theme color is for **disabled** (0.35–0.4) and **scrims** only.

## 3. Typography

One sans for words, one mono for numbers that change.

**Display / headline / body — Inter** (`Theme.of(context).textTheme`):

| Style | Use |
|---|---|
| `displaySmall` 36/44 w800 | desktop hero title|
| `headlineLarge` 28/36 w800 | page titles; **the current step name on the runner**|
| `headlineMedium` 24/32 w700 | completion headline, dialog-sized titles|
| `headlineSmall` 20/28 w700 | card titles, dialog titles|
| `titleMedium` 18/24 w700 | CTA labels, list emphasis|
| `bodyLarge` 16/24 w500 | default content text, list titles, form tips|
| `bodyMedium` 14/20 w400 | secondary sentences, instructions, dialog body|
| `bodySmall` 12/16 w400 | captions, subtitles only|
| `labelMedium` 12/16 w600 +0.4 | text buttons, nav labels, segments|

**Telemetry — JetBrains Mono, tabular figures** (`GimmyTokens`): anything that
ticks or aligns in columns — countdowns, reps, BPM, durations, step counters.

| Token | Size | Use |
|---|---|---|
| `metricDisplayMobile` | 72 | the runner's countdown / rep count (inside a `FittedBox`) |
| `metricDisplay` | 44 | desktop countdown, big stats |
| `metricLg` | 28 | secondary live readouts beside the countdown (BPM) |
| `metricMd` | 20 | stat values, the "−10" control |
| `labelMono` | 12 | small mono labels: "STEP 1 OF 22", chips, weekday row, "25 min" |

**Rules**
- **12sp floor** for anything meaningful. Nothing ships at 11.
- **Never pass `fontSize:` in a widget.** If the ramp lacks a size, add a token.
  The only overrides allowed through `copyWith` are `color`, `fontWeight`
  (within w500–w800) and `letterSpacing`.
- **All-caps labels** add `GimmyType.capsTracking` (1.2 ≈ 10% of a 12px cap).
  Lowercase or numeric mono keeps the token's 0.5; calendar digits use 0 so two
  digits stay centred.
- **Screen readers** must not hear shouting: caps are visual. Put the sentence-
  case label in `Semantics(label:)` with `excludeSemantics: true`.
- **Text scaling is never clamped.** Fixed-height chrome must shrink its label
  (`FittedBox(fit: BoxFit.scaleDown)`) rather than clip.
- Headings: negative tracking is already in the ramp (≥ −0.5px); don't tighten
  further.

## 4. Elevation

Layered, not lifted: hierarchy comes from tonal surfaces first, a 1px stroke
second, and a soft ambient shadow last.

- `tokens.cardShadow` — cards (dark: black 40% / 20 blur / y4; light: 8%).
- `tokens.modalShadow` — dialogs and the completion card (32 blur / y12).
- `tokens.chromeShadowColor` — the fixed header and nav bar, cast toward the
  content scrolling under them.
- `tokens.activeGlow` — **only** the element that is live right now (the
  primary workout control). One glow per screen.
- Tonal order, back to front: `surface` → `surfaceContainerLow` →
  `surfaceContainer` (cards) → `surfaceContainerHigh` (chips, secondary round
  controls) → `surfaceContainerHighest` (selected/pressed fills).
- Blur (`BackdropFilter`) is expensive per frame: the chrome blur ships at 0
  (`AppConfig.chromeBlurSigma`). The completion summary's focus-pull blur is
  the one sanctioned use, and it animates in once.

## 5. Components

Reuse before you build. These live in `lib/core/widgets/` and already carry
tokens, press feedback, semantics and reduced-motion handling.

- **`GimmyCta`** — the full-width primary action (52dp, `rounded.lg`,
  `primaryContainer` fill, `titleMedium`, optional leading icon and a busy
  spinner). One per screen.
- **`FilledButton` / `OutlinedButton` / `TextButton`** — themed in
  `app_theme.dart` (52 / 52 / 44 min). Don't restyle per call site.
- **`PressableScale`** — wrap every custom tappable. 0.98 scale, 90ms down /
  160ms up, still under reduce-motion.
- **Cards** — `Card` (themed) or `GimmyCard`: `surfaceContainer`, 16 radius,
  `cardBorder`, `cardShadow`, 16 padding. Tappable cards put an `InkWell` inside
  a `Material` *above* the decoration (an opaque child hides the splash) and
  declare `Semantics(button: true)`.
- **Inset tile** — `tokens.insetSurface`, `GimmyRadii.cell` (8), 8 padding:
  metric strips, summary stats, notes inside sheets.
- **Chips / badges** — `GimmyBadge`, pill radius, `labelMono` in caps with
  `capsTracking`, `surfaceContainerHigh` or a 12% tint of the accent.
- **Round workout controls** — 48 / 64 / 48 circles, `lg` gap. Primary is the
  context action (Play → Pause → Done ✓), secondaries are text "−10" and
  skip-next. Each has a spoken label and `button`/`enabled` semantics. Distinct
  glyphs for distinct actions: Done is a check, Skip is skip-next.
- **Nav bar / sidebar** — `AppFooter` / `AppSidebar`, driven by `GimmyTab`.
  Selected state is `primary` ink plus `Semantics(selected: true)`.
- **Sheets and dialogs** — `showModalBottomSheet` / `showDialog` with the themed
  `modalSurface`, drag handle on sheets, and always a
  `RouteSettings(name: ...)`. Destructive dialogs name the consequence and give
  the safe option the longer, plainer label ("Cancel and keep my data").
- **Feedback** — floating `SnackBar` for transient results. Any tap that moves
  the workout on (Done, Skip) gets "*{step} done/skipped* · **Undo**", named
  after the step, kept until the next action rather than timed out. Past the
  last step the summary carries a quiet **Undo last step** `TextButton` under
  the main CTA. A timer running out is not a tap and is not undoable.
- **Double taps** — a Done or Skip within `AppConfig.advanceGuard` (500ms) of
  the previous move is ignored; runner events are handled one at a time.
- **Session detail** (`SessionDetailPage`, from a day-sheet row or a recent
  log): outcome badge, plan name (headline-lg), date, then **one line of
  totals** — never a hero metric block — whose figures wrap as units. Then one
  divided row per step: number, ✓ / skip mark, name, target, time in mono, and
  a heart icon + average BPM when recorded. Skipped rows recede and show "–"
  for time. Older sessions say plainly that step detail wasn't recorded.
  Outcomes read "Completed" / "Ended early" / "In progress" everywhere
  (`sessionOutcome`), never "abandoned".
- **Compared with last time** (`previousRun` + `SessionComparison`, shown by
  `ComparisonLine`): one muted line — "vs Wed 23: +3 min active · +2 done ·
  −4 avg BPM" — on the completion summary and under the session totals
  (tappable there, opening the earlier run). The baseline is the latest
  earlier session of the same plan *name* with at least one step done. Changes
  are neutral: only more steps done takes the peak colour. Step rows add
  "+0:15 · −4 BPM" or "skipped before" only where the same step sits in the
  same place. No earlier run: no line — no "first time!" hype. Real minus sign.
- **Glyphs in mono**: JetBrains Mono lacks symbols like ♥; use an `Icon`
  beside mono text, not a character inside it.
- **Calendar** — only session days are filled (`primaryContainer`); missed and
  future days are bare digits; today is a 2px `primary` ring. Absence must never
  outweigh what was done.
- **Empty states teach**: say what to do next and offer the action (the import
  help opens itself on first run).
- **First run without a file**: under the picker, a divider ("No workout file
  yet?") and an outlined **Try a sample workout** — secondary, because
  importing your own plan is the point. Offered only when no plan exists. The
  sample runs through the normal preview → Confirm & Save path and is labelled
  wherever it appears ("Built-in sample", `SAMPLE PLAN`, "Import your own plan
  from Settings.") so it never passes for an import.

### Motion (folded in here per the spec) — `GimmyMotion`

| Token | Duration | For |
|---|---|---|
| `press` / `release` | 90 / 160ms | a control acknowledging a finger |
| `stateChange` | 200ms | content swapping in place (step title cross-fade) |
| `tabChange` | 220ms | switching nav destinations |
| `pageTransition` / `Reverse` | 260 / 180ms | pushed pages; the completion summary's entrance |
| `pulse` | 1200ms | the live dot, the only repeating motion |

- Curves: `GimmyMotion.enter` (easeOutCubic) in, `exit` (easeInCubic) out.
  No bounce, no elastic, no spring overshoot.
- **Every animation checks `GimmyMotion.isReduced(context)`** and becomes a
  cut (duration zero, or the end state held still). No exceptions — including
  loops.
- Motion conveys state only: a press, a step change, a page arriving, the
  workout ending, the timer being live. No page-load choreography, no scroll
  reveals, no idle decoration.
- A widget that repaints every tick (the timer ring, the live dot) sits in a
  `RepaintBoundary`.
- Never use `pumpAndSettle` in tests of a page with a live dot; pump fixed
  durations long enough to clear the entrance (≥ 300ms).

## 6. Do's and Don'ts

**Do**
- Read every color, size, radius, gap, duration and curve from the theme,
  `GimmyTokens`, `GimmySpacing`, `GimmyRadii`, `GimmyLayout`, `GimmyType` or
  `GimmyMotion`.
- Give every tappable ≥ 44×44dp, a spoken label, and the right semantic flags
  (`button`, `selected`, `enabled`). Announce step changes to screen readers
  (`Semantics(liveRegion: true)` on the stage title).
- Put the changing number biggest, in mono with tabular figures.
- Keep the primary action in the thumb zone and the escape hatch (the header
  back arrow, Esc on desktop) out of it, behind a confirmation that says what
  will be kept.
- Write copy that is literally true about what was saved and what counts toward
  the streak.
- Use one name and one icon per destination across phone and desktop.
- Test both brightnesses and both themes; update goldens with
  `flutter test --update-goldens` after an intentional visual change.

**Don't**
- Hard-code a `Color(...)`, `fontSize:`, an off-scale `EdgeInsets`/`SizedBox`
  literal, or a `Duration(milliseconds: ...)` in a widget.
- Use `outline` as a text color, or `primaryContainer` as text in light mode.
- Nest a card in a card, or build an identical icon-heading-text card grid.
- Put a tiny uppercase eyebrow over every section; one "NEXT UP" on the runner
  earns its place, a kicker on every card does not.
- Use gradient text, glassmorphism, side-stripe borders, or radii above 16 on
  cards.
- Add motion that does not report a state change, or any animation that
  ignores reduce-motion.
- Clamp or disable text scaling, or give a text container a fixed height it
  cannot grow out of.
- Celebrate a workout where nothing was done, or say "nothing was recorded"
  when the session was saved.
- Bring back `InkSparkle` (first-tap shader stall) or reach for `print` instead
  of `AppLog`.
