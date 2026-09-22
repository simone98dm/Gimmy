import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'bloc/execution_bloc.dart';

/// The two moments in a workout worth announcing without looking at the screen.
enum WorkoutCue {
  /// The workout moved on to the next step, by hand or because a timer ran out.
  step,

  /// Every step is done.
  complete,
}

/// Which cue — if any — the move from [previous] to [current] deserves.
///
/// Finishing changes the step index *and* the status in a single emit, so the
/// completion cue has to win over the step cue. Abandoning gets nothing: the
/// user chose to stop and already confirmed it in a dialog.
WorkoutCue? cueFor(ExecutionState previous, ExecutionState current) {
  if (current.status == ExecutionStatus.completed &&
      previous.status != ExecutionStatus.completed) {
    return WorkoutCue.complete;
  }
  if (current.isRunning && current.currentIndex != previous.currentIndex) {
    return WorkoutCue.step;
  }
  return null;
}

/// Plays the sound and fires the vibration for a [WorkoutCue].
///
/// Audio here is a nicety on top of a screen the user can always look at, so
/// every failure is logged and swallowed: a device with no haptics, a browser
/// that has not been tapped yet and so refuses to start audio, or a test
/// environment with no plugins must not take the workout down with it.
abstract final class WorkoutCues {
  /// Turned off by `silenceWorkoutCues()` in tests. audioplayers opens a
  /// platform event stream as soon as it is touched, and under `flutter_test`
  /// the missing plugin is reported through `FlutterError` — somewhere no
  /// try/catch can reach — which fails the test that happened to run a step.
  static bool enabled = true;

  static const _assets = {
    WorkoutCue.step: 'audio/step.wav',
    WorkoutCue.complete: 'audio/complete.wav',
  };

  static AudioPlayer? _player;

  static Future<void> play(WorkoutCue cue) async {
    if (!enabled) return;
    await Future.wait([_vibrate(cue), _sound(cue)]);
  }

  static Future<void> _vibrate(WorkoutCue cue) async {
    try {
      await switch (cue) {
        WorkoutCue.step => HapticFeedback.mediumImpact(),
        WorkoutCue.complete => HapticFeedback.heavyImpact(),
      };
    } catch (error, stackTrace) {
      _report('haptic', error, stackTrace);
    }
  }

  static Future<void> _sound(WorkoutCue cue) async {
    try {
      await (_player ??= await _openPlayer()).play(
        AssetSource(_assets[cue]!),
        mode: PlayerMode.lowLatency,
      );
    } catch (error, stackTrace) {
      _report('sound', error, stackTrace);
    }
  }

  /// An ambient, sonification session: a cue is a beep over whatever the user
  /// is listening to, and must never pause their music. (`ambient` already
  /// mixes, and audioplayers asserts if `mixWithOthers` is set alongside it.)
  static Future<AudioPlayer> _openPlayer() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
      ),
    );
    return AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  static void _report(String what, Object error, StackTrace stackTrace) {
    debugPrint('Workout $what cue failed: $error\n$stackTrace');
  }
}
