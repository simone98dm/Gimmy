import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/config/feature_flags.dart';
import 'package:gimmy/data/fit/fit_parse_exception.dart';
import 'package:gimmy/data/fit/fit_workout_parser.dart';
import 'package:gimmy/data/models/plan.dart';
import 'package:gimmy/data/models/plan_step.dart';

import '../../support/sample_fit.dart';

final importedAt = DateTime.utc(2026, 9, 22, 10, 0);

Plan parseSample() => FitWorkoutParser.parse(
  bytes: sampleFitBytes(),
  filename: sampleFitFilename,
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

      expect(plan.name, sampleFitPlanName);
      expect(plan.sourceFilename, sampleFitFilename);
      expect(plan.importedAt, importedAt);
    });

    test('expands 13 stored steps and 3 repeat blocks into 22 flat steps', () {
      expect(parseSample().stepCount, sampleFitStepCount);
    });

    test('opens with the warmup and closes with the two cooldown steps', () {
      final steps = parseSample().steps;

      expect(steps.first.name, 'Warm-up bike');
      expect(steps.first.type, StepType.timer);
      expect(steps.first.durationSeconds, 300);
      expect(steps.first.intensity, StepIntensity.warmup);

      expect(steps[20].name, 'Cool-down walk');
      expect(steps[20].intensity, StepIntensity.cooldown);
      expect(steps.last.name, 'Stretching');
      expect(steps.last.durationSeconds, 180);
      expect(steps.last.intensity, StepIntensity.cooldown);
    });

    test('converts milliseconds in the file into whole seconds', () {
      // The first "Rest" is 60000 ms in the file.
      final firstRest = parseSample().steps.firstWhere((s) => s.name == 'Rest');

      expect(firstRest.durationSeconds, 60);
      expect(firstRest.intensity, StepIntensity.rest);
    });

    test('reads rep-based steps as reps, not as a zero-length timer', () {
      final squat = parseSample().steps.firstWhere((s) => s.name == 'Squat');

      expect(squat.type, StepType.reps);
      expect(squat.repCount, 10);
      expect(squat.durationSeconds, isNull);
      expect(squat.intensity, StepIntensity.active);
    });

    test('repeats a set three times, interleaved with its rest step', () {
      final names = parseSample().steps.map((s) => s.name).toList();

      expect(names.sublist(0, 7), [
        'Warm-up bike',
        'Squat',
        'Rest',
        'Squat',
        'Rest',
        'Squat',
        'Rest',
      ]);
    });

    test('keeps both sides of a two-exercise block in order', () {
      final names = parseSample().steps.map((s) => s.name).toList();
      final start = names.indexOf('Row left');

      expect(names.sublist(start, start + 9), [
        'Row left',
        'Row right',
        'Rest',
        'Row left',
        'Row right',
        'Rest',
        'Row left',
        'Row right',
        'Rest',
      ]);
    });

    test('carries the coaching notes through, including non-ASCII text', () {
      final squat = parseSample().steps.firstWhere((s) => s.name == 'Squat');

      expect(squat.notes, sampleFitSquatNotes);
    });

    test(
      'leaves rest steps without notes rather than inventing empty strings',
      () {
        final rest = parseSample().steps.firstWhere((s) => s.name == 'Rest');

        expect(rest.notes, isNull);
      },
    );

    test('estimates a duration that accounts for both timers and reps', () {
      final estimate = parseSample().estimatedDuration(
        secondsPerRep: AppConfig.estimatedSecondsPerRep,
      );

      expect(
        estimate,
        const Duration(
          seconds:
              sampleFitTimerSeconds +
              sampleFitTotalReps * AppConfig.estimatedSecondsPerRep,
        ),
      );
    });

    test('survives a round trip through JSON', () {
      final plan = parseSample();

      expect(Plan.fromJson(plan.toJson()), plan);
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
      final bytes = sampleFitBytes();
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
      final full = sampleFitBytes();
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
