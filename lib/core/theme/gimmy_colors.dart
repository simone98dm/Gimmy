import 'package:flutter/material.dart';

import 'gimmy_theme_id.dart';
import 'palette_blue.dart';
import 'tokens.dart';

/// A complete color set for one theme × one brightness: the M3 [ColorScheme]
/// handed to `ThemeData`, plus the roles M3 has no slot for but the app still
/// themes — the functional accent trio and the card/modal strokes.
///
/// [GimmyTokens.from] turns one of these into the [ThemeExtension] widgets
/// actually read.
@immutable
class GimmyColors {
  const GimmyColors({
    required this.scheme,
    required this.accentPeak,
    required this.accentPacing,
    required this.accentCritical,
    required this.cardBorder,
    required this.modalSurface,
    required this.modalBorder,
  });

  final ColorScheme scheme;

  /// Peak effort: the timer ring above its warning threshold, a working step.
  final Color accentPeak;

  /// Pacing: the timer ring mid-countdown, a rest step.
  final Color accentPacing;

  /// Critical: the timer ring in its last stretch.
  final Color accentCritical;

  final Color cardBorder;
  final Color modalSurface;
  final Color modalBorder;
}

/// [id]'s palette for [brightness]. One switch, not one per field — adding a
/// theme means adding a palette file and a case here, not touching every
/// call site that reads a color.
GimmyColors gimmyColorsFor(GimmyThemeId id, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  switch (id) {
    case GimmyThemeId.hackerGreen:
      return isDark ? _greenDark : _greenLight;
    case GimmyThemeId.sophisticatedBlue:
      return isDark ? _blueDark : _blueLight;
  }
}

const _greenDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: GimmyPalette.darkPrimary,
  onPrimary: GimmyPalette.darkOnPrimary,
  primaryContainer: GimmyPalette.darkPrimaryContainer,
  onPrimaryContainer: GimmyPalette.darkOnPrimaryContainer,
  inversePrimary: GimmyPalette.darkInversePrimary,
  secondary: GimmyPalette.darkSecondary,
  onSecondary: GimmyPalette.darkOnSecondary,
  secondaryContainer: GimmyPalette.darkSecondaryContainer,
  onSecondaryContainer: GimmyPalette.darkOnSecondaryContainer,
  tertiary: GimmyPalette.darkTertiary,
  onTertiary: GimmyPalette.darkOnTertiary,
  tertiaryContainer: GimmyPalette.darkTertiaryContainer,
  onTertiaryContainer: GimmyPalette.darkOnTertiaryContainer,
  error: GimmyPalette.darkError,
  onError: GimmyPalette.darkOnError,
  errorContainer: GimmyPalette.darkErrorContainer,
  onErrorContainer: GimmyPalette.darkOnErrorContainer,
  surface: GimmyPalette.darkSurface,
  onSurface: GimmyPalette.darkOnSurface,
  surfaceDim: GimmyPalette.darkSurfaceDim,
  surfaceBright: GimmyPalette.darkSurfaceBright,
  surfaceContainerLowest: GimmyPalette.darkSurfaceContainerLowest,
  surfaceContainerLow: GimmyPalette.darkSurfaceContainerLow,
  surfaceContainer: GimmyPalette.darkSurfaceContainer,
  surfaceContainerHigh: GimmyPalette.darkSurfaceContainerHigh,
  surfaceContainerHighest: GimmyPalette.darkSurfaceContainerHighest,
  onSurfaceVariant: GimmyPalette.darkOnSurfaceVariant,
  outline: GimmyPalette.darkOutline,
  outlineVariant: GimmyPalette.darkOutlineVariant,
  inverseSurface: GimmyPalette.darkInverseSurface,
  onInverseSurface: GimmyPalette.darkInverseOnSurface,
);

const _greenLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: GimmyPalette.lightPrimary,
  onPrimary: GimmyPalette.lightOnPrimary,
  primaryContainer: GimmyPalette.lightPrimaryContainer,
  onPrimaryContainer: GimmyPalette.lightOnPrimaryContainer,
  inversePrimary: GimmyPalette.lightInversePrimary,
  secondary: GimmyPalette.lightSecondary,
  onSecondary: GimmyPalette.lightOnSecondary,
  secondaryContainer: GimmyPalette.lightSecondaryContainer,
  onSecondaryContainer: GimmyPalette.lightOnSecondaryContainer,
  tertiary: GimmyPalette.lightTertiary,
  onTertiary: GimmyPalette.lightOnTertiary,
  tertiaryContainer: GimmyPalette.lightTertiaryContainer,
  onTertiaryContainer: GimmyPalette.lightOnTertiaryContainer,
  error: GimmyPalette.lightError,
  onError: GimmyPalette.lightOnError,
  errorContainer: GimmyPalette.lightErrorContainer,
  onErrorContainer: GimmyPalette.lightOnErrorContainer,
  surface: GimmyPalette.lightSurface,
  onSurface: GimmyPalette.lightOnSurface,
  surfaceDim: GimmyPalette.lightSurfaceDim,
  surfaceBright: GimmyPalette.lightSurfaceBright,
  surfaceContainerLowest: GimmyPalette.lightSurfaceContainerLowest,
  surfaceContainerLow: GimmyPalette.lightSurfaceContainerLow,
  surfaceContainer: GimmyPalette.lightSurfaceContainer,
  surfaceContainerHigh: GimmyPalette.lightSurfaceContainerHigh,
  surfaceContainerHighest: GimmyPalette.lightSurfaceContainerHighest,
  onSurfaceVariant: GimmyPalette.lightOnSurfaceVariant,
  outline: GimmyPalette.lightOutline,
  outlineVariant: GimmyPalette.lightOutlineVariant,
  inverseSurface: GimmyPalette.lightInverseSurface,
  onInverseSurface: GimmyPalette.lightInverseOnSurface,
);

// Blue has no doc-specified error palette; the M3 baseline error red is
// shared with green in both brightnesses (dark even matches the design
// doc's own frontmatter values digit for digit).
const _blueDarkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: GimmyPaletteBlue.darkPrimary,
  onPrimary: GimmyPaletteBlue.darkOnPrimary,
  primaryContainer: GimmyPaletteBlue.darkPrimaryContainer,
  onPrimaryContainer: GimmyPaletteBlue.darkOnPrimaryContainer,
  inversePrimary: GimmyPaletteBlue.darkInversePrimary,
  secondary: GimmyPaletteBlue.darkSecondary,
  onSecondary: GimmyPaletteBlue.darkOnSecondary,
  secondaryContainer: GimmyPaletteBlue.darkSecondaryContainer,
  onSecondaryContainer: GimmyPaletteBlue.darkOnSecondaryContainer,
  tertiary: GimmyPaletteBlue.darkTertiary,
  onTertiary: GimmyPaletteBlue.darkOnTertiary,
  tertiaryContainer: GimmyPaletteBlue.darkTertiaryContainer,
  onTertiaryContainer: GimmyPaletteBlue.darkOnTertiaryContainer,
  error: GimmyPalette.darkError,
  onError: GimmyPalette.darkOnError,
  errorContainer: GimmyPalette.darkErrorContainer,
  onErrorContainer: GimmyPalette.darkOnErrorContainer,
  surface: GimmyPaletteBlue.darkSurface,
  onSurface: GimmyPaletteBlue.darkOnSurface,
  surfaceDim: GimmyPaletteBlue.darkSurfaceDim,
  surfaceBright: GimmyPaletteBlue.darkSurfaceBright,
  surfaceContainerLowest: GimmyPaletteBlue.darkSurfaceContainerLowest,
  surfaceContainerLow: GimmyPaletteBlue.darkSurfaceContainerLow,
  surfaceContainer: GimmyPaletteBlue.darkSurfaceContainer,
  surfaceContainerHigh: GimmyPaletteBlue.darkSurfaceContainerHigh,
  surfaceContainerHighest: GimmyPaletteBlue.darkSurfaceContainerHighest,
  onSurfaceVariant: GimmyPaletteBlue.darkOnSurfaceVariant,
  outline: GimmyPaletteBlue.darkOutline,
  outlineVariant: GimmyPaletteBlue.darkOutlineVariant,
  inverseSurface: GimmyPaletteBlue.darkInverseSurface,
  onInverseSurface: GimmyPaletteBlue.darkInverseOnSurface,
);

const _blueLightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: GimmyPaletteBlue.lightPrimary,
  onPrimary: GimmyPaletteBlue.lightOnPrimary,
  primaryContainer: GimmyPaletteBlue.lightPrimaryContainer,
  onPrimaryContainer: GimmyPaletteBlue.lightOnPrimaryContainer,
  inversePrimary: GimmyPaletteBlue.lightInversePrimary,
  secondary: GimmyPaletteBlue.lightSecondary,
  onSecondary: GimmyPaletteBlue.lightOnSecondary,
  secondaryContainer: GimmyPaletteBlue.lightSecondaryContainer,
  onSecondaryContainer: GimmyPaletteBlue.lightOnSecondaryContainer,
  tertiary: GimmyPaletteBlue.lightTertiary,
  onTertiary: GimmyPaletteBlue.lightOnTertiary,
  tertiaryContainer: GimmyPaletteBlue.lightTertiaryContainer,
  onTertiaryContainer: GimmyPaletteBlue.lightOnTertiaryContainer,
  error: GimmyPalette.lightError,
  onError: GimmyPalette.lightOnError,
  errorContainer: GimmyPalette.lightErrorContainer,
  onErrorContainer: GimmyPalette.lightOnErrorContainer,
  surface: GimmyPaletteBlue.lightSurface,
  onSurface: GimmyPaletteBlue.lightOnSurface,
  surfaceDim: GimmyPaletteBlue.lightSurfaceDim,
  surfaceBright: GimmyPaletteBlue.lightSurfaceBright,
  surfaceContainerLowest: GimmyPaletteBlue.lightSurfaceContainerLowest,
  surfaceContainerLow: GimmyPaletteBlue.lightSurfaceContainerLow,
  surfaceContainer: GimmyPaletteBlue.lightSurfaceContainer,
  surfaceContainerHigh: GimmyPaletteBlue.lightSurfaceContainerHigh,
  surfaceContainerHighest: GimmyPaletteBlue.lightSurfaceContainerHighest,
  onSurfaceVariant: GimmyPaletteBlue.lightOnSurfaceVariant,
  outline: GimmyPaletteBlue.lightOutline,
  outlineVariant: GimmyPaletteBlue.lightOutlineVariant,
  inverseSurface: GimmyPaletteBlue.lightInverseSurface,
  onInverseSurface: GimmyPaletteBlue.lightInverseOnSurface,
);

const _greenDark = GimmyColors(
  scheme: _greenDarkScheme,
  accentPeak: GimmyPalette.darkAccentEmerald,
  accentPacing: GimmyPalette.darkAccentAmber,
  accentCritical: GimmyPalette.darkAccentRed,
  cardBorder: GimmyPalette.darkCardBorder,
  modalSurface: GimmyPalette.darkModalSurface,
  modalBorder: GimmyPalette.darkModalBorder,
);

const _greenLight = GimmyColors(
  scheme: _greenLightScheme,
  accentPeak: GimmyPalette.lightAccentEmerald,
  accentPacing: GimmyPalette.lightAccentAmber,
  accentCritical: GimmyPalette.lightAccentRed,
  cardBorder: GimmyPalette.lightCardBorder,
  modalSurface: GimmyPalette.lightModalSurface,
  modalBorder: GimmyPalette.lightModalBorder,
);

const _blueDark = GimmyColors(
  scheme: _blueDarkScheme,
  accentPeak: GimmyPaletteBlue.darkAccentPeak,
  accentPacing: GimmyPaletteBlue.darkAccentPacing,
  accentCritical: GimmyPaletteBlue.darkAccentCritical,
  cardBorder: GimmyPaletteBlue.darkCardBorder,
  modalSurface: GimmyPaletteBlue.darkModalSurface,
  modalBorder: GimmyPaletteBlue.darkModalBorder,
);

const _blueLight = GimmyColors(
  scheme: _blueLightScheme,
  accentPeak: GimmyPaletteBlue.lightAccentPeak,
  accentPacing: GimmyPaletteBlue.lightAccentPacing,
  accentCritical: GimmyPaletteBlue.lightAccentCritical,
  cardBorder: GimmyPaletteBlue.lightCardBorder,
  modalSurface: GimmyPaletteBlue.lightModalSurface,
  modalBorder: GimmyPaletteBlue.lightModalBorder,
);
