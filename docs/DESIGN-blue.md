---
name: Kinetic Performance
colors:
  surface: '#10131a'
  surface-dim: '#10131a'
  surface-bright: '#363940'
  surface-container-lowest: '#0b0e14'
  surface-container-low: '#181c22'
  surface-container: '#1c2026'
  surface-container-high: '#272a31'
  surface-container-highest: '#31353c'
  on-surface: '#e0e2eb'
  on-surface-variant: '#c0c6d5'
  inverse-surface: '#e0e2eb'
  inverse-on-surface: '#2d3037'
  outline: '#8b919f'
  outline-variant: '#414753'
  surface-tint: '#a7c8ff'
  primary: '#a7c8ff'
  on-primary: '#003060'
  primary-container: '#3591fd'
  on-primary-container: '#002a55'
  inverse-primary: '#005eb2'
  secondary: '#acc8f7'
  on-secondary: '#113158'
  secondary-container: '#2e4a72'
  on-secondary-container: '#9ebae8'
  tertiary: '#ffb68f'
  on-tertiary: '#542100'
  tertiary-container: '#e66e1f'
  on-tertiary-container: '#4a1c00'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a7c8ff'
  on-primary-fixed: '#001b3c'
  on-primary-fixed-variant: '#004788'
  secondary-fixed: '#d5e3ff'
  secondary-fixed-dim: '#acc8f7'
  on-secondary-fixed: '#001b3b'
  on-secondary-fixed-variant: '#2b476f'
  tertiary-fixed: '#ffdbca'
  tertiary-fixed-dim: '#ffb68f'
  on-tertiary-fixed: '#331100'
  on-tertiary-fixed-variant: '#773200'
  background: '#10131a'
  on-background: '#e0e2eb'
  surface-variant: '#31353c'
typography:
  headline-xl:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
  headline-xl-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '800'
    lineHeight: 36px
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  metric-display:
    fontFamily: JetBrains Mono
    fontSize: 44px
    fontWeight: '700'
    lineHeight: 48px
  metric-display-mobile:
    fontFamily: JetBrains Mono
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 36px
  metric-md:
    fontFamily: JetBrains Mono
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-mono:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  gutter-desktop: 2rem
  margin: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system projects elite athletic performance, technical precision, and unrelenting drive. Engineered for high-intensity training environments and real-time workout tracking, the interface emphasizes immediate legibility, high tactile responsiveness, and zero friction.

### Visual Style
- **High-Contrast Precision:** Crisp, high-contrast visual hierarchy tuned for rapid glanceability under motion and outdoor lighting.
- **Modern Technical Minimalism:** Dense information architecture without clutter, using purposeful blue and amber accents against deep carbon backdrops.
- **Engineered Ergonomics:** Large thumb-accessible interactive zones, distinct telemetry modules, and micro-interactions calibrated for sweaty hands and active motion.

## Colors

The palette balances energy with functional clarity, anchored by deep carbon surfaces and high-voltage functional accents.

### Dark Mode (Default)
- **Background (`surface-base`):** `#121212` — Deep carbon black preventing eye strain in dim gym facilities.
- **Card/Surface (`surface-card`):** `#1E1E1E` — Elevated dark gray for modular training cards.
- **Surface Highlight (`surface-elevated`):** `#2A2A2A` — Modals, interactive state containers, and nested metrics.
- **Borders (`border-subtle`):** `#2C2C2C` — Ultra-fine structural separation lines.
- **Primary Accent (`electric-blue`):** `#037CE7` — Peak energy action targets, active timers, successful PRs, and completion states.
- **Secondary Accent (`steel-blue`):** `#5D78A3` — Rest periods, active working sets, warning indicators, and pacing telemetry.
- **Tertiary Alert (`kinetic-orange`):** `#CA5A03` — Heart rate max zones, failure thresholds, critical limits, and destruct action triggers.
- **Text Primary:** `#FFFFFF` — 100% white for optimal legibility.
- **Text Secondary:** `#A0A0A0` — Medium contrast for secondary labels, workout metadata, and inactive set counts.

### Light Mode Support
- **Background (`surface-base`):** `#FAFAFA` — Clean neutral canvas.
- **Card/Surface (`surface-card`):** `#FFFFFF` — Pure white with hairline `#E5E5E5` borders.
- **Surface Highlight (`surface-elevated`):** `#F0F0F0` — Recessed input metrics and control bars.
- **Primary Accent:** `#037CE7` — Adjusted tone for contrast against white backgrounds.
- **Secondary Accent:** `#4A6082` — Darkened blue for AA text contrast compliance.
- **Tertiary Alert:** `#A84A02` — Punchy alert tone for light backdrops.
- **Text Primary:** `#121212` — Rich black typography.
- **Text Secondary:** `#666666` — Muted supporting labels.

## Typography

Typography prioritizes high-speed scanning through dual typeface orchestration:
- **Inter** handles all narrative, body, hierarchy, headers, and UI instructions. It delivers neutral geometry, high x-height, and tight letter spacing at bold weights.
- **JetBrains Mono** renders stopwatch tickers, rep counters, rest periods, heart rate telemetry, and weight statistics. Tabular lining numbers ensure static positioning during live data streaming without jitter.

## Layout & Spacing

A compact, thumb-driven fluid layout optimized for single-hand mobile operation on the gym floor.

### Rhythm & Grid
- **Mobile (<600px):** 4-column fluid layout with `16px` margins and `16px` gutters. Primary actions anchored inside the bottom 35% thumb zone.
- **Tablet (600px–1024px):** 8-column layout with split-screen workout session views (routine tree on the left, active set logger on the right).
- **Desktop (>1024px):** 12-column layout centered at maximum 1280px container width for coach dashboards and analytics overviews.
- Vertical rhythm follows an explicit 8px base grid, collapsing to 4px increments strictly for badge padding and tabular metric cells.

## Elevation & Depth

Depth is defined through stacked planar dark neutrals and crisp, low-contrast structural outlines rather than heavy drop shadows.

- **Level 0 (Canvas):** Pure `#121212` background.
- **Level 1 (Cards & Data Modules):** `#1E1E1E` surface with a `1px` border of `#2C2C2C`. Subtle ambient glow applied only to active cards: `0 4px 20px rgba(0, 0, 0, 0.4)`.
- **Level 2 (Modals, Overlays & Sticky Sheets):** `#242424` with a `1px` border of `#383838` and a deep shadow: `0 12px 32px rgba(0, 0, 0, 0.6)`.
- **Active State Aura:** Elements with focus or ongoing live tracking (such as an active workout set) gain a calibrated 1px accent outline `#037CE7` and an optional ambient glow: `0 0 16px rgba(3, 124, 231, 0.25)`.

## Shapes

The interface embraces a unified 16px corner radius for primary interaction targets and workout cards, creating a streamlined, modern industrial silhouette.

- **Primary Cards & Containers:** `16px` (`rounded-lg`) corner radii for all modular components.
- **Buttons & Tactical Inputs:** `12px` to `16px` corners, maintaining proportional balance.
- **Pills & Status Tags:** Fully rounded pill shapes (`9999px`) for set tags, timers, and state chips.
- **Data Cells:** `8px` (`rounded-md`) internal nested containers within primary cards.

## Components

### Buttons
- **Primary Action (CTA):** High-voltage `#037CE7` background, `#121212` bold typography, 52px height for thumb-tapping during fatigue. Roundedness `16px`. Active press scales down slightly (`transform: scale(0.98)`).
- **Secondary Action:** Transparent background with a `1.5px` border in `#2C2C2C`, white text, and hover/active fill of `#242424`.
- **Destructive/Stop Action:** Tinted `#CA5A03` with 15% opacity fill, solid `#CA5A03` text, and border.

### Workout Cards
- Built with a `#1E1E1E` surface and `16px` corner radii with a `1px` `#2C2C2C` stroke.
- Header row features exercise name (`Inter 18px Bold`), equipment type badge (`JetBrains Mono 11px`), and context menu trigger.
- Body displays historical PR markers alongside current set matrix rows.

### Chips & Badges
- **Status Pills:** 28px height, `9999px` border radius, padding `4px 12px`.
- **Rest Timer Chip:** `#5D78A3` background at 12% opacity, `#5D78A3` text in `JetBrains Mono 12px`, with an animated radial sweep icon.

### Form Inputs & Set Loggers
- Numeric weight and rep counter fields feature centered `JetBrains Mono` figures, elevated `#2A2A2A` background, and quick stepper touch triggers (`+` / `-`) on card flanks.
- Focus state activates a distinct `1.5px` `#037CE7` border ring.

### Metric Tiles & Telemetry Rings
- Compact grid modules displaying Heart Rate, Total Volume (kg/lbs), and RPE (Rate of Perceived Exertion).
- Top label in muted uppercase (`Inter 11px SemiBold`), metric value in oversized `JetBrains Mono`, and bottom change delta with color-coded status arrow.