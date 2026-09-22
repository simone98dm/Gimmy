# 5. Departing from the design system's light palette

Date: 2026-09-22

## Status

Accepted.

## Context

The design system is dark-first and documents a light variant, naming `#00C853` as the primary
accent, `#F5B800` as the secondary, and `#D50000` as the alert — the last described as "darkened
golden amber for AA text contrast compliance".

In this app those accents are used as **foregrounds**: the timer ring, the countdown digits, the
active nav label, intensity markers. Measured against the light background `#FAFAFA`:

| Token | Contrast | Verdict |
| --- | --- | --- |
| `#00C853` | 2.14:1 | fails |
| `#F5B800` | 1.71:1 | fails |
| `#D50000` | 5.25:1 | passes |

The first two fail even the 3:1 bar for graphical objects, let alone 4.5:1 for text. The claim of
AA compliance does not hold when the colour is the ink rather than the fill.

## Decision

Keep the hues, darken the light-mode tones until they pass: emerald `#00873A`, amber `#8A6200`,
red `#C62300`, all at 4.4:1 or better. In Material terms `primary` became the dark foreground tone
and `primaryContainer` kept the bright fill, which is how the roles are meant to be used — the
active nav item now takes `primary`, not `primaryContainer`.

Dark mode is untouched; its documented values already pass comfortably.

## Consequences

Light mode is slightly more muted than the design file. This is a deliberate, documented departure,
not drift.

`test/core/theme/contrast_test.dart` computes WCAG ratios from the real `ColorScheme` for both
themes and fails the build if any pairing regresses. The palette had already regressed once before
that test existed.
