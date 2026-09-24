import 'package:flutter/foundation.dart';

enum LogLevel { action, info, warning, error }

/// The app's one logger: user actions, outcomes, and errors, as single lines
/// on the console.
///
/// ponytail: `debugPrint`, not `dart:developer`'s `log` — that one is a no-op
/// in a dart2js build, so the web would log nothing. `debugPrint` reaches the
/// browser console, logcat and the Xcode console alike. Nothing leaves the
/// device; swap the body for a file or a crash reporter if that ever changes.
///
/// Never log file contents or anything a user did not name themselves.
abstract final class AppLog {
  /// Something the user did: a tap, a navigation, a choice.
  static void action(String area, String message) =>
      _write(LogLevel.action, area, message);

  /// Something the app did on its own that is worth a line.
  static void info(String area, String message) =>
      _write(LogLevel.info, area, message);

  /// A recoverable problem: bad input, missing data, a fallback taken.
  static void warning(String area, String message, [Object? error]) =>
      _write(LogLevel.warning, area, message, error);

  /// A failure the user will notice, or that should never happen.
  static void error(
    String area,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _write(LogLevel.error, area, message, error, stackTrace);

  static void _write(
    LogLevel level,
    String area,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final time = DateTime.now().toIso8601String().substring(11, 23);
    final buffer = StringBuffer(
      '[gimmy] $time ${level.name.toUpperCase().padRight(7)} $area: $message',
    );
    if (error != null) buffer.write(' | $error');
    if (stackTrace != null) buffer.write('\n$stackTrace');
    debugPrint(buffer.toString());
  }
}
