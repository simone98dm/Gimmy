import 'package:intl/intl.dart';

/// "Today", "Yesterday", "3 days ago", then an actual date.
///
/// Used in the recent-session list, where the age of a workout matters more
/// than its calendar date until it is about a week old.
abstract final class RelativeDay {
  static String format(DateTime day, {required DateTime now}) {
    final thatDay = DateTime(day.year, day.month, day.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(thatDay).inDays;

    return switch (difference) {
      0 => 'Today',
      1 => 'Yesterday',
      < 7 && > 0 => '$difference days ago',
      _ => DateFormat.MMMd().format(day),
    };
  }
}
