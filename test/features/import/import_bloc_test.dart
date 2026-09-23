import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/fit/fit_file_picker.dart';
import 'package:gimmy/data/storage/document_store_io.dart';
import 'package:gimmy/data/storage/plan_repository.dart';
import 'package:gimmy/data/storage/settings_repository.dart';
import 'package:gimmy/features/import/bloc/import_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/sample_fit.dart';

final sampleBytes = sampleFitBytes();

PickedFitFile sampleFile() =>
    PickedFitFile(name: sampleFitFilename, bytes: sampleBytes);

void main() {
  late Directory tempDir;
  late PlanRepository planRepository;
  late SettingsRepository settingsRepository;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('gimmy-import');
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
    }
    await subscription.cancel();
    return emitted;
  }

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
}
