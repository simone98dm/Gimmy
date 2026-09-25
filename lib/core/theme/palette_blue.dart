import 'package:flutter/material.dart';

/// Raw color constants for the "Sophisticated Blue" theme
/// (`docs/DESIGN-blue.md`, design system *Kinetic Performance*).
///
/// Shaped exactly like [GimmyPalette] in `tokens.dart` — see that file for
/// what each role means. Nothing here is Flutter-theme-shaped yet; `AppTheme`
/// (via `gimmy_colors.dart`) assembles it into `ThemeData`.
///
/// Error roles are deliberately absent: the doc doesn't specify a blue error
/// palette and the M3 baseline error red the green theme already uses is
/// reused as-is for both brightnesses (`gimmy_colors.dart` reads it straight
/// off `GimmyPalette`).
abstract final class GimmyPaletteBlue {
  // ---------------------------------------------------------------------------
  // Dark — the YAML frontmatter in DESIGN-blue.md, verbatim.
  // ---------------------------------------------------------------------------
  static const darkSurface = Color(0xFF10131A);
  static const darkSurfaceDim = Color(0xFF10131A);
  static const darkSurfaceBright = Color(0xFF363940);
  static const darkSurfaceContainerLowest = Color(0xFF0B0E14);
  static const darkSurfaceContainerLow = Color(0xFF181C22);
  static const darkSurfaceContainer = Color(0xFF1C2026);
  static const darkSurfaceContainerHigh = Color(0xFF272A31);
  static const darkSurfaceContainerHighest = Color(0xFF31353C);
  static const darkOnSurface = Color(0xFFE0E2EB);
  static const darkOnSurfaceVariant = Color(0xFFC0C6D5);
  static const darkOutline = Color(0xFF8B919F);
  static const darkOutlineVariant = Color(0xFF414753);
  static const darkInverseSurface = Color(0xFFE0E2EB);
  static const darkInverseOnSurface = Color(0xFF2D3037);

  static const darkPrimary = Color(0xFFA7C8FF);
  static const darkOnPrimary = Color(0xFF003060);
  static const darkPrimaryContainer = Color(0xFF3591FD);
  // Frontmatter's on-primary-container measures 4.53:1 against
  // primaryContainer (>=4.5 kept, but only just) — leave it exactly as
  // given rather than second-guess a generated M3 palette.
  static const darkOnPrimaryContainer = Color(0xFF002A55);
  static const darkInversePrimary = Color(0xFF005EB2);

  static const darkSecondary = Color(0xFFACC8F7);
  static const darkOnSecondary = Color(0xFF113158);
  static const darkSecondaryContainer = Color(0xFF2E4A72);
  static const darkOnSecondaryContainer = Color(0xFF9EBAE8);

  static const darkTertiary = Color(0xFFFFB68F);
  static const darkOnTertiary = Color(0xFF542100);
  static const darkTertiaryContainer = Color(0xFFE66E1F);
  static const darkOnTertiaryContainer = Color(0xFF4A1C00);

  /// Borders/modal surface from the frontmatter's own
  /// surface-container-high/-highest and outline-variant — nothing invented.
  static const darkCardBorder = Color(0xFF31353C);
  static const darkModalSurface = Color(0xFF272A31);
  static const darkModalBorder = Color(0xFF414753);

  // ---------------------------------------------------------------------------
  // Light — the doc only gives prose for this mode. Neutral surfaces mirror
  // `GimmyPalette`'s light values exactly (both palettes were generated off
  // the same neutral scale); the accent-bearing roles come from the doc's
  // "Light Mode Support" section.
  // ---------------------------------------------------------------------------
  static const lightSurface = Color(0xFFFAFAFA);
  static const lightSurfaceDim = Color(0xFFEDEDED);
  static const lightSurfaceBright = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLow = Color(0xFFFFFFFF);
  static const lightSurfaceContainer = Color(0xFFFFFFFF);
  static const lightSurfaceContainerHigh = Color(0xFFF0F0F0);
  static const lightSurfaceContainerHighest = Color(0xFFE8E8E8);
  static const lightOnSurface = Color(0xFF121212);
  static const lightOnSurfaceVariant = Color(0xFF666666);
  static const lightOutline = Color(0xFF8A8A8A);
  static const lightOutlineVariant = Color(0xFFE5E5E5);
  static const lightInverseSurface = Color(0xFF2E2E2E);
  static const lightInverseOnSurface = Color(0xFFF5F5F5);

  /// The doc's "Primary Accent" #037CE7 measures ~4.0:1 against the light
  /// surfaces — under the 4.5:1 AA text bar (it's fine as a 3:1 graphic, just
  /// not as a foreground). `primary` is the M3 *foreground* role, so it's
  /// darkened ~20% toward black, holding the hue: 5.78:1 on #FAFAFA, 6.04:1
  /// on #FFFFFF. `primaryContainer` is the *fill* behind accent buttons, never
  /// a foreground itself — see below for why it is a step deeper than the doc.
  static const lightPrimary = Color(0xFF0263B8);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  // One step deeper than the doc's #037CE7, so white text holds on it:
  // near-black on a mid blue technically passed (4.59:1) but read as muddy on
  // every accent button. White on #037CE7 is only 4.17:1; on #0270D6 it is
  // 4.89:1, and the blue is visually the same.
  static const lightPrimaryContainer = Color(0xFF0270D6);
  static const lightOnPrimaryContainer = Color(0xFFFFFFFF);
  static const lightInversePrimary = darkPrimary;

  /// Already the doc's "adjusted for AA contrast" tone: 6.12:1 on #FAFAFA.
  static const lightSecondary = Color(0xFF4A6082);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFADB7C6);
  static const lightOnSecondaryContainer = Color(0xFF0F2038);

  /// The doc's light tertiary alert tone: 5.52:1 on #FAFAFA.
  static const lightTertiary = Color(0xFFA84A02);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFD7AD8D);
  static const lightOnTertiaryContainer = Color(0xFF3A1400);

  static const lightCardBorder = Color(0xFFE5E5E5);
  static const lightModalSurface = Color(0xFFFFFFFF);
  static const lightModalBorder = Color(0xFFDCDCDC);

  // ---------------------------------------------------------------------------
  // Functional accents — "peak / pacing / critical" per the design system,
  // same role [tokens.dart]'s emerald/amber/red trio plays for green. These
  // colour the timer ring, intensity labels and small mono text, so they need
  // the 4.5:1 text bar, not just the 3:1 graphics one.
  // ---------------------------------------------------------------------------
  /// The doc's dark accents (electric-blue/steel-blue/kinetic-orange) measure
  /// 3.65-4.46:1 against the dark surfaces — short of 4.5:1 as text, unlike
  /// green's much brighter dark accents. Lightened 20% toward white, holding
  /// hue, clears both `surface` and `surfaceContainer` at >=4.5:1.
  static const darkAccentPeak = Color(0xFF3596EB); // was #037CE7
  static const darkAccentPacing = Color(0xFF7D93B5); // was #5D78A3
  static const darkAccentCritical = Color(0xFFD47B35); // was #CA5A03

  /// `accentPeak` reuses [lightPrimary]'s darkened tone; pacing/critical are
  /// the doc's light accents verbatim (both already clear 4.5:1).
  static const lightAccentPeak = lightPrimary;
  static const lightAccentPacing = lightSecondary;
  static const lightAccentCritical = lightTertiary;
}
