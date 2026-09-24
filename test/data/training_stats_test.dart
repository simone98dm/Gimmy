import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/streak_calculator.dart';
import 'package:gimmy/data/training_stats.dart';

WorkoutSession session(
  DateTime day, {
  SessionStatus status = SessionStatus.completed,
  int seconds = 600,
}) => WorkoutSession(
  id: '$day',
  planId: 'p',
  planName: 'Plan',
  startedAt: DateTime(day.year, day.month, day.day, 18),
  totalActiveSeconds: seconds,
  status: status,
);

void main() {
  // Thursday.
  final now = DateTime(2026, 9, 24, 12);

  test('longest streak finds the best run, not the current one', () {
    final sessions = [
      for (final d in [1, 2, 3, 4, 10, 11, 23, 24])
        session(DateTime(2026, 9, d)),
      session(DateTime(2026, 9, 2)), // same day twice counts once
    ];

    expect(StreakCalculator.longest(sessions), 4);
    expect(StreakCalculator.longest(const []), 0);
  });

  test('counts the month, last month, and the week since Monday', () {
    final stats = TrainingStats.of([
      session(DateTime(2026, 8, 30)),
      session(DateTime(2026, 9, 20)), // Sunday, last week
      session(DateTime(2026, 9, 21), seconds: 300), // Monday
      session(DateTime(2026, 9, 23), status: SessionStatus.abandoned),
      session(DateTime(2026, 9, 23), seconds: 100),
      session(DateTime(2026, 9, 24)),
    ], now: now);

    expect(stats.monthSessions, 5);
    expect(stats.monthCompleted, 4);
    expect(stats.lastMonthSessions, 1);
    expect(stats.weekDays, 3);
    expect(stats.weekActiveSeconds, 300 + 600 + 100 + 600);
    expect(stats.streak, 2);
    expect(stats.bestStreak, 2);
  });
}
