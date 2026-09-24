// Frame-timing harness. Run on a device in profile mode:
//   flutter drive --profile --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/view/gimmy_app.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:integration_test/integration_test.dart';

import '../test/support/sample_fit.dart';

const _settle = Duration(milliseconds: 700);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('frame timings', (tester) async {
    // Never overwrite a real plan on the device: seed only when there is none.
    final plans = PlanRepository();
    if (await plans.load() == null) {
      await plans.save(
        FitWorkoutParser.parse(
          bytes: sampleFitBytes(),
          filename: sampleFitFilename,
          planId: 'perf',
          importedAt: DateTime.now(),
        ),
      );
    }

    await tester.pumpWidget(const GimmyApp());
    await tester.pump(const Duration(seconds: 2));

    Future<void> tapTab(String label) async {
      // `.last`: the header also names the page, and the tab bar is drawn
      // after it.
      await tester.tap(find.text(label).last);
      await tester.pump(_settle);
    }

    await binding.watchPerformance(() async {
      for (var i = 0; i < 4; i++) {
        await tapTab('WORKOUT');
        await tapTab('SETTINGS');
        await tapTab('TODAY');
      }
    }, reportKey: 'tab_switch');

    // The theme switch lives in Settings.
    await tapTab('SETTINGS');
    await binding.watchPerformance(() async {
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text(i.isEven ? 'Dark' : 'Light'));
        await tester.pump(_settle);
      }
    }, reportKey: 'theme_toggle');

    await tapTab('WORKOUT');
    await binding.watchPerformance(() async {
      final list = find.byType(CustomScrollView).hitTestable();
      for (var i = 0; i < 3; i++) {
        await tester.fling(list, const Offset(0, -600), 2500);
        await tester.pump(const Duration(milliseconds: 900));
        await tester.fling(list, const Offset(0, 600), 2500);
        await tester.pump(const Duration(milliseconds: 900));
      }
    }, reportKey: 'active_scroll');

    await tapTab('TODAY');
    await binding.watchPerformance(() async {
      final page = find.byType(SingleChildScrollView).hitTestable().first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(page, const Offset(0, -500), 2500);
        await tester.pump(const Duration(milliseconds: 900));
        await tester.fling(page, const Offset(0, 500), 2500);
        await tester.pump(const Duration(milliseconds: 900));
      }
    }, reportKey: 'dashboard_scroll');
  });
}
