import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/execution_bloc.dart';

/// Desktop shortcuts for the workout, sent through the same events as the
/// buttons so the double-tap guard and undo apply to keys too.
///
/// | Key | While running | On the summary |
/// |---|---|---|
/// | Space | Play / Pause / Done | — |
/// | S | Skip | — |
/// | − | −10 s on a timer | — |
/// | ⌘Z / Ctrl+Z | Undo, when offered | Undo last step |
/// | Esc | Leave (asks first) | — |
/// | Enter | — | Back to Today |
///
/// Only while the runner has focus: a dialog over it takes focus with it.
class RunnerKeyboard extends StatelessWidget {
  const RunnerKeyboard({super.key, required this.onDone, required this.child});

  /// Leaves the finished workout, as the summary's main button does.
  final VoidCallback onDone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExecutionBloc>();
    void whenRunning(ExecutionEvent event) {
      if (bloc.state.isRunning) bloc.add(event);
    }

    void undo() {
      if (bloc.state.canUndo) bloc.add(const ExecutionUndone());
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () =>
            whenRunning(const ExecutionPrimaryPressed()),
        const SingleActivator(LogicalKeyboardKey.keyS): () =>
            whenRunning(const ExecutionSkipped()),
        const SingleActivator(LogicalKeyboardKey.minus): () =>
            whenRunning(const ExecutionTimerAdjusted()),
        const SingleActivator(LogicalKeyboardKey.numpadSubtract): () =>
            whenRunning(const ExecutionTimerAdjusted()),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (bloc.state.isRunning) Navigator.of(context).maybePop();
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (bloc.state.isFinished) onDone();
        },
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
