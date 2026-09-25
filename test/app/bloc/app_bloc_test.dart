import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/app/bloc/app_bloc.dart';
import 'package:gimmy/core/theme/gimmy_theme_id.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late SettingsRepository settingsRepository;
  late AppBloc bloc;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gimmy-app-bloc');
    SharedPreferences.setMockInitialValues({});
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

  tearDown(() {
    bloc.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('AppThemeChanged', () {
    test('updates the color theme and persists it', () async {
      expect(bloc.state.settings.themeId, GimmyThemeId.fallback);

      bloc.add(const AppThemeChanged(GimmyThemeId.sophisticatedBlue));
      await pumpEventQueue();

      expect(bloc.state.settings.themeId, GimmyThemeId.sophisticatedBlue);
      final saved = await settingsRepository.load();
      expect(saved.themeId, GimmyThemeId.sophisticatedBlue);
    });
  });
}
