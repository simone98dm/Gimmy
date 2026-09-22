import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/streak_calculator.dart';

WorkoutSession sessionOn(DateTime startedAt, {SessionStatus? status}) =>
    WorkoutSession(
      id: 's-${startedAt.toIso8601String()}',
      planId: 'plan-1',
      planName: 'Total Body S2-4',
      startedAt: startedAt,
      status: status,
    );

void main() {
  // A fixed "now" in local time, mid-evening so the day is unambiguous.
  final now = DateTime(2026, 9, 22, 19, 30);

  group('StreakCalculator.calculate', () {
    test('is zero with no sessions at all', () {
      expect(StreakCalculator.calculate([], now: now), 0);
    });

    test('counts today as soon as a workout is started', () {
      final sessions = [sessionOn(DateTime(2026, 9, 22, 19, 29))];

      expect(StreakCalculator.calculate(sessions, now: now), 1);
    });

    test('counts an abandoned workout the same as a completed one', () {
      final sessions = [
        sessionOn(DateTime(2026, 9, 22, 8, 0), status: SessionStatus.abandoned),
      ];

      expect(StreakCalculator.calculate(sessions, now: now), 1);
    });

    test('counts consecutive days ending today', () {
      final sessions = [
        sessionOn(DateTime(2026, 9, 20, 7, 0)),
        sessionOn(DateTime(2026, 9, 21, 7, 0)),
        sessionOn(DateTime(2026, 9, 22, 7, 0)),
      ];

      expect(StreakCalculator.calculate(sessions, now: now), 3);
    });

    test('counts several sessions on one day only once', () {
      final sessions = [
        sessionOn(DateTime(2026, 9, 22, 7, 0)),
        sessionOn(DateTime(2026, 9, 22, 18, 0)),
        sessionOn(DateTime(2026, 9, 21, 7, 0)),
      ];

      expect(StreakCalculator.calculate(sessions, now: now), 2);
    });

    test('stays intact all through the day after the last workout', () {
      // Nothing today yet, but today is not over, so no full day has been lost.
      final sessions = [
        sessionOn(DateTime(2026, 9, 20, 7, 0)),
        sessionOn(DateTime(2026, 9, 21, 7, 0)),
      ];

      expect(StreakCalculator.calculate(sessions, now: now), 2);
    });

    test('resets to zero once a full calendar day has passed empty', () {
      // Last workout two days ago: yesterday came and went with nothing in it.
      final sessions = [
        sessionOn(DateTime(2026, 9, 19, 7, 0)),
        sessionOn(DateTime(2026, 9, 20, 7, 0)),
      ];

      expect(StreakCalculator.calculate(sessions, now: now), 0);
    });

    test(
      'counts only the run that reaches the present, ignoring older runs',
      () {
        final sessions = [
          // An old five-day run, long since broken.
          sessionOn(DateTime(2026, 9, 1, 7, 0)),
          sessionOn(DateTime(2026, 9, 2, 7, 0)),
          sessionOn(DateTime(2026, 9, 3, 7, 0)),
          sessionOn(DateTime(2026, 9, 4, 7, 0)),
          sessionOn(DateTime(2026, 9, 5, 7, 0)),
          // The current run.
          sessionOn(DateTime(2026, 9, 21, 7, 0)),
          sessionOn(DateTime(2026, 9, 22, 7, 0)),
        ];

        expect(StreakCalculator.calculate(sessions, now: now), 2);
      },
    );

    test('a single gap day breaks the run', () {
      final sessions = [
        sessionOn(DateTime(2026, 9, 19, 7, 0)),
        // 20th missing
        sessionOn(DateTime(2026, 9, 21, 7, 0)),
        sessionOn(DateTime(2026, 9, 22, 7, 0)),
      ];

      expect(StreakCalculator.calculate(sessions, now: now), 2);
    });

    test('does not care what order the sessions arrive in', () {
      final sessions = [
        sessionOn(DateTime(2026, 9, 22, 7, 0)),
        sessionOn(DateTime(2026, 9, 20, 7, 0)),
        sessionOn(DateTime(2026, 9, 21, 7, 0)),
      ];

      expect(StreakCalculator.calculate(sessions, now: now), 3);
    });

    group('the midnight boundary', () {
      test('a workout at 23:59 belongs to the day it started', () {
        final sessions = [sessionOn(DateTime(2026, 9, 21, 23, 59, 59))];

        expect(StreakCalculator.calculate(sessions, now: now), 1);
      });

      test('a workout at 00:00 belongs to the new day, not the one before', () {
        final sessions = [
          sessionOn(DateTime(2026, 9, 21, 23, 59)),
          sessionOn(DateTime(2026, 9, 22, 0, 0)),
        ];

        expect(StreakCalculator.calculate(sessions, now: now), 2);
      });

      test('a streak measured one second after midnight still stands', () {
        final justAfterMidnight = DateTime(2026, 9, 22, 0, 0, 1);
        final sessions = [
          sessionOn(DateTime(2026, 9, 20, 7, 0)),
          sessionOn(DateTime(2026, 9, 21, 7, 0)),
        ];

        expect(StreakCalculator.calculate(sessions, now: justAfterMidnight), 2);
      });

      test('a streak measured one second before midnight still stands', () {
        final justBeforeMidnight = DateTime(2026, 9, 22, 23, 59, 59);
        final sessions = [
          sessionOn(DateTime(2026, 9, 21, 7, 0)),
          sessionOn(DateTime(2026, 9, 22, 7, 0)),
        ];

        expect(
          StreakCalculator.calculate(sessions, now: justBeforeMidnight),
          2,
        );
      });

      test('the run dies the instant the empty day ends', () {
        // Last workout on the 20th. All of the 21st passed with nothing.
        final sessions = [sessionOn(DateTime(2026, 9, 20, 7, 0))];

        expect(
          StreakCalculator.calculate(
            sessions,
            now: DateTime(2026, 9, 21, 23, 59, 59),
          ),
          1,
          reason: 'still the 21st, the day after — the run is hanging on',
        );
        expect(
          StreakCalculator.calculate(
            sessions,
            now: DateTime(2026, 9, 22, 0, 0, 0),
          ),
          0,
          reason: 'the 21st is over and was empty — the run is gone',
        );
      });

      test('crosses a month boundary', () {
        final sessions = [
          sessionOn(DateTime(2026, 8, 30, 7, 0)),
          sessionOn(DateTime(2026, 8, 31, 7, 0)),
          sessionOn(DateTime(2026, 9, 1, 7, 0)),
        ];

        expect(
          StreakCalculator.calculate(
            sessions,
            now: DateTime(2026, 9, 1, 12, 0),
          ),
          3,
        );
      });

      test('crosses a year boundary', () {
        final sessions = [
          sessionOn(DateTime(2025, 12, 31, 22, 0)),
          sessionOn(DateTime(2026, 1, 1, 9, 0)),
        ];

        expect(
          StreakCalculator.calculate(
            sessions,
            now: DateTime(2026, 1, 1, 12, 0),
          ),
          2,
        );
      });

      test('crosses a leap day', () {
        final sessions = [
          sessionOn(DateTime(2028, 2, 28, 7, 0)),
          sessionOn(DateTime(2028, 2, 29, 7, 0)),
          sessionOn(DateTime(2028, 3, 1, 7, 0)),
        ];

        expect(
          StreakCalculator.calculate(
            sessions,
            now: DateTime(2028, 3, 1, 12, 0),
          ),
          3,
        );
      });
    });
  });

  group('StreakCalculator.hasWorkedOutToday', () {
    test('is false when the last workout was yesterday', () {
      final sessions = [sessionOn(DateTime(2026, 9, 21, 20, 0))];

      expect(StreakCalculator.hasWorkedOutToday(sessions, now: now), isFalse);
    });

    test('is true from the moment today s workout starts', () {
      final sessions = [sessionOn(DateTime(2026, 9, 22, 0, 0))];

      expect(StreakCalculator.hasWorkedOutToday(sessions, now: now), isTrue);
    });
  });
}
