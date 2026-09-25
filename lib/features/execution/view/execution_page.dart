import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/session_comparison.dart';
import '../bloc/execution_bloc.dart';
import '../widgets/completion_summary.dart';
import '../widgets/execution_desktop.dart';
import '../widgets/phone_runner.dart';
import '../widgets/runner_keyboard.dart';
import '../workout_cues.dart';

/// Guides the user through the active plan, one step at a time.
///
/// Laid out to match the Stitch "Active Workout & Timer Modal" screen: a
/// telemetry card on top, then one stage card holding everything about the
/// current step — chips, title, the countdown dial, the metric strip and the
/// controls — then the next-up card and the form tip. The completion summary
/// arrives as a modal over the top of it, not as a separate page.
class ExecutionPage extends StatefulWidget {
  const ExecutionPage({
    super.key,
    required this.onDone,
    this.areCuesEnabled = true,
    this.history = const [],
  });

  /// Leaves the workout, back to the Dashboard.
  final VoidCallback onDone;

  /// The user's Settings choice for step and completion cues.
  final bool areCuesEnabled;

  /// Past sessions, for the summary's "vs last time" line.
  final List<WorkoutSession> history;

  @override
  State<ExecutionPage> createState() => _ExecutionPageState();
}

class _ExecutionPageState extends State<ExecutionPage> {
  /// The last state the cues saw, so a listener call can tell what moved.
  ///
  /// Read in initState, not lazily: a lazy initialiser would first run inside
  /// the listener, already holding the new state, and the very first move
  /// would look like no move at all.
  late ExecutionState _previous;

  /// The phone runner's own messenger, so the undo snackbar lands above its
  /// pinned control bar. Absent on a desktop, where the page's messenger is
  /// used instead.
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  ScaffoldMessengerState? _messenger(BuildContext context) =>
      _messengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);

  @override
  void initState() {
    super.initState();
    _previous = context.read<ExecutionBloc>().state;
  }

  /// Done and Skip are thumbed at a phone on the floor, so a mis-tap has to be
  /// cheap: name the step that moved and offer it back.
  void _offerUndo(BuildContext context, ExecutionState state) {
    final bloc = context.read<ExecutionBloc>();
    final name = state.undoableStep!.name;
    final verb = state.lastAdvance == AdvanceKind.done ? 'done' : 'skipped';
    _messenger(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$name $verb',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          duration: _untilNextAction,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => bloc.add(const ExecutionUndone()),
          ),
        ),
      );
  }

  /// The offer stays until the next action takes it away (the listener hides
  /// it) or the user swipes it off: hands can be busy for more than a few
  /// seconds mid-set.
  static const _untilNextAction = Duration(days: 1);

  SessionComparison? _comparison(BuildContext context) {
    final current = context.read<ExecutionBloc>().session;
    final previous = previousRun(widget.history, current);
    return previous == null ? null : SessionComparison.of(current, previous);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExecutionBloc, ExecutionState>(
      // Sound and vibration live here rather than in the bloc: they are
      // feedback about a state change, not part of it, and a bloc test should
      // not have to silence a speaker.
      listener: (context, state) {
        final cue = cueFor(_previous, state);
        final didJustMove =
            state.canUndo &&
            (state.currentIndex != _previous.currentIndex ||
                !_previous.canUndo);
        _previous = state;
        if (cue != null && widget.areCuesEnabled) WorkoutCues.play(cue);
        // Past the last step the summary carries its own undo.
        if (didJustMove && !state.isFinished) {
          _offerUndo(context, state);
        } else if (!state.canUndo || state.isFinished) {
          _messenger(context)?.hideCurrentSnackBar();
        }
      },
      builder: (context, state) {
        final isReduced = GimmyMotion.isReduced(context);
        final page = Stack(
          children: [
            Positioned.fill(
              child: isDesktopLayout(context)
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GimmySpacing.gutter,
                        GimmySpacing.md,
                        GimmySpacing.gutter,
                        0,
                      ),
                      child: DesktopRunner(state: state),
                    )
                  : PhoneRunner(state: state, messengerKey: _messengerKey),
            ),
            // In instantly (the summary runs its own entrance), out with a
            // fade when Undo on the summary reopens the workout.
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: Duration.zero,
                reverseDuration: isReduced
                    ? Duration.zero
                    : GimmyMotion.pageTransitionReverse,
                child: state.isFinished
                    ? CompletionSummary(
                        key: const ValueKey('summary'),
                        state: state,
                        onDone: widget.onDone,
                        comparison: _comparison(context),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        );
        // A keyboard is a desktop's main control; a phone has none to bind.
        return isDesktopLayout(context)
            ? RunnerKeyboard(onDone: widget.onDone, child: page)
            : page;
      },
    );
  }
}
