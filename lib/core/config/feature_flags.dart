/// Every feature flag and tunable constant in the app, in one place.
///
/// The metric flags gate UI that is fully built but has no real data source
/// behind it yet (no calorie model, no RPE prompt). Flip one to `true` and the
/// component appears on the Execution page. BPM needs no flag: its tile shows
/// whenever a heart-rate sensor is paired.
abstract final class FeatureFlags {
  /// Calories-burned tile on the Execution page.
  static const bool showCalories = false;

  /// Perceived-effort (RPE) tile on the Execution page.
  static const bool showEffort = false;

  /// True when at least one flagged metric tile is visible, so the Execution
  /// page can drop the whole row (and its spacing) rather than render an empty
  /// band.
  static bool get showAnyMetric => showCalories || showEffort;
}

/// Tunables that are not feature switches but also should not be scattered
/// across widgets as magic numbers.
abstract final class AppConfig {
  /// Shown on the About and Legal pages. Bumped by release-please together
  /// with `version:` in pubspec.yaml — do not edit by hand.
  static const String appVersion = '1.2.0'; // x-release-please-version

  /// Who built it: the About page credit and the copyright line.
  static const String author = 'simone98dm';

  /// Seconds subtracted by the −10s control on a running timer step.
  static const int timerAdjustmentSeconds = 10;

  /// How long one repetition is assumed to take, used **only** to estimate a
  /// plan's total duration in the import preview.
  ///
  /// FIT rep-based steps carry no duration, so there is nothing to read from
  /// the file. Execution never uses this — reps steps advance on user input.
  static const int estimatedSecondsPerRep = 3;

  /// Gaussian sigma for the frosted header and bottom nav.
  ///
  /// `BackdropFilter` re-filters everything painted behind it on every frame,
  /// which makes it by far the most expensive thing the app draws while a long
  /// list is scrolling under it — and the iOS Simulator has no fast path for
  /// it at all. The design asks for `backdrop-blur-xl` over an 85%-opaque bar,
  /// where most of the frosting comes from the opacity rather than the blur,
  /// so a smaller radius costs almost nothing visually.
  ///
  /// Off by default. Raise it to 8–16 for the full frosted look on hardware
  /// that can afford it; the bars stay translucent either way.
  static const double chromeBlurSigma = 0;

  /// Guard against a malformed or hostile FIT file whose repeat steps expand
  /// into an unbounded plan. The sample expands to 54 steps; this is far above
  /// any real workout while still bounding the work.
  static const int maxExpandedSteps = 2000;
}
