import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/core/widgets/app_sidebar.dart';
import 'package:gimmy/core/widgets/desktop_layout.dart';
import 'package:gimmy/core/widgets/gimmy_scaffold.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/features/execution/bloc/execution_bloc.dart';
import 'package:gimmy/features/execution/view/execution_page.dart';

import '../../support/test_fonts.dart';
import 'execution_bloc_test.dart' show FakeTicker;
import '../../support/fake_heart_rate_monitor.dart';
import '../../support/sample_fit.dart';

Plan sample() => FitWorkoutParser.parse(
  bytes: sampleFitBytes(),
  filename: sampleFitFilename,
  planId: 'plan-1',
  importedAt: DateTime(2026, 9, 22, 10),
);

void main() {
  late Directory tempDir;
  late FakeTicker ticker;

  setUpAll(loadAppFonts);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-exec-golden');
    ticker = FakeTicker();
  });

  tearDown(() async {
    await ticker.dispose();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Drives the bloc to a given point, then captures the page.
  Future<void> capture(
    WidgetTester tester, {
    required String name,
    required Future<void> Function(ExecutionBloc bloc) drive,
    Brightness brightness = Brightness.dark,
    bool desktop = false,
  }) async {
    if (desktop) {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      debugDesktopLayoutEnabled = true;
      addTearDown(() => debugDesktopLayoutEnabled = false);
    } else {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
    }
    addTearDown(tester.view.reset);

    late final ExecutionBloc bloc;
    await tester.runAsync(() async {
      bloc = ExecutionBloc(
        plan: sample(),
        sessionRepository: SessionRepository(
          store: FileDocumentStore('sessions.json', directory: tempDir),
        ),
        ticker: ticker,
        now: () => DateTime(2026, 9, 22, 18),
      )..add(const ExecutionStarted());
      await pumpEventQueue(times: 50);
      await drive(bloc);
    });
    addTearDown(bloc.close);

    await tester.pumpWidget(
      withHeartRate(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
          home: BlocProvider.value(
            value: bloc,
            child: GimmyScaffold(
              label: 'Workout',
              sidebarItem: SidebarItem.active,
              child: ExecutionPage(onDone: () {}),
            ),
          ),
        ),
      ),
    );
    // Not `pumpAndSettle`: the live dot pulses for as long as the timer is
    // running, so there is no settled state to wait for.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('a timer step waiting for Play', (tester) async {
    await capture(tester, name: 'execution_timer_idle', drive: (_) async {});
  });

  testWidgets('a timer step counting down', (tester) async {
    await capture(
      tester,
      name: 'execution_timer_running',
      drive: (bloc) async {
        bloc.add(const ExecutionPrimaryPressed());
        await pumpEventQueue(times: 50);
        await ticker.tick(120);
      },
    );
  });

  testWidgets('a reps step, where the control becomes Done', (tester) async {
    await capture(
      tester,
      name: 'execution_reps',
      drive: (bloc) async {
        // Step 2 of the sample is Squat, 10 reps.
        bloc.add(const ExecutionSkipped());
        await pumpEventQueue(times: 50);
      },
    );
  });

  testWidgets('the completion summary', (tester) async {
    await capture(
      tester,
      name: 'execution_complete',
      drive: (bloc) async {
        var guard = 0;
        while (bloc.state.isRunning && guard++ < 300) {
          bloc.add(const ExecutionSkipped());
          await pumpEventQueue(times: 10);
        }
      },
    );
  });

  testWidgets('desktop: stage card beside next-up', (tester) async {
    await capture(
      tester,
      name: 'execution_desktop',
      drive: (bloc) async {
        // Step 3 of the sample is a timed rest: two steps behind it.
        bloc.add(const ExecutionPrimaryPressed());
        await pumpEventQueue(times: 50);
        await ticker.tick(300);
        bloc.add(const ExecutionSkipped());
        await pumpEventQueue(times: 50);
        bloc.add(const ExecutionPrimaryPressed());
        await pumpEventQueue(times: 50);
        await ticker.tick(20);
      },
      desktop: true,
    );
  });
}
