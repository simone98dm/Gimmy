import 'package:flutter/material.dart';

/// Raw design tokens extracted from the Stitch project "Minimal Flutter Gym App"
/// (design system: *Kinetic Performance*).
///
/// Nothing in here is Flutter-theme-shaped yet — these are the literal values.
/// [AppTheme] assembles them into `ThemeData`; widgets never read this file
/// directly, they read `Theme.of(context)` or `GimmyTokens.of(context)`.
abstract final class GimmyPalette {
  // ---------------------------------------------------------------------------
  // Dark (the mode the Stitch screens were designed in)
  // ---------------------------------------------------------------------------
  static const darkSurface = Color(0xFF131313);
  static const darkSurfaceDim = Color(0xFF131313);
  static const darkSurfaceBright = Color(0xFF393939);
  static const darkSurfaceContainerLowest = Color(0xFF0E0E0E);
  static const darkSurfaceContainerLow = Color(0xFF1C1B1B);
  static const darkSurfaceContainer = Color(0xFF201F1F);
  static const darkSurfaceContainerHigh = Color(0xFF2A2A2A);
  static const darkSurfaceContainerHighest = Color(0xFF353534);
  static const darkOnSurface = Color(0xFFE5E2E1);
  static const darkOnSurfaceVariant = Color(0xFFBACBB9);
  static const darkOutline = Color(0xFF859585);
  static const darkOutlineVariant = Color(0xFF3B4A3D);
  static const darkInverseSurface = Color(0xFFE5E2E1);
  static const darkInverseOnSurface = Color(0xFF313030);

  static const darkPrimary = Color(0xFF75FF9E);
  static const darkOnPrimary = Color(0xFF003918);
  static const darkPrimaryContainer = Color(0xFF00E676);
  static const darkOnPrimaryContainer = Color(0xFF00612E);
  static const darkInversePrimary = Color(0xFF006D35);

  static const darkSecondary = Color(0xFFFFF3D2);
  static const darkOnSecondary = Color(0xFF3A3000);
  static const darkSecondaryContainer = Color(0xFFFDD400);
  static const darkOnSecondaryContainer = Color(0xFF6F5C00);

  static const darkTertiary = Color(0xFFFFDDD5);
  static const darkOnTertiary = Color(0xFF621100);
  static const darkTertiaryContainer = Color(0xFFFFB7A5);
  static const darkOnTertiaryContainer = Color(0xFFA12300);

  static const darkError = Color(0xFFFFB4AB);
  static const darkOnError = Color(0xFF690005);
  static const darkErrorContainer = Color(0xFF93000A);
  static const darkOnErrorContainer = Color(0xFFFFDAD6);

  /// Hairline stroke on cards. The design doc specifies this separately from
  /// `outline-variant`, which is too green for a 1px structural line.
  static const darkCardBorder = Color(0xFF2C2C2C);
  static const darkModalSurface = Color(0xFF242424);
  static const darkModalBorder = Color(0xFF383838);

  // ---------------------------------------------------------------------------
  // Light (documented in the design system's prose; no Stitch screen uses it)
  // ---------------------------------------------------------------------------
  /// In M3 terms `primary` is the *foreground* accent and `primaryContainer`
  /// the bright fill. The design doc's single "#00C853 primary accent" is the
  /// fill; the foreground has to be darker to survive a white background.
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

  static const lightPrimary = Color(0xFF006D35);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightPrimaryContainer = Color(0xFF00C853);
  static const lightOnPrimaryContainer = Color(0xFF00210B);
  static const lightInversePrimary = Color(0xFF75FF9E);

  static const lightSecondary = Color(0xFF6F5C00);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightSecondaryContainer = Color(0xFFF5B800);
  static const lightOnSecondaryContainer = Color(0xFF231B00);

  static const lightTertiary = Color(0xFFC62300);
  static const lightOnTertiary = Color(0xFFFFFFFF);
  static const lightTertiaryContainer = Color(0xFFFFDAD4);
  static const lightOnTertiaryContainer = Color(0xFF410000);

  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  static const lightCardBorder = Color(0xFFE5E5E5);
  static const lightModalSurface = Color(0xFFFFFFFF);
  static const lightModalBorder = Color(0xFFDCDCDC);

  // ---------------------------------------------------------------------------
  // Functional accents — identical role in both modes, different tone.
  // "Peak / pacing / critical" per the design system.
  //
  // The light tones are darker than the ones the design doc names (#00C853 /
  // #F5B800 / #D50000). Those are used as *foregrounds* here — the timer ring,
  // the countdown digits, intensity labels — and against #FAFAFA they measure
  // 2.14 / 1.71 / 5.25 contrast. The first two fail even the 3:1 bar for
  // graphics. These replacements hold the same hues at >=4.5:1, since they colour small
  // labels as well as graphics.
  // ---------------------------------------------------------------------------
  static const darkAccentEmerald = Color(0xFF00E676);
  static const darkAccentAmber = Color(0xFFFFD600);
  static const darkAccentRed = Color(0xFFFF3D00);

  /// The logo mark is brand-fixed: the same tile and accent in both themes.
  static const logoTile = Color(0xFF121212);
  static const logoAccent = Color(0xFF00E676);

  static const lightAccentEmerald = Color(0xFF007A34);
  static const lightAccentAmber = Color(0xFF8A6200);
  static const lightAccentRed = Color(0xFFC62300);
}

/// 8px base grid, collapsing to 4px for badge padding and tabular cells.
abstract final class GimmySpacing {
  /// Hairline gap between a title and the line directly under it.
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;

  /// Between [sm] and [md]: pill padding, the gap beside a leading icon tile.
  static const double ms = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Horizontal screen margin on mobile.
  static const double gutter = 16;
}

abstract final class GimmyRadii {
  static const double sm = 4;
  static const double md = 8;

  /// Buttons and tactical inputs.
  static const double lg = 12;

  /// Primary cards and containers — the signature radius.
  static const double xl = 16;
  static const double pill = 9999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius button = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius cell = BorderRadius.all(Radius.circular(md));
}

/// Fixed chrome dimensions shared by every page.
abstract final class GimmyLayout {
  static const double headerHeight = 64;
  static const double footerHeight = 64;

  /// Minimum tap target — the design system calls for thumb operation with
  /// sweaty hands, and WCAG 2.2 asks for 44px.
  static const double minTapTarget = 44;

  /// Primary CTA height, sized for tapping under fatigue.
  static const double ctaHeight = 52;

  /// From this width the web build swaps the bottom nav for a sidebar and
  /// lays pages out in columns, as the Stitch desktop screens do.
  static const double desktopBreakpoint = 1200;

  static const double sidebarWidth = 288;

  /// Content stops growing here; past it the extra width is background.
  static const double desktopMaxContentWidth = 1280;

  /// Prose pages (About, Legal) stop here: about 75 characters a line.
  static const double readingWidth = 680;
}

/// Type details that are not a size, so have no home in `TextTheme`.
abstract final class GimmyType {
  /// Tracking for every all-caps label, sans or mono: about 10% of a 12px cap.
  /// One value, so caps read as one voice across the app.
  static const double capsTracking = 1.2;
}

abstract final class GimmyFonts {
  static const String sans = 'Inter';
  static const String mono = 'JetBrains Mono';
}
