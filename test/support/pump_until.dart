import 'package:flutter_test/flutter_test.dart';

/// Pumps until [condition] holds, or fails the test after [timeout].
///
/// Flow tests drive real file I/O inside `tester.runAsync`, so there is no
/// fixed number of pumps that is both fast and reliable — a fixed count passes
/// on an idle machine and flakes on a busy one. Waiting on the condition is
/// both faster and deterministic.
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out waiting for ${reason ?? 'condition'}');
    }
    await tester.pump(const Duration(milliseconds: 20));
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }

  // Let any animation started by the condition settle.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps until [finder] matches something on screen.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) => pumpUntil(
  tester,
  () => finder.evaluate().isNotEmpty,
  timeout: timeout,
  reason: finder.describeMatch(Plurality.many),
);

/// Pumps until [finder] matches nothing.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) => pumpUntil(
  tester,
  () => finder.evaluate().isEmpty,
  timeout: timeout,
  reason: 'absence of ${finder.describeMatch(Plurality.many)}',
);
