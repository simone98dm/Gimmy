import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/bloc/app_bloc.dart';
import 'package:gimmy/core/theme/app_theme.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:gimmy/features/about/view/about_page.dart';
import 'package:gimmy/features/about/view/legal_page.dart';
import 'package:gimmy/features/settings/view/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_heart_rate_monitor.dart';
import '../../support/test_fonts.dart';

void main() {
  late Directory tempDir;

  setUpAll(loadAppFonts);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-settings');
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<(AppBloc, SettingsRepository)> pumpSettings(
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // The repositories touch dart:io, which never completes under fake async.
    late final AppBloc bloc;
    late final SettingsRepository settingsRepository;
    await tester.runAsync(() async {
      settingsRepository = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );
      bloc = AppBloc(
        planRepository: PlanRepository(
          store: FileDocumentStore('plan.json', directory: tempDir),
        ),
        sessionRepository: SessionRepository(
          store: FileDocumentStore('sessions.json', directory: tempDir),
        ),
        settingsRepository: settingsRepository,
      )..add(const AppStarted());
      await bloc.stream.firstWhere((s) => s.status == AppStatus.ready);
    });
    addTearDown(bloc.close);

    await tester.pumpWidget(
      withHeartRate(
        BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: SettingsPage(onImport: () {}, onWiped: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (bloc, settingsRepository);
  }

  testWidgets('the cues switch turns cues off and remembers it', (
    tester,
  ) async {
    final (bloc, settingsRepository) = await pumpSettings(tester);
    expect(bloc.state.settings.areCuesEnabled, isTrue);

    final toggle = find.byType(Switch);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(bloc.state.settings.areCuesEnabled, isFalse);
    final saved = await tester.runAsync(settingsRepository.load);
    expect(saved!.areCuesEnabled, isFalse);
  });

  testWidgets('About opens from Settings and leads on to Legal', (
    tester,
  ) async {
    await pumpSettings(tester);

    final aboutRow = find.text('About Gimmy');
    await tester.ensureVisible(aboutRow);
    await tester.tap(aboutRow);
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);

    // Settings, still underneath, has a row with the same label.
    final legalRow = find.descendant(
      of: find.byType(AboutPage),
      matching: find.text('Legal notes & terms'),
    );
    await tester.dragUntilVisible(
      legalRow,
      find.byType(AboutPage),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(legalRow);
    await tester.pumpAndSettle();
    expect(find.byType(LegalPage), findsOneWidget);
    expect(find.text('Not a medical device'), findsOneWidget);
  });
}
