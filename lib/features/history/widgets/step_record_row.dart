import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/session_comparison.dart';
import '../comparison_text.dart';

/// One step of a past session: what it was, whether it was done, how long it
/// took and how hard the heart worked.
class StepRecordRow extends StatelessWidget {
  const StepRecordRow({
    super.key,
    required this.number,
    required this.record,
    this.change,
  });

  final int number;
  final StepRecord record;

  /// Against the same step last time; null when there is nothing to compare.
  final StepComparison? change;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final isDone = record.outcome == StepOutcome.done;
    final mono = tokens.labelMono.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final time = DurationFormat.clock(Duration(seconds: record.activeSeconds));

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: GimmySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: GimmySpacing.lg,
            child: Text('$number', style: mono),
          ),
          Padding(
            padding: const EdgeInsets.only(right: GimmySpacing.sm),
            child: Icon(
              isDone ? Icons.check : Icons.redo,
              size: 18,
              color: isDone
                  ? tokens.intensityActive
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    // Skipped steps recede; done ones carry the list.
                    color: isDone ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  isDone ? record.target : '${record.target} · skipped',
                  style: mono,
                ),
              ],
            ),
          ),
          const SizedBox(width: GimmySpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // A skipped step took no time worth a clock.
              Text(isDone ? time : '–', style: tokens.metricMd),
              if (_changeLine case final line?) Text(line, style: mono),
              if (record.averageBpm case final bpm?)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // An icon, not a ♥ glyph: the mono face has none.
                    Icon(
                      Icons.favorite,
                      size: 12,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: GimmySpacing.xs),
                    Text('$bpm', style: mono),
                  ],
                ),
            ],
          ),
        ],
      ),
    );

    return Semantics(
      label: [
        'Step $number',
        record.name,
        record.target,
        isDone ? 'done' : 'skipped',
        '${_spoken(record.activeSeconds)} active',
        if (record.averageBpm case final bpm?) 'average $bpm BPM',
        if (_changeLine case final line?) 'last time: $line',
      ].join(', '),
      excludeSemantics: true,
      child: row,
    );
  }

  /// "1 min 12 s": a step is short enough that the seconds matter, and the
  /// "01:12" on screen does not read well aloud.
  static String _spoken(int seconds) {
    if (seconds < 60) return '$seconds s';
    final rest = seconds % 60;
    return rest == 0 ? '${seconds ~/ 60} min' : '${seconds ~/ 60} min $rest s';
  }

  String? get _changeLine {
    final c = change;
    if (c == null) return null;
    final line = stepChangeLine(c, record.outcome);
    return line.isEmpty ? null : line;
  }
}
