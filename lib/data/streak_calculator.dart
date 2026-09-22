import 'models/workout_session.dart';

/// Counts consecutive calendar days, in local time, on which the user started
/// at least one workout.
///
/// A day counts the moment a workout starts — finishing it is not required, and
/// abandoning it does not take the day back.
///
/// The streak survives the whole of the day after the last workout: if the last
/// session was yesterday, nothing is lost yet, because today is not over. It
/// resets only once a full calendar day has gone by with nothing in it.
abstract final class StreakCalculator {
  static int calculate(
    Iterable<WorkoutSession> sessions, {
    required DateTime now,
  }) {
    final workoutDays = sessions.map((s) => s.localDay).toSet();
    if (workoutDays.isEmpty) return 0;

    final today = _startOfDay(now);
    final yesterday = _dayBefore(today);

    // Anchor on the most recent day that can still hold a live streak.
    final DateTime anchor;
    if (workoutDays.contains(today)) {
      anchor = today;
    } else if (workoutDays.contains(yesterday)) {
      anchor = yesterday;
    } else {
      return 0;
    }

    var streak = 0;
    var cursor = anchor;
    while (workoutDays.contains(cursor)) {
      streak++;
      cursor = _dayBefore(cursor);
    }
    return streak;
  }

  /// True when [now] falls on a day the user has already worked out.
  static bool hasWorkedOutToday(
    Iterable<WorkoutSession> sessions, {
    required DateTime now,
  }) {
    final today = _startOfDay(now);
    return sessions.any((s) => s.localDay == today);
  }

  static DateTime _startOfDay(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  /// Steps back one calendar day.
  ///
  /// Built from date parts rather than by subtracting 24 hours, so a day that
  /// is 23 or 25 hours long across a daylight-saving change still counts once.
  static DateTime _dayBefore(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);
}
