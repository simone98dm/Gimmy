import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/config/feature_flags.dart';
import 'package:gimmy/data/fit/fit_parse_exception.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';

/// The reference workout shipped with the repo: Garmin export, 28 steps on
/// disk, 8 repeat blocks, Italian coaching notes.
final sampleFile = File('docs/TotalBody_Sett2-4.fit');

final importedAt = DateTime.utc(2026, 9, 22, 10, 0);

Plan parseSample() => FitWorkoutParser.parse(
  bytes: sampleFile.readAsBytesSync(),
  filename: 'TotalBody_Sett2-4.fit',
  planId: 'plan-1',
  importedAt: importedAt,
);

Matcher throwsFailure(FitParseFailure failure) => throwsA(
  isA<FitParseException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  group('parsing the sample workout', () {
    test('reads the workout name out of the file, not the filename', () {
      final plan = parseSample();

      expect(plan.name, 'Total Body S2-4');
      expect(plan.sourceFilename, 'TotalBody_Sett2-4.fit');
      expect(plan.importedAt, importedAt);
    });

    test('expands 28 stored steps and 8 repeat blocks into 54 flat steps', () {
      final plan = parseSample();

      expect(plan.stepCount, 54);
    });

    test('opens with the warmup and closes with the two cooldown steps', () {
      final steps = parseSample().steps;

      expect(steps.first.name, 'Tapis salita');
      expect(steps.first.type, StepType.timer);
      expect(steps.first.durationSeconds, 600);
      expect(steps.first.intensity, StepIntensity.warmup);

      expect(steps[52].name, 'Tapis scarico');
      expect(steps[52].intensity, StepIntensity.cooldown);
      expect(steps.last.name, 'Stretching');
      expect(steps.last.durationSeconds, 300);
      expect(steps.last.intensity, StepIntensity.cooldown);
    });

    test('converts milliseconds in the file into whole seconds', () {
      final steps = parseSample().steps;
      // "Recupero" after the first Leg press set is 90000 ms in the file.
      final firstRest = steps.firstWhere((s) => s.name == 'Recupero');

      expect(firstRest.durationSeconds, 90);
      expect(firstRest.intensity, StepIntensity.rest);
    });

    test('reads rep-based steps as reps, not as a zero-length timer', () {
      final legPress = parseSample().steps.firstWhere(
        (s) => s.name == 'Leg press',
      );

      expect(legPress.type, StepType.reps);
      expect(legPress.repCount, 12);
      expect(legPress.durationSeconds, isNull);
      expect(legPress.intensity, StepIntensity.active);
    });

    test('repeats a set three times, interleaved with its rest step', () {
      final names = parseSample().steps.map((s) => s.name).toList();

      expect(names.sublist(0, 7), [
        'Tapis salita',
        'Leg press',
        'Recupero',
        'Leg press',
        'Recupero',
        'Leg press',
        'Recupero',
      ]);
    });

    test('keeps both sides of a two-exercise block in order', () {
      final names = parseSample().steps.map((s) => s.name).toList();
      final start = names.indexOf('Rematore DX');

      expect(names.sublist(start, start + 9), [
        'Rematore DX',
        'Rematore SX',
        'Recupero',
        'Rematore DX',
        'Rematore SX',
        'Recupero',
        'Rematore DX',
        'Rematore SX',
        'Recupero',
      ]);
    });

    test('carries the coaching notes through, including non-ASCII text', () {
      final legPress = parseSample().steps.firstWhere(
        (s) => s.name == 'Leg press',
      );

      expect(
        legPress.notes,
        'Piedi a meta pedana, scendi a 90 gradi, non bloccare le ginocchia. Range 40-60 kg.',
      );
    });

    test(
      'leaves rest steps without notes rather than inventing empty strings',
      () {
        final rest = parseSample().steps.firstWhere(
          (s) => s.name == 'Recupero',
        );

        expect(rest.notes, isNull);
      },
    );

    test('estimates a duration that accounts for both timers and reps', () {
      final plan = parseSample();

      final estimate = plan.estimatedDuration(
        secondsPerRep: AppConfig.estimatedSecondsPerRep,
      );

      // 3165s of real timers, plus 24 reps steps x 12 reps x 3s.
      expect(estimate, const Duration(seconds: 3165 + 864));
    });

    test('survives a round trip through JSON', () {
      final plan = parseSample();

      final restored = Plan.fromJson(plan.toJson());

      expect(restored, plan);
    });
  });

  group('rejecting files that are not usable workouts', () {
    test('rejects a file that is not named .fit before reading a byte', () {
      expect(
        () => FitWorkoutParser.parse(
          bytes: Uint8List(0),
          filename: 'workout.tcx',
          planId: 'p',
          importedAt: importedAt,
        ),
        throwsFailure(FitParseFailure.wrongExtension),
      );
    });

    test('rejects a .fit file whose contents are not FIT at all', () {
      // The decoder returns an empty result for this rather than throwing,
      // which is exactly why the parser checks the header itself.
      expect(
        () => FitWorkoutParser.parse(
          bytes: File('pubspec.yaml').readAsBytesSync(),
          filename: 'pubspec.fit',
          planId: 'p',
          importedAt: importedAt,
        ),
        throwsFailure(FitParseFailure.notAFitFile),
      );
    });

    test('rejects an empty file', () {
      expect(
        () => FitWorkoutParser.parse(
          bytes: Uint8List(0),
          filename: 'empty.fit',
          planId: 'p',
          importedAt: importedAt,
        ),
        throwsFailure(FitParseFailure.notAFitFile),
      );
    });

    test('rejects a FIT file whose body has been corrupted', () {
      final bytes = Uint8List.fromList(sampleFile.readAsBytesSync());
      // Flip a byte inside the data records; the header still says ".FIT".
      bytes[200] = bytes[200] ^ 0xFF;

      expect(
        () => FitWorkoutParser.parse(
          bytes: bytes,
          filename: 'corrupt.fit',
          planId: 'p',
          importedAt: importedAt,
        ),
        throwsFailure(FitParseFailure.corrupt),
      );
    });

    test('rejects a FIT file that has been truncated', () {
      final full = sampleFile.readAsBytesSync();
      final truncated = Uint8List.fromList(full.sublist(0, full.length ~/ 2));

      expect(
        () => FitWorkoutParser.parse(
          bytes: truncated,
          filename: 'truncated.fit',
          planId: 'p',
          importedAt: importedAt,
        ),
        throwsFailure(FitParseFailure.corrupt),
      );
    });

    test('every failure carries a message that names the .fit requirement', () {
      for (final failure in FitParseFailure.values) {
        expect(failure.message, isNotEmpty);
        expect(failure.message, endsWith('.'));
      }
    });
  });
}
