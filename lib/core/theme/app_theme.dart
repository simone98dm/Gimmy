import 'package:flutter/material.dart';

import 'gimmy_tokens.dart';
import 'tokens.dart';

/// Assembles the Stitch design system into light and dark `ThemeData`.
///
/// Every widget in the app gets its colors and sizes from here, either through
/// `Theme.of(context)` or `GimmyTokens.of(context)`.
abstract final class AppTheme {
  static ThemeData get dark => _build(_darkScheme, GimmyTokens.dark);
  static ThemeData get light => _build(_lightScheme, GimmyTokens.light);

  static const _darkScheme = ColorScheme(
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

  static const _lightScheme = ColorScheme(
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

  /// Inter, mapped onto the Material slots the app actually uses.
  /// The JetBrains Mono telemetry styles live in [GimmyTokens].
  static const _textTheme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    headlineLarge: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
    ),
    headlineMedium: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    headlineSmall: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 18,
      height: 24 / 18,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w500,
    ),
    bodyMedium: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w400,
    ),
    labelMedium: TextStyle(
      fontFamily: GimmyFonts.sans,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );

  static ThemeData _build(ColorScheme scheme, GimmyTokens tokens) {
    final textTheme = _textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: GimmyFonts.sans,
      textTheme: textTheme,
      extensions: [tokens],
      // InkSparkle compiles a fragment shader the first time it is used, which
      // shows up as a stalled first tap. InkRipple is the cheap, boring one.
      splashFactory: InkRipple.splashFactory,
      dividerTheme: DividerThemeData(
        color: tokens.cardBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: GimmyRadii.card,
          side: BorderSide(color: tokens.cardBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          disabledBackgroundColor: scheme.surfaceContainerHigh,
          disabledForegroundColor: scheme.onSurfaceVariant,
          minimumSize: const Size.fromHeight(GimmyLayout.ctaHeight),
          shape: const RoundedRectangleBorder(borderRadius: GimmyRadii.button),
          textStyle: textTheme.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(GimmyLayout.ctaHeight),
          side: BorderSide(color: tokens.cardBorder, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: GimmyRadii.button),
          textStyle: textTheme.titleMedium,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          // Material defaults the selected segment to `secondaryContainer`,
          // which in this palette is the amber reserved for rest and warnings.
          // Selection is a primary state, so it takes the primary fill.
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primaryContainer
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.cardBorder)),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, GimmyLayout.minTapTarget),
          ),
        ),
      ),
      // Material's text and icon buttons default to 40px, under the 44px the
      // design system asks of every control.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelMedium,
          minimumSize: const Size.square(GimmyLayout.minTapTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(GimmyLayout.minTapTarget),
        ),
      ),
      iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.modalSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: GimmyRadii.card,
          side: BorderSide(color: tokens.modalBorder),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.modalSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GimmyRadii.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.modalSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: GimmyRadii.button),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GimmySpacing.md,
          vertical: GimmySpacing.xs,
        ),
      ),
    );
  }
}
