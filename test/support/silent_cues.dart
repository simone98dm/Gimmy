import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/features/execution/workout_cues.dart';

/// Silences the workout cues for every test in the current group.
///
/// A widget test that actually runs a step would otherwise reach audioplayers,
/// whose platform channels do not exist here; see [WorkoutCues.enabled].
void silenceWorkoutCues() {
  setUp(() => WorkoutCues.enabled = false);
  tearDown(() => WorkoutCues.enabled = true);
}
