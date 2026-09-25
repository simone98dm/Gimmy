import 'package:flutter/material.dart';

import 'gimmy_colors.dart';
import 'tokens.dart';

/// Design tokens that have no home in Material's `ColorScheme` or `TextTheme`
/// but still change between light and dark: the functional accent trio, the
/// per-intensity step colors, card/modal strokes, elevation shadows, and the
/// JetBrains Mono telemetry styles.
///
/// Read it with `GimmyTokens.of(context)` — never hard-code these values.
@immutable
class GimmyTokens extends ThemeExtension<GimmyTokens> {
  const GimmyTokens({
    required this.timerSafe,
    required this.timerWarning,
    required this.timerCritical,
    required this.intensityActive,
    required this.intensityRest,
    required this.intensityEasy,
    required this.cardBorder,
    required this.insetSurface,
    required this.modalSurface,
    required this.modalBorder,
    required this.cardShadow,
    required this.modalShadow,
    required this.chromeShadowColor,
    required this.activeGlow,
    required this.metricDisplay,
    required this.metricDisplayMobile,
    required this.metricLg,
    required this.metricMd,
    required this.labelMono,
  });

  /// Timer ring above [kTimerWarningThreshold] of the step's duration.
  final Color timerSafe;

  /// Timer ring between [kTimerCriticalThreshold] and [kTimerWarningThreshold].
  final Color timerWarning;

  /// Timer ring below [kTimerCriticalThreshold].
  final Color timerCritical;

  /// A working step.
  final Color intensityActive;

  /// A rest step between sets.
  final Color intensityRest;

  /// Warmup and cooldown share one muted tone.
  ///
  /// ponytail: the design system defines exactly three functional accents
  /// (peak / pacing / critical). Giving warmup and cooldown distinct hues would
  /// mean inventing colors it doesn't have, and the step label already names
  /// which one it is. Split them if the two ever need telling apart at a glance.
  final Color intensityEasy;

  final Color cardBorder;

  /// A recessed tile inside a card, sheet or dialog. Dark recesses darker than
  /// the card; light cannot (cards are already white), so it tints grey.
  final Color insetSurface;
  final Color modalSurface;
  final Color modalBorder;

  final List<BoxShadow> cardShadow;
  final List<BoxShadow> modalShadow;

  /// Ambient aura on the element that is currently live (a running timer).
  final List<BoxShadow> activeGlow;

  /// Shadow cast by the fixed header and bottom nav onto the content that
  /// scrolls under them. Only the color is a token — the header and the footer
  /// throw it in opposite directions.
  final Color chromeShadowColor;

  /// Tabular-lining mono styles. Used for anything that ticks: countdowns, rep
  /// counters, durations. Keeps digits from jittering as values change.
  final TextStyle metricDisplay;
  final TextStyle metricDisplayMobile;

  /// Secondary live readouts beside the countdown (heart rate).
  final TextStyle metricLg;
  final TextStyle metricMd;
  final TextStyle labelMono;

  /// Fraction of a timer step's duration below which the ring turns amber.
  static const double kTimerWarningThreshold = 0.5;

  /// Fraction below which the ring turns red.
  static const double kTimerCriticalThreshold = 0.2;

  static GimmyTokens of(BuildContext context) =>
      Theme.of(context).extension<GimmyTokens>()!;

  /// Picks the countdown color for [remaining] out of [total] seconds.
  ///
  /// A zero or negative [total] has no meaningful progress, so it reads as
  /// critical rather than dividing by zero.
  Color timerColorFor({
    required int remainingSeconds,
    required int totalSeconds,
  }) {
    if (totalSeconds <= 0) return timerCritical;
    final fraction = remainingSeconds / totalSeconds;
    if (fraction > kTimerWarningThreshold) return timerSafe;
    if (fraction > kTimerCriticalThreshold) return timerWarning;
    return timerCritical;
  }

  static const _monoDisplay = TextStyle(
    fontFamily: GimmyFonts.mono,
    fontSize: 44,
    height: 48 / 44,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Read from a phone on the floor, one to two metres away, mid-set.
  static const _monoDisplayMobile = TextStyle(
    fontFamily: GimmyFonts.mono,
    fontSize: 72,
    height: 1,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const _monoLg = TextStyle(
    fontFamily: GimmyFonts.mono,
    fontSize: 28,
    height: 1,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const _monoMd = TextStyle(
    fontFamily: GimmyFonts.mono,
    fontSize: 20,
    height: 24 / 20,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // 12, not 11: this carries the step counter and the next-up target, which
  // are read at arm's length mid-set.
  static const _monoLabel = TextStyle(
    fontFamily: GimmyFonts.mono,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    // Also sets lowercase values ("10 reps"), so only a touch; all-caps
    // labels add [GimmyType.capsTracking] themselves.
    letterSpacing: 0.5,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const _darkCardShadow = [
    BoxShadow(color: Color(0x66000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const _lightCardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4)),
  ];
  static const _darkModalShadow = [
    BoxShadow(color: Color(0x99000000), blurRadius: 32, offset: Offset(0, 12)),
  ];
  static const _lightModalShadow = [
    BoxShadow(color: Color(0x29000000), blurRadius: 32, offset: Offset(0, 12)),
  ];

  /// Builds the tokens for one theme × brightness. [colors] supplies
  /// everything that changes per theme; shadows and text styles only change
  /// with [brightness] (or not at all).
  ///
  /// `activeGlow` derives from `colors.scheme.primaryContainer` — the bright
  /// fill role, not [GimmyColors.accentPeak] (which is darkened for text
  /// contrast in light mode and would dim the glow). For green this reproduces
  /// today's hard-coded values exactly: dark 0x40 on #00E676, light 0x33 on
  /// #00C853 — both are that theme's `primaryContainer`.
  factory GimmyTokens.from(GimmyColors colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return GimmyTokens(
      timerSafe: colors.accentPeak,
      timerWarning: colors.accentPacing,
      timerCritical: colors.accentCritical,
      intensityActive: colors.accentPeak,
      intensityRest: colors.accentPacing,
      intensityEasy: colors.scheme.onSurfaceVariant,
      cardBorder: colors.cardBorder,
      insetSurface: isDark
          ? colors.scheme.surfaceContainerLow
          : colors.scheme.surfaceContainerHigh,
      modalSurface: colors.modalSurface,
      modalBorder: colors.modalBorder,
      cardShadow: isDark ? _darkCardShadow : _lightCardShadow,
      modalShadow: isDark ? _darkModalShadow : _lightModalShadow,
      activeGlow: [
        BoxShadow(
          color: colors.scheme.primaryContainer.withAlpha(isDark ? 0x40 : 0x33),
          blurRadius: 16,
        ),
      ],
      chromeShadowColor: isDark
          ? const Color(0x99000000)
          : const Color(0x1F000000),
      metricDisplay: _monoDisplay,
      metricDisplayMobile: _monoDisplayMobile,
      metricLg: _monoLg,
      metricMd: _monoMd,
      labelMono: _monoLabel,
    );
  }

  @override
  GimmyTokens copyWith({
    Color? timerSafe,
    Color? timerWarning,
    Color? timerCritical,
    Color? intensityActive,
    Color? intensityRest,
    Color? intensityEasy,
    Color? cardBorder,
    Color? insetSurface,
    Color? modalSurface,
    Color? modalBorder,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? modalShadow,
    List<BoxShadow>? activeGlow,
    Color? chromeShadowColor,
    TextStyle? metricDisplay,
    TextStyle? metricDisplayMobile,
    TextStyle? metricLg,
    TextStyle? metricMd,
    TextStyle? labelMono,
  }) {
    return GimmyTokens(
      timerSafe: timerSafe ?? this.timerSafe,
      timerWarning: timerWarning ?? this.timerWarning,
      timerCritical: timerCritical ?? this.timerCritical,
      intensityActive: intensityActive ?? this.intensityActive,
      intensityRest: intensityRest ?? this.intensityRest,
      intensityEasy: intensityEasy ?? this.intensityEasy,
      cardBorder: cardBorder ?? this.cardBorder,
      insetSurface: insetSurface ?? this.insetSurface,
      modalSurface: modalSurface ?? this.modalSurface,
      modalBorder: modalBorder ?? this.modalBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      modalShadow: modalShadow ?? this.modalShadow,
      activeGlow: activeGlow ?? this.activeGlow,
      chromeShadowColor: chromeShadowColor ?? this.chromeShadowColor,
      metricDisplay: metricDisplay ?? this.metricDisplay,
      metricDisplayMobile: metricDisplayMobile ?? this.metricDisplayMobile,
      metricLg: metricLg ?? this.metricLg,
      metricMd: metricMd ?? this.metricMd,
      labelMono: labelMono ?? this.labelMono,
    );
  }

  @override
  GimmyTokens lerp(covariant GimmyTokens? other, double t) {
    if (other == null) return this;
    return GimmyTokens(
      timerSafe: Color.lerp(timerSafe, other.timerSafe, t)!,
      timerWarning: Color.lerp(timerWarning, other.timerWarning, t)!,
      timerCritical: Color.lerp(timerCritical, other.timerCritical, t)!,
      intensityActive: Color.lerp(intensityActive, other.intensityActive, t)!,
      intensityRest: Color.lerp(intensityRest, other.intensityRest, t)!,
      intensityEasy: Color.lerp(intensityEasy, other.intensityEasy, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      insetSurface: Color.lerp(insetSurface, other.insetSurface, t)!,
      modalSurface: Color.lerp(modalSurface, other.modalSurface, t)!,
      modalBorder: Color.lerp(modalBorder, other.modalBorder, t)!,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      modalShadow: BoxShadow.lerpList(modalShadow, other.modalShadow, t)!,
      activeGlow: BoxShadow.lerpList(activeGlow, other.activeGlow, t)!,
      chromeShadowColor: Color.lerp(
        chromeShadowColor,
        other.chromeShadowColor,
        t,
      )!,
      metricDisplay: TextStyle.lerp(metricDisplay, other.metricDisplay, t)!,
      metricDisplayMobile: TextStyle.lerp(
        metricDisplayMobile,
        other.metricDisplayMobile,
        t,
      )!,
      metricLg: TextStyle.lerp(metricLg, other.metricLg, t)!,
      metricMd: TextStyle.lerp(metricMd, other.metricMd, t)!,
      labelMono: TextStyle.lerp(labelMono, other.labelMono, t)!,
    );
  }
}
