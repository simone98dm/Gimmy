import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/theme/gimmy_tokens.dart';

void main() {
  group('timerColorFor', () {
    const tokens = GimmyTokens.dark;

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
    test('exposes GimmyTokens on both variants', () {
      expect(AppTheme.dark.extension<GimmyTokens>(), isNotNull);
      expect(AppTheme.light.extension<GimmyTokens>(), isNotNull);
    });

    test('uses the bundled font families, not the platform default', () {
      expect(AppTheme.dark.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(GimmyTokens.dark.metricDisplay.fontFamily, 'JetBrains Mono');
    });

    test(
      'renders mono metrics with tabular figures so digits do not jitter',
      () {
        expect(
          GimmyTokens.dark.metricDisplay.fontFeatures,
          contains(const FontFeature.tabularFigures()),
        );
      },
    );

    test('light and dark disagree on surface but agree on accent roles', () {
      expect(
        AppTheme.light.colorScheme.surface,
        isNot(AppTheme.dark.colorScheme.surface),
      );
      expect(AppTheme.light.colorScheme.brightness, Brightness.light);
      expect(AppTheme.dark.colorScheme.brightness, Brightness.dark);
    });
  });
}
