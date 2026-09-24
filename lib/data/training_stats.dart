import 'models/workout_session.dart';
import 'streak_calculator.dart';

/// What the session history adds up to, for the desktop dashboard's stat
/// cards and the sidebar. Everything is counted from real sessions — nothing
/// here is estimated.
class TrainingStats {
  const TrainingStats({
    required this.monthSessions,
    required this.monthCompleted,
    required this.lastMonthSessions,
    required this.weekDays,
    required this.weekActiveSeconds,
    required this.streak,
    required this.bestStreak,
  });

  factory TrainingStats.of(
    Iterable<WorkoutSession> sessions, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    // Weeks start on Monday, as the calendar's do.
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final lastMonth = DateTime(now.year, now.month - 1);

    bool inMonth(WorkoutSession s, DateTime month) =>
        s.startedAt.year == month.year && s.startedAt.month == month.month;

    final month = sessions.where((s) => inMonth(s, now)).toList();
    final week = sessions
        .where((s) => !s.localDay.isBefore(weekStart))
        .toList();

    return TrainingStats(
      monthSessions: month.length,
      monthCompleted: month
          .where((s) => s.status == SessionStatus.completed)
          .length,
      lastMonthSessions: sessions.where((s) => inMonth(s, lastMonth)).length,
      weekDays: week.map((s) => s.localDay).toSet().length,
      weekActiveSeconds: week.fold(0, (t, s) => t + s.totalActiveSeconds),
      streak: StreakCalculator.calculate(sessions, now: now),
      bestStreak: StreakCalculator.longest(sessions),
    );
  }

  final int monthSessions;
  final int monthCompleted;
  final int lastMonthSessions;

  /// Distinct days trained since Monday.
  final int weekDays;
  final int weekActiveSeconds;

  final int streak;
  final int bestStreak;
}
