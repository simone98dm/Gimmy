import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../data/models/workout_session.dart';

/// Lists one day's sessions: time, duration, plan name and outcome.
Future<void> showDaySessionsSheet(
  BuildContext context, {
  required DateTime day,
  required List<WorkoutSession> sessions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => _DaySessionsSheet(day: day, sessions: sessions),
  );
}

class _DaySessionsSheet extends StatelessWidget {
  const _DaySessionsSheet({required this.day, required this.sessions});

  final DateTime day;
  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GimmySpacing.md,
          0,
          GimmySpacing.md,
          GimmySpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMMEEEEd().format(day),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: GimmySpacing.md),
            for (final session in sessions) ...[
              _SessionRow(session: session),
              if (session != sessions.last)
                Divider(color: tokens.cardBorder, height: GimmySpacing.lg),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final WorkoutSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    final isCompleted = session.status == SessionStatus.completed;
    final statusColor = switch (session.status) {
      SessionStatus.completed => tokens.intensityActive,
      SessionStatus.abandoned => tokens.timerCritical,
      null => tokens.intensityRest,
    };
    final statusLabel = switch (session.status) {
      SessionStatus.completed => 'COMPLETED',
      SessionStatus.abandoned => 'ABANDONED',
      null => 'IN PROGRESS',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCompleted
              ? Icons.check_circle_outline
              : Icons.remove_circle_outline,
          color: statusColor,
          size: 20,
        ),
        const SizedBox(width: GimmySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.planName, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(
                '${DateFormat.Hm().format(session.startedAt)} · '
                '${DurationFormat.human(Duration(seconds: session.totalActiveSeconds))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${session.stepsCompleted} done · ${session.stepsSkipped} skipped',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(statusLabel, style: tokens.labelMono.copyWith(color: statusColor)),
      ],
    );
  }
}
