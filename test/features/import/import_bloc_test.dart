import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/exercises/exercise_demos.dart';
import 'package:gimmy/data/exercises/exercise_matcher.dart';
import 'package:gimmy/data/fit/fit_file_picker.dart';
import 'package:gimmy/data/models/plan_step.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:gimmy/features/import/bloc/import_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_exercise_demos.dart';
import '../../support/sample_fit.dart';

final sampleBytes = sampleFitBytes();

PickedFitFile sampleFile() =>
    PickedFitFile(name: sampleFitFilename, bytes: sampleBytes);

void main() {
  // The bundled exercise catalog is read through the asset bundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PlanRepository planRepository;
  late SettingsRepository settingsRepository;
  late FakeExerciseMediaStore media;
  late ExerciseDemos demos;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gimmy-import');
    media = FakeExerciseMediaStore();
    demos = ExerciseDemos(media: media);
    SharedPreferences.setMockInitialValues({});
    planRepository = PlanRepository(
      store: FileDocumentStore('plan.json', directory: tempDir),
    );
    settingsRepository = SettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ImportBloc buildBloc({required Future<PickedFitFile?> Function() pickFile}) =>
      ImportBloc(
        pickFile: pickFile,
        planRepository: planRepository,
        settingsRepository: settingsRepository,
        demos: demos,
      );

  /// Runs [events] through [bloc] and returns every state it emitted.
  Future<List<ImportState>> run(
    ImportBloc bloc,
    List<ImportEvent> events,
  ) async {
    final emitted = <ImportState>[];
    final subscription = bloc.stream.listen(emitted.add);
    for (final event in events) {
      bloc.add(event);
      await pumpEventQueue();
      // Parsing and saving touch the real disk: wait for them to land rather
      // than for a fixed number of turns, which flakes on a busy machine.
      for (var i = 0; bloc.state.isBusy && i < 200; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }
    await subscription.cancel();
    return emitted;
  }

  group('trying the sample workout', () {
    test('previews the sample without the file picker', () async {
      var didPick = false;
      final bloc = buildBloc(
        pickFile: () async {
          didPick = true;
          return null;
        },
      );
      addTearDown(bloc.close);

      final states = await run(bloc, [const ImportSampleRequested()]);

      expect(didPick, isFalse);
      expect(states.last.status, ImportStatus.preview);
      expect(states.last.plan?.isSample, isTrue);
      expect(await planRepository.load(), isNull);
    });

    test('confirming saves the sample as the active plan', () async {
      final bloc = buildBloc(pickFile: () async => null);
      addTearDown(bloc.close);

      await run(bloc, [const ImportSampleRequested(), const ImportConfirmed()]);

      final saved = await planRepository.load();
      expect(saved?.isSample, isTrue);
      expect((await settingsRepository.load()).activePlanId, saved!.id);
    });
  });

  group('picking a valid workout file', () {
    test('parses through to a preview without touching storage', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [const ImportFileRequested()]);

      expect(states.map((s) => s.status), [
        ImportStatus.parsing,
        ImportStatus.preview,
      ]);
      expect(states.last.plan?.name, sampleFitPlanName);
      expect(states.last.plan?.stepCount, sampleFitStepCount);
      expect(states.last.filename, sampleFitFilename);

      // Crucially, nothing is saved until the user confirms.
      expect(await planRepository.load(), isNull);
      expect((await settingsRepository.load()).activePlanId, isNull);
    });

    test('confirming saves the plan and makes it active', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [
        const ImportFileRequested(),
        const ImportConfirmed(),
      ]);

      expect(states.last.status, ImportStatus.saved);

      final saved = await planRepository.load();
      expect(saved, isNotNull);
      expect(saved!.stepCount, sampleFitStepCount);
      expect((await settingsRepository.load()).activePlanId, saved.id);
    });

    test('a second import replaces the first as the active plan', () async {
      final first = buildBloc(pickFile: () async => sampleFile());
      await run(first, [const ImportFileRequested(), const ImportConfirmed()]);
      final firstId = (await planRepository.load())!.id;
      await first.close();

      final second = buildBloc(pickFile: () async => sampleFile());
      addTearDown(second.close);
      await run(second, [const ImportFileRequested(), const ImportConfirmed()]);

      final activeId = (await settingsRepository.load()).activePlanId;
      expect(activeId, isNot(firstId));
      expect((await planRepository.load())!.id, activeId);
    });

    test('reset clears the preview without unsaving anything', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [
        const ImportFileRequested(),
        const ImportReset(),
      ]);

      expect(states.last.status, ImportStatus.idle);
      expect(states.last.plan, isNull);
    });
  });

  group('cancelling', () {
    test('returns to idle and is not treated as an error', () async {
      final bloc = buildBloc(pickFile: () async => null);
      addTearDown(bloc.close);

      final states = await run(bloc, [const ImportFileRequested()]);

      expect(states.map((s) => s.status), [
        ImportStatus.parsing,
        ImportStatus.idle,
      ]);
      expect(states.last.errorMessage, isNull);
    });
  });

  group('rejecting bad files', () {
    test('a non-FIT file fails with a message and stores nothing', () async {
      final bloc = buildBloc(
        pickFile: () async => PickedFitFile(
          name: 'notes.fit',
          bytes: File('pubspec.yaml').readAsBytesSync(),
        ),
      );
      addTearDown(bloc.close);

      final states = await run(bloc, [const ImportFileRequested()]);

      expect(states.last.status, ImportStatus.failure);
      expect(states.last.plan, isNull);
      expect(
        states.last.errorMessage,
        contains('not in the Garmin FIT format'),
      );
      expect(await planRepository.load(), isNull);
      expect((await settingsRepository.load()).activePlanId, isNull);
    });

    test('a wrong extension is caught before the bytes are read', () async {
      final bloc = buildBloc(
        pickFile: () async =>
            PickedFitFile(name: 'workout.tcx', bytes: Uint8List(0)),
      );
      addTearDown(bloc.close);

      final states = await run(bloc, [const ImportFileRequested()]);

      expect(states.last.status, ImportStatus.failure);
      expect(states.last.errorMessage, contains('not a .fit file'));
    });

    test('a corrupt file fails and keeps the previously saved plan', () async {
      // Save a good plan first.
      final good = buildBloc(pickFile: () async => sampleFile());
      await run(good, [const ImportFileRequested(), const ImportConfirmed()]);
      await good.close();
      final savedBefore = await planRepository.load();

      final corrupted = Uint8List.fromList(sampleBytes);
      corrupted[200] = corrupted[200] ^ 0xFF;
      final bad = buildBloc(
        pickFile: () async =>
            PickedFitFile(name: 'broken.fit', bytes: corrupted),
      );
      addTearDown(bad.close);

      final states = await run(bad, [const ImportFileRequested()]);

      expect(states.last.status, ImportStatus.failure);
      expect(states.last.errorMessage, contains('damaged'));
      expect(await planRepository.load(), savedBefore);
    });

    test('confirming is a no-op when there is no previewed plan', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [const ImportConfirmed()]);

      expect(states, isEmpty);
      expect(await planRepository.load(), isNull);
    });

    test(
      'a picker that throws surfaces an error instead of crashing',
      () async {
        final bloc = buildBloc(
          pickFile: () async => throw const FileSystemException('denied'),
        );
        addTearDown(bloc.close);
        // The bloc reports the error as well as recovering from it.
        bloc.stream.handleError((_) {});

        final states = await run(bloc, [const ImportFileRequested()]);

        expect(states.last.status, ImportStatus.failure);
        expect(states.last.errorMessage, isNotEmpty);
      },
    );
  });

  group('exercise demos', () {
    Iterable<String?> idsOf(ImportState state, String name) =>
        state.plan!.steps.where((s) => s.name == name).map((s) => s.exerciseId);

    test('the preview comes with every exercise matched', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [const ImportFileRequested()]);

      final squat = matchExercise('Squat', await demos.catalog());
      expect(idsOf(states.last, 'Squat'), everyElement(squat!.id));
      // Rest never gets a demo.
      expect(idsOf(states.last, 'Rest'), everyElement(isNull));
    });

    test('changing an exercise changes every step of it', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [
        const ImportFileRequested(),
        const ImportExerciseChanged(name: 'Squat', exerciseId: '0001'),
      ]);

      expect(states.last.status, ImportStatus.preview);
      expect(idsOf(states.last, 'Squat'), everyElement('0001'));
    });

    test('"no demo" clears it', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [
        const ImportFileRequested(),
        const ImportExerciseChanged(name: 'Squat', exerciseId: null),
      ]);

      expect(idsOf(states.last, 'Squat'), everyElement(isNull));
    });

    test('changing an exercise is ignored with nothing previewed', () async {
      final bloc = buildBloc(pickFile: () async => null);
      addTearDown(bloc.close);

      final states = await run(bloc, [
        const ImportExerciseChanged(name: 'Squat', exerciseId: '0001'),
      ]);

      expect(states, isEmpty);
    });

    test('confirming saves the chosen demos and fetches them', () async {
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      await run(bloc, [
        const ImportFileRequested(),
        const ImportExerciseChanged(name: 'Squat', exerciseId: '0001'),
        const ImportConfirmed(),
      ]);
      await pumpEventQueue();

      final saved = await planRepository.load();
      final squats = saved!.steps.where((s) => s.name == 'Squat');
      expect(squats.map((s) => s.exerciseId), everyElement('0001'));
      expect(media.prefetched, contains('0001'));
      expect(
        saved.steps.where((s) => s.intensity != StepIntensity.active),
        everyElement(predicate<PlanStep>((s) => s.exerciseId == null)),
      );
    });

    test('a demo that fails to download does not fail the import', () async {
      media = FakeExerciseMediaStore(failing: {'0001'});
      demos = ExerciseDemos(media: media);
      final bloc = buildBloc(pickFile: () async => sampleFile());
      addTearDown(bloc.close);

      final states = await run(bloc, [
        const ImportFileRequested(),
        const ImportExerciseChanged(name: 'Squat', exerciseId: '0001'),
        const ImportConfirmed(),
      ]);

      expect(states.last.status, ImportStatus.saved);
    });
  });
}
