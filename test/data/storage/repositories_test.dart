import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/theme/gimmy_theme_id.dart';
import 'package:gimmy/data/models/app_settings.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/models/workout_session.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/session_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Plan samplePlan({String id = 'plan-1'}) => Plan(
  id: id,
  name: 'Full Body Sample',
  sourceFilename: 'full_body_sample.fit',
  importedAt: DateTime.utc(2026, 9, 22, 10),
  steps: [
    PlanStep.timer(
      name: 'Warm-up bike',
      intensity: StepIntensity.warmup,
      durationSeconds: 600,
    ),
    PlanStep.reps(
      name: 'Squat',
      intensity: StepIntensity.active,
      repCount: 12,
      notes: 'Range 40-60 kg.',
    ),
    PlanStep.open(name: 'Stretching', intensity: StepIntensity.cooldown),
  ],
);

WorkoutSession session(String id, DateTime startedAt) => WorkoutSession(
  id: id,
  planId: 'plan-1',
  planName: 'Full Body Sample',
  startedAt: startedAt,
);

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gimmy-test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('PlanRepository', () {
    test('has no plan before the first import', () async {
      final repo = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );

      expect(await repo.load(), isNull);
    });

    test('round-trips a plan with every step type intact', () async {
      final repo = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );
      final plan = samplePlan();

      await repo.save(plan);

      expect(await repo.load(), plan);
    });

    test('a second import replaces the first plan', () async {
      final repo = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );
      await repo.save(samplePlan(id: 'first'));

      await repo.save(samplePlan(id: 'second'));

      expect((await repo.load())?.id, 'second');
    });

    test('clear leaves nothing behind', () async {
      final repo = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );
      await repo.save(samplePlan());

      await repo.clear();

      expect(await repo.load(), isNull);
      expect(tempDir.listSync(), isEmpty);
    });

    test(
      'recovers from a corrupt plan file instead of crashing on launch',
      () async {
        File('${tempDir.path}/plan.json').writeAsStringSync('{not json');
        final repo = PlanRepository(
          store: FileDocumentStore('plan.json', directory: tempDir),
        );

        expect(await repo.load(), isNull);
      },
    );

    test('discards a plan file that parses but is missing its steps', () async {
      File('${tempDir.path}/plan.json')
          .writeAsStringSync(jsonEncode({'id': 'x', 'name': 'x'}));
      final repo = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );

      expect(await repo.load(), isNull);
      // The bad file is removed, so the next launch is not slowed by it again.
      expect(File('${tempDir.path}/plan.json').existsSync(), isFalse);
    });
  });

  group('SessionRepository', () {
    test('starts empty', () async {
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );

      expect(await repo.loadAll(), isEmpty);
    });

    test('keeps sessions sorted by start time however they arrive', () async {
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );

      await repo.upsert(session('c', DateTime(2026, 9, 22)));
      await repo.upsert(session('a', DateTime(2026, 9, 20)));
      await repo.upsert(session('b', DateTime(2026, 9, 21)));

      final stored = await repo.loadAll();
      expect(stored.map((s) => s.id), ['a', 'b', 'c']);
    });

    test('updating a session replaces it rather than duplicating it', () async {
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );
      final started = session('s1', DateTime(2026, 9, 22, 18));
      await repo.upsert(started);

      await repo.upsert(
        started.copyWith(
          endedAt: DateTime(2026, 9, 22, 19),
          status: SessionStatus.completed,
          totalActiveSeconds: 3600,
          stepsCompleted: 54,
        ),
      );

      final stored = await repo.loadAll();
      expect(stored, hasLength(1));
      expect(stored.single.status, SessionStatus.completed);
      expect(stored.single.totalActiveSeconds, 3600);
      expect(stored.single.stepsCompleted, 54);
    });

    test('a session survives a round trip with its unfinished state', () async {
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );
      final running = session('s1', DateTime(2026, 9, 22, 18));

      await repo.upsert(running);

      final stored = (await repo.loadAll()).single;
      expect(stored.isFinished, isFalse);
      expect(stored.endedAt, isNull);
      expect(stored, running);
    });

    test('loads sessions saved before step records existed', () async {
      // Exactly what a 1.2 build wrote: no steps, no heart rate.
      File('${tempDir.path}/sessions.json').writeAsStringSync('''
[{"id":"s1","planId":"plan-1","planName":"Full Body Sample",
  "startedAt":"2026-09-20T18:00:00.000","endedAt":"2026-09-20T18:40:00.000",
  "totalActiveSeconds":2100,"status":"completed",
  "stepsCompleted":20,"stepsSkipped":2}]
''');
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );

      final loaded = (await repo.loadAll()).single;

      expect(loaded.planName, 'Full Body Sample');
      expect(loaded.stepsCompleted, 20);
      expect(loaded.hasStepRecords, isFalse);
      expect(loaded.steps, isEmpty);
      expect(loaded.averageBpm, isNull);
    });

    test('one unreadable session does not take the rest with it', () async {
      File('${tempDir.path}/sessions.json').writeAsStringSync('''
[{"id":"s1","planId":"p","planName":"Kept",
  "startedAt":"2026-09-20T18:00:00.000"},
 {"id":"s2","planId":"p","planName":"Broken","startedAt":"not a date"},
 {"id":"s3","planId":"p","planName":"Also kept",
  "startedAt":"2026-09-21T18:00:00.000",
  "steps":[{"name":"Squat","outcome":"sideways"}]}]
''');
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );

      final loaded = await repo.loadAll();

      expect(loaded.map((s) => s.planName), ['Kept', 'Also kept']);
      // A bad step list costs that session its detail, not its place.
      expect(loaded.last.hasStepRecords, isFalse);
    });

    test('saving leaves an entry it cannot read untouched on disk', () async {
      File('${tempDir.path}/sessions.json').writeAsStringSync(
        '[{"id":"s2","planId":"p","planName":"From a newer build",'
        '"startedAt":"2026-09-20T18:00:00.000","status":"paused"}]',
      );
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );

      await repo.upsert(session('s1', DateTime(2026, 9, 22, 18)));

      final raw = File('${tempDir.path}/sessions.json').readAsStringSync();
      expect(raw, contains('From a newer build'));
      expect((await repo.loadAll()).map((s) => s.id), ['s1']);
    });

    test('step records and heart rate survive a round trip', () async {
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );
      final saved = session('s1', DateTime(2026, 9, 22, 18)).copyWith(
        plannedSteps: 3,
        steps: const [
          StepRecord(
            name: 'Squat',
            target: '10 reps',
            intensity: StepIntensity.active,
            outcome: StepOutcome.done,
            activeSeconds: 72,
            averageBpm: 128,
          ),
          StepRecord(
            name: 'Rest',
            target: '01:00',
            intensity: StepIntensity.rest,
            outcome: StepOutcome.skipped,
            activeSeconds: 0,
          ),
        ],
        averageBpm: 124,
        maxBpm: 171,
      );

      await repo.upsert(saved);
      final loaded = (await repo.loadAll()).single;

      expect(loaded, saved);
      expect(loaded.hasStepRecords, isTrue);
      expect(loaded.stepsNotReached, 1);
    });

    test('recovers from a corrupt history file', () async {
      File('${tempDir.path}/sessions.json').writeAsStringSync('[[[');
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );

      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('JsonFileStore durability', () {
    test('overlapping writes queue, and the last one wins', () async {
      final store = FileDocumentStore('doc.json', directory: tempDir);

      await Future.wait([for (var i = 0; i < 20; i++) store.write(i)]);

      expect(await store.read(), 19);
    });

    test('leaves no temporary file behind after a write', () async {
      final repo = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );

      await repo.save(samplePlan());

      final names = tempDir.listSync().map((e) => e.path.split('/').last);
      expect(names, ['plan.json']);
    });

    test('an interrupted write cannot destroy the previous version', () async {
      final repo = PlanRepository(
        store: FileDocumentStore('plan.json', directory: tempDir),
      );
      await repo.save(samplePlan(id: 'good'));
      // Simulate a crash between write and rename.
      File('${tempDir.path}/plan.json.tmp').writeAsStringSync('{half-writ');

      expect((await repo.load())?.id, 'good');
    });
  });

  group('SettingsRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to following the system theme with no plan', () async {
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      final settings = await repo.load();

      expect(settings.themeMode, ThemeMode.system);
      expect(settings.activePlanId, isNull);
      expect(settings.hasActivePlan, isFalse);
    });

    test('round-trips the theme and the active plan', () async {
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      await repo.save(
        const AppSettings(themeMode: ThemeMode.dark, activePlanId: 'plan-1'),
      );

      final settings = await repo.load();
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.activePlanId, 'plan-1');
    });

    test('round-trips the paired heart-rate sensor', () async {
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      await repo.save(
        const AppSettings(
          heartRateMonitorId: 'AA:BB:CC',
          heartRateMonitorName: 'Forerunner 965',
        ),
      );

      final settings = await repo.load();
      expect(settings.heartRateMonitorId, 'AA:BB:CC');
      expect(settings.heartRateMonitorName, 'Forerunner 965');
      expect(settings.withoutHeartRateMonitor().hasHeartRateMonitor, isFalse);
    });

    test('round-trips the cues toggle, on by default', () async {
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );
      expect((await repo.load()).areCuesEnabled, isTrue);

      await repo.save(const AppSettings(areCuesEnabled: false));

      expect((await repo.load()).areCuesEnabled, isFalse);
    });

    test('keeps cues on for settings saved before the toggle', () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepository.storageKey: jsonEncode({'themeMode': 'dark'}),
      });
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      expect((await repo.load()).areCuesEnabled, isTrue);
    });

    test(
      'falls back to defaults when the stored value is unreadable',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsRepository.storageKey: 'not json',
        });
        final repo = SettingsRepository(
          preferences: await SharedPreferences.getInstance(),
        );

        expect(await repo.load(), const AppSettings());
      },
    );

    test('ignores a theme name it does not recognise', () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepository.storageKey: jsonEncode({'themeMode': 'sepia'}),
      });
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      expect((await repo.load()).themeMode, ThemeMode.system);
    });

    test('defaults the color theme with no stored settings', () async {
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      expect((await repo.load()).themeId, GimmyThemeId.fallback);
    });

    test('round-trips the color theme', () async {
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      await repo.save(
        const AppSettings(themeId: GimmyThemeId.sophisticatedBlue),
      );

      expect((await repo.load()).themeId, GimmyThemeId.sophisticatedBlue);
    });

    test('a settings file with no themeId key falls back quietly', () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepository.storageKey: jsonEncode({'themeMode': 'dark'}),
      });
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      expect((await repo.load()).themeId, GimmyThemeId.fallback);
    });

    test('ignores a color theme name it does not recognise', () async {
      SharedPreferences.setMockInitialValues({
        SettingsRepository.storageKey: jsonEncode({'themeId': 'sepia'}),
      });
      final repo = SettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      );

      expect((await repo.load()).themeId, GimmyThemeId.fallback);
    });

    test(
      'ignores the legacy accentColor key from before themes shipped',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsRepository.storageKey: jsonEncode({
            'themeMode': 'dark',
            'accentColor': '#00E676',
          }),
        });
        final repo = SettingsRepository(
          preferences: await SharedPreferences.getInstance(),
        );

        final settings = await repo.load();
        expect(settings.themeMode, ThemeMode.dark);
        expect(settings.themeId, GimmyThemeId.fallback);
      },
    );

    test('clear wipes the stored settings', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SettingsRepository(preferences: prefs);
      await repo.save(const AppSettings(themeMode: ThemeMode.light));

      await repo.clear();

      expect(prefs.getString(SettingsRepository.storageKey), isNull);
      expect((await repo.load()).themeMode, ThemeMode.system);
    });
  });
}
