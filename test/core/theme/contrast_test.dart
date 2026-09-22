import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/theme/gimmy_tokens.dart';

/// WCAG 2.1 relative-luminance contrast ratio.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Body text and other small type.
const double kAaNormal = 4.5;

/// Icons, borders, large type, and graphical objects like the timer ring.
const double kAaGraphics = 3.0;

void main() {
  /// The design system is built for reading under motion in bad gym lighting,
  /// so these pairings are load-bearing, not cosmetic. They regressed once
  /// already when the light palette was derived from the design doc's stated
  /// accent values.
  for (final (name, theme) in [
    ('dark', AppTheme.dark),
    ('light', AppTheme.light),
  ]) {
    group('$name theme contrast', () {
      final scheme = theme.colorScheme;
      final tokens = theme.extension<GimmyTokens>()!;

      void expectAtLeast(String label, Color fg, Color bg, double min) {
        final ratio = contrast(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(min),
          reason: '$label is ${ratio.toStringAsFixed(2)}:1, needs $min:1',
        );
      }

      test('body and muted text on the page background', () {
        expectAtLeast('onSurface', scheme.onSurface, scheme.surface, kAaNormal);
        expectAtLeast(
          'onSurfaceVariant',
          scheme.onSurfaceVariant,
          scheme.surface,
          kAaNormal,
        );
      });

      test('text on cards and on modals', () {
        expectAtLeast(
          'onSurface on card',
          scheme.onSurface,
          scheme.surfaceContainer,
          kAaNormal,
        );
        expectAtLeast(
          'onSurface on modal',
          scheme.onSurface,
          tokens.modalSurface,
          kAaNormal,
        );
      });

      test('primary CTA label on its fill', () {
        expectAtLeast(
          'onPrimaryContainer',
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
          kAaNormal,
        );
        expectAtLeast('onPrimary', scheme.onPrimary, scheme.primary, kAaNormal);
      });

      test('accent text on the page background', () {
        expectAtLeast('primary', scheme.primary, scheme.surface, kAaNormal);
      });

      test('the active nav destination against the nav bar', () {
        expectAtLeast(
          'nav active',
          scheme.primary,
          scheme.surfaceContainerLowest,
          kAaNormal,
        );
        expectAtLeast(
          'nav inactive',
          scheme.onSurfaceVariant,
          scheme.surfaceContainerLowest,
          kAaNormal,
        );
      });

      test('the timer ring stays legible at every stage of the countdown', () {
        for (final (label, color) in [
          ('safe', tokens.timerSafe),
          ('warning', tokens.timerWarning),
          ('critical', tokens.timerCritical),
        ]) {
          expectAtLeast(
            'timer $label on surface',
            color,
            scheme.surface,
            kAaGraphics,
          );
          expectAtLeast(
            'timer $label on card',
            color,
            scheme.surfaceContainer,
            kAaGraphics,
          );
        }
      });

      test('intensity colors are distinguishable against a card', () {
        for (final (label, color) in [
          ('active', tokens.intensityActive),
          ('rest', tokens.intensityRest),
          ('easy', tokens.intensityEasy),
        ]) {
          expectAtLeast(
            'intensity $label',
            color,
            scheme.surfaceContainer,
            kAaGraphics,
          );
        }
      });

      test('card hairlines are visible against the card they outline', () {
        expectAtLeast(
          'cardBorder',
          tokens.cardBorder,
          scheme.surfaceContainer,
          1.1,
        );
      });
    });
  }
}
