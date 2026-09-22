import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/util/duration_format.dart';

void main() {
  group('DurationFormat.clock', () {
    test('pads minutes and seconds so the width never jumps', () {
      expect(DurationFormat.clock(const Duration(seconds: 5)), '00:05');
      expect(DurationFormat.clock(const Duration(seconds: 65)), '01:05');
      expect(DurationFormat.clock(const Duration(minutes: 10)), '10:00');
    });

    test('grows an hours field only when it is needed', () {
      expect(
        DurationFormat.clock(const Duration(minutes: 59, seconds: 59)),
        '59:59',
      );
      expect(
        DurationFormat.clock(const Duration(hours: 1, seconds: 7)),
        '1:00:07',
      );
    });

    test('clamps a negative duration to zero rather than printing a minus', () {
      expect(DurationFormat.clock(const Duration(seconds: -5)), '00:00');
    });
  });

  group('DurationFormat.human', () {
    test('uses seconds below a minute', () {
      expect(DurationFormat.human(const Duration(seconds: 30)), '30 s');
    });

    test('uses whole minutes in between', () {
      expect(DurationFormat.human(const Duration(minutes: 45)), '45 min');
      expect(DurationFormat.human(const Duration(seconds: 3165)), '52 min');
    });

    test('splits into hours past sixty minutes', () {
      expect(DurationFormat.human(const Duration(seconds: 4029)), '1 h 07 min');
    });
  });
}
