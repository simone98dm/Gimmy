import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/theme/gimmy_theme_id.dart';
import 'package:gimmy/core/theme/gimmy_tokens.dart';

void main() {
  group('timerColorFor', () {
    // Pure fraction-of-duration logic — theme-independent, so any one
    // theme's tokens exercise it.
    final tokens = AppTheme.dark.extension<GimmyTokens>()!;

    test('is safe above 50% of the step remaining', () {
      // Arrange
      const total = 60;

      // Act
      final color = tokens.timerColorFor(
        remainingSeconds: 31,
        totalSeconds: total,
      );

      // Assert
      expect(color, tokens.timerSafe);
    });

    test('is warning at exactly 50% remaining', () {
      final color = tokens.timerColorFor(
        remainingSeconds: 30,
        totalSeconds: 60,
      );

      expect(color, tokens.timerWarning);
    });

    test('is warning between 20% and 50% remaining', () {
      final color = tokens.timerColorFor(
        remainingSeconds: 15,
        totalSeconds: 60,
      );

      expect(color, tokens.timerWarning);
    });

    test('is critical at exactly 20% remaining', () {
      final color = tokens.timerColorFor(
        remainingSeconds: 12,
        totalSeconds: 60,
      );

      expect(color, tokens.timerCritical);
    });

    test('is critical at zero remaining', () {
      final color = tokens.timerColorFor(remainingSeconds: 0, totalSeconds: 60);

      expect(color, tokens.timerCritical);
    });

    test(
      'is critical when the step has no duration, instead of dividing by zero',
      () {
        final color = tokens.timerColorFor(
          remainingSeconds: 0,
          totalSeconds: 0,
        );

        expect(color, tokens.timerCritical);
      },
    );
  });

  group('AppTheme', () {
    for (final id in GimmyThemeId.values) {
      group(id.name, () {
        test('exposes GimmyTokens on both variants', () {
          expect(AppTheme.darkFor(id).extension<GimmyTokens>(), isNotNull);
          expect(AppTheme.lightFor(id).extension<GimmyTokens>(), isNotNull);
        });

        test('uses the bundled font families, not the platform default', () {
          final dark = AppTheme.darkFor(id);
          expect(dark.textTheme.bodyMedium?.fontFamily, 'Inter');
          expect(
            dark.extension<GimmyTokens>()!.metricDisplay.fontFamily,
            'JetBrains Mono',
          );
        });

        test(
          'renders mono metrics with tabular figures so digits do not jitter',
          () {
            expect(
              AppTheme.darkFor(id)
                  .extension<GimmyTokens>()!
                  .metricDisplay
                  .fontFeatures,
              contains(const FontFeature.tabularFigures()),
            );
          },
        );

        test('light and dark disagree on surface but agree on brightness', () {
          final light = AppTheme.lightFor(id);
          final dark = AppTheme.darkFor(id);

          expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
          expect(light.colorScheme.brightness, Brightness.light);
          expect(dark.colorScheme.brightness, Brightness.dark);
        });
      });
    }

    test('AppTheme.dark / .light are Hacker Green', () {
      final hackerDark = AppTheme.darkFor(GimmyThemeId.hackerGreen);
      final hackerLight = AppTheme.lightFor(GimmyThemeId.hackerGreen);

      expect(AppTheme.dark.colorScheme, hackerDark.colorScheme);
      expect(AppTheme.light.colorScheme, hackerLight.colorScheme);
    });
  });
}
