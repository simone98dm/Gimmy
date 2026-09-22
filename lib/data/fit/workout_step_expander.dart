import '../../core/config/feature_flags.dart';
import '../models/plan_step.dart';
import 'fit_parse_exception.dart';

/// One `workout_step` message, reduced to just what flattening needs.
///
/// Keeping this free of FIT SDK types lets the expander — the only genuinely
/// tricky part of importing — be tested without building FIT binaries.
class RawStep {
  const RawStep.exercise({required this.messageIndex, required this.step})
    : repeatFromIndex = null,
      repeatCount = null;

  const RawStep.repeat({
    required this.messageIndex,
    required this.repeatFromIndex,
    required this.repeatCount,
  }) : step = null;

  /// `workout_step.message_index`. Repeat steps jump to one of these, which is
  /// not necessarily a position in the list.
  final int messageIndex;

  /// Null for a repeat marker.
  final PlanStep? step;

  /// The `message_index` this repeat jumps back to.
  final int? repeatFromIndex;

  /// Total times the block runs, counting the pass that already happened.
  final int? repeatCount;

  bool get isRepeat => step == null;
}

/// Flattens FIT repeat blocks into the linear list the user will walk through.
///
/// FIT encodes a repeat as a marker step placed *after* the block: it carries
/// the `message_index` to jump back to and the total number of iterations,
/// including the pass that just finished. So `[A, B, repeat(from: A, count: 3)]`
/// means A B A B A B.
///
/// Walks the steps like an interpreter with a program counter and one loop
/// counter per repeat marker. That handles nested repeats for free — resetting
/// a finished inner counter is what lets an enclosing block re-enter it — and
/// is shorter than special-casing the flat form.
List<PlanStep> expandRepeats(List<RawStep> raw) {
  final positionOf = {
    for (var i = 0; i < raw.length; i++) raw[i].messageIndex: i,
  };

  final expanded = <PlanStep>[];
  final iterationsLeft = <int, int>{};

  var position = 0;
  while (position < raw.length) {
    final current = raw[position];

    if (!current.isRepeat) {
      expanded.add(current.step!);
      if (expanded.length > AppConfig.maxExpandedSteps) {
        throw const FitParseException(
          FitParseFailure.tooManySteps,
          'Expansion exceeded ${AppConfig.maxExpandedSteps} steps',
        );
      }
      position++;
      continue;
    }

    final target = positionOf[current.repeatFromIndex];
    if (target == null || target >= position) {
      throw FitParseException(
        FitParseFailure.corrupt,
        'Repeat step ${current.messageIndex} jumps to '
        '${current.repeatFromIndex}, which is not an earlier step',
      );
    }

    // First time here, the block has already run once.
    final remaining =
        iterationsLeft[position] ??
        (current.repeatCount! - 1).clamp(0, _maxIterations);

    if (remaining > 0) {
      iterationsLeft[position] = remaining - 1;
      position = target;
      continue;
    }

    // Done. Forget the counter so an enclosing repeat can run this block again.
    iterationsLeft.remove(position);
    position++;
  }

  return List.unmodifiable(expanded);
}

/// Upper bound on a single block's iterations. [AppConfig.maxExpandedSteps]
/// is the real guard; this only stops a corrupt count from overflowing first.
const int _maxIterations = 10000;
