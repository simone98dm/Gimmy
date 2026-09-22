import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/motion.dart';
import 'package:gimmy/core/widgets/pressable_scale.dart';

/// Reads the animation driving the scale, rather than introspecting whatever
/// render widget `ScaleTransition` happens to build.
double scaleOf(WidgetTester tester) =>
    tester.widget<ScaleTransition>(find.byType(ScaleTransition)).scale.value;

Widget harness({bool enabled = true, bool reduceMotion = false}) {
  return MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: PressableScale(
          enabled: enabled,
          child: const SizedBox.square(
            key: Key('target'),
            dimension: 100,
            child: ColoredBox(color: Color(0xFF00E676)),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PressableScale', () {
    testWidgets('shrinks while a finger is down and springs back', (
      tester,
    ) async {
      await tester.pumpWidget(harness());
      expect(scaleOf(tester), 1.0);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('target'))),
      );
      await tester.pumpAndSettle();

      expect(
        scaleOf(tester),
        closeTo(GimmyMotion.pressedScale, 0.001),
        reason: 'the design system asks for a 0.98 press',
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(scaleOf(tester), 1.0);
    });

    testWidgets('springs back when the gesture is cancelled', (tester) async {
      await tester.pumpWidget(harness());

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('target'))),
      );
      await tester.pumpAndSettle();
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(scaleOf(tester), 1.0);
    });

    testWidgets('a disabled control does not react', (tester) async {
      await tester.pumpWidget(harness(enabled: false));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('target'))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ScaleTransition), findsNothing);
      await gesture.up();
    });

    testWidgets('stays still when the platform asks for reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(harness(reduceMotion: true));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('target'))),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(ScaleTransition),
        findsNothing,
        reason: 'motion sensitivity is an accessibility need, not a preference',
      );
      await gesture.up();
    });

    testWidgets('does not swallow the tap it decorates', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: PressableScale(
                child: ElevatedButton(
                  onPressed: () => taps++,
                  child: const Text('Tap me'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });
  });
}
