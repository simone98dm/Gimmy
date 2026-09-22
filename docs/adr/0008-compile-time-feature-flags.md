# 8. Compile-time flags for metrics with no data

Date: 2026-09-22

## Status

Accepted.

## Context

The design shows heart rate, calories burned and perceived effort during a workout. The app has no
heart-rate strap, no calorie model, and no way to ask for an RPE. Every one of those numbers would
be invented.

The brief asked for the components to be built but hidden behind flags that default to off, with
all flags in one config file.

## Decision

Compile-time constants in `lib/core/config/feature_flags.dart`:

```dart
static const bool showBpm = false;
static const bool showCalories = false;
static const bool showEffort = false;
```

The metric strip is built, styled and positioned. It renders nothing while the flags are off, and
the surrounding spacing collapses with it so there is no empty band.

## Consequences

Turning a metric on is a one-line change once a real source exists, and the UI is already designed
and laid out for it.

Because they are `const`, the hidden widgets are tree-shaken out of release builds entirely.

They are not user-facing settings. A switch in Settings would imply the app could show the number
if asked, which it cannot. `AppSettings` deliberately does not carry them, despite the data model
in the brief listing feature flags under settings — the config file is the single place they live.
