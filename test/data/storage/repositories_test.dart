import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
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
  name: 'Total Body S2-4',
  sourceFilename: 'TotalBody_Sett2-4.fit',
  importedAt: DateTime.utc(2026, 9, 22, 10),
  steps: [
    PlanStep.timer(
      name: 'Tapis salita',
      intensity: StepIntensity.warmup,
      durationSeconds: 600,
    ),
    PlanStep.reps(
      name: 'Leg press',
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
  planName: 'Total Body S2-4',
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

    test('recovers from a corrupt history file', () async {
      File('${tempDir.path}/sessions.json').writeAsStringSync('[[[');
      final repo = SessionRepository(
        store: FileDocumentStore('sessions.json', directory: tempDir),
      );

      expect(await repo.loadAll(), isEmpty);
    });
  });

  group('JsonFileStore durability', () {
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
