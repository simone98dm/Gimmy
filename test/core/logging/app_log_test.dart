import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/logging/app_log.dart';
import 'package:gimmy/core/logging/log_observers.dart';

class _Ping {
  @override
  String toString() => 'Ping()';
}

class ExecutionTicked {}

class _TestBloc extends Bloc<Object, int> {
  _TestBloc() : super(0) {
    on<_Ping>((_, _) {});
    on<ExecutionTicked>((_, _) {});
  }

  /// How the app's blocs report a caught failure.
  void report(Object error) => addError(error, StackTrace.empty);
}

void main() {
  late List<String> lines;
  late DebugPrintCallback original;

  setUp(() {
    lines = [];
    original = debugPrint;
    debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
  });

  tearDown(() {
    debugPrint = original;
    Bloc.observer = const _NoOpObserver();
  });

  test('writes level, area, message, error and stack on one entry', () {
    AppLog.action('import', 'picked file');
    AppLog.error('storage', 'read failed', 'disk full', StackTrace.empty);

    expect(
      lines[0],
      matches(
        r'^\[gimmy\] \d\d:\d\d:\d\d\.\d{3} ACTION  '
        r'import: picked file$',
      ),
    );
    expect(lines[1], contains('ERROR   storage: read failed | disk full'));
  });

  test(
    'the bloc observer logs user events, skips ticks, logs errors',
    () async {
      Bloc.observer = const LoggingBlocObserver();
      final bloc = _TestBloc()
        ..add(_Ping())
        ..add(ExecutionTicked())
        ..report(StateError('boom'));
      await pumpEventQueue();
      await bloc.close();

      expect(lines.where((l) => l.contains('_TestBloc: Ping()')), hasLength(1));
      expect(lines.where((l) => l.contains('ExecutionTicked')), isEmpty);
      expect(
        lines.where((l) => l.contains('ERROR') && l.contains('boom')),
        hasLength(1),
      );
    },
  );

  test('the navigator observer names pushed and popped routes', () {
    final observer = LoggingNavigatorObserver();
    final route = MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'about'),
      builder: (_) => const SizedBox(),
    );

    observer
      ..didPush(route, null)
      ..didPop(route, null);

    expect(lines[0], endsWith('navigation: open about'));
    expect(lines[1], endsWith('navigation: close about'));
  });
}

class _NoOpObserver extends BlocObserver {
  const _NoOpObserver();
}
