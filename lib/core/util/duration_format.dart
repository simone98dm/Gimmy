/// Formatting helpers for the durations and targets shown all over the app.
abstract final class DurationFormat {
  /// `MM:SS`, or `H:MM:SS` past an hour. Used for live countdowns, so it is
  /// zero-padded and never changes width unexpectedly.
  static String clock(Duration duration) {
    final total = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;

    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$mm:$ss' : '$mm:$ss';
  }

  /// `45 min`, `1 h 07 min`, `30 s`. For summaries, not for counting down.
  static String human(Duration duration) {
    final total = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    if (total < 60) return '$total s';

    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours == 0) return '$minutes min';
    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }
}
