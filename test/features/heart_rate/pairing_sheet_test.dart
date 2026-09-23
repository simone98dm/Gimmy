import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/bloc/app_bloc.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/data/heart_rate/heart_rate_monitor.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:gimmy/features/heart_rate/view/pairing_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_heart_rate_monitor.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-pairing');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// Lets a change travel stream → bloc → rebuild. The [AppBloc] is built
  /// inside `runAsync`, so its stream delivers in the real zone and needs real
  /// time; the [HeartRateBloc] and the frames need fake-async pumps.
  Future<void> flush(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  Future<AppBloc> readyAppBloc(WidgetTester tester) async {
    late final AppBloc bloc;
    // Loading touches the real filesystem; see CLAUDE.md on fake async.
    await tester.runAsync(() async {
      bloc = AppBloc(
        planRepository: PlanRepository(
          store: FileDocumentStore('plan.json', directory: tempDir),
        ),
        sessionRepository: SessionRepository(
          store: FileDocumentStore('sessions.json', directory: tempDir),
        ),
        settingsRepository: SettingsRepository(
          preferences: await SharedPreferences.getInstance(),
        ),
      )..add(const AppStarted());
      await bloc.stream.firstWhere((s) => s.status == AppStatus.ready);
    });
    addTearDown(bloc.close);
    return bloc;
  }

  testWidgets(
    'scans while open, pairs a sensor, remembers it, and forgets it',
    (tester) async {
      final monitor = FakeHeartRateMonitor();
      final appBloc = await readyAppBloc(tester);

      await tester.pumpWidget(
        BlocProvider.value(
          value: appBloc,
          child: withHeartRate(
            monitor: monitor,
            MaterialApp(
              theme: AppTheme.dark,
              home: const Scaffold(body: PairingSheet()),
            ),
          ),
        ),
      );
      await flush(tester);
      expect(monitor.scansStarted, 1);

      monitor.scanningController.add(true);
      monitor.nearbyController.add(const [
        NearbyMonitor(id: 'watch', name: 'Forerunner 965', rssi: -56),
        NearbyMonitor(id: 'strap', name: 'HRM-Pro Plus', rssi: -64),
      ]);
      await flush(tester);

      expect(find.text('DEVICES FOUND (2)'), findsOneWidget);
      expect(find.text('Forerunner 965'), findsOneWidget);
      expect(find.text('88% Excellent'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Pair Forerunner 965'));
      await flush(tester);

      final saved = (await SharedPreferences.getInstance()).getString(
        SettingsRepository.storageKey,
      );
      expect(appBloc.state.settings.heartRateMonitorId, 'watch');
      expect(saved, contains('"heartRateMonitorId":"watch"'));
      // The paired sensor moves out of the found list into its own row.
      expect(find.text('DEVICES FOUND (1)'), findsOneWidget);
      expect(find.text('Waiting for the device…'), findsOneWidget);

      await tester.tap(find.text('Forget'));
      await flush(tester);

      expect(appBloc.state.settings.hasHeartRateMonitor, isFalse);
      expect(find.text('DEVICES FOUND (2)'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      expect(monitor.scansStopped, greaterThanOrEqualTo(1));
    },
  );

  testWidgets('says why it cannot scan', (tester) async {
    final monitor = FakeHeartRateMonitor()
      ..scanFailure = StateError('Bluetooth is off');
    final appBloc = await readyAppBloc(tester);

    await tester.pumpWidget(
      BlocProvider.value(
        value: appBloc,
        child: withHeartRate(
          monitor: monitor,
          MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: PairingSheet()),
          ),
        ),
      ),
    );
    await flush(tester);

    expect(find.text('Bluetooth is off'), findsOneWidget);
    expect(find.text('No heart-rate sensors found nearby.'), findsOneWidget);
  });
}
