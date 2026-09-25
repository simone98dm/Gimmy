import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../data/models/workout_session.dart';
import '../../history/session_outcome.dart';
import '../../history/view/session_detail_page.dart';

/// Lists one day's sessions: time, duration, plan name and outcome.
Future<void> showDaySessionsSheet(
  BuildContext context, {
  required DateTime day,
  required List<WorkoutSession> sessions,
  List<WorkoutSession> history = const [],
}) {
  return showModalBottomSheet<void>(
    routeSettings: const RouteSettings(name: 'day-sessions sheet'),
    context: context,
    builder: (context) =>
        _DaySessionsSheet(day: day, sessions: sessions, history: history),
  );
}

class _DaySessionsSheet extends StatelessWidget {
  const _DaySessionsSheet({
    required this.day,
    required this.sessions,
    required this.history,
  });

  final DateTime day;
  final List<WorkoutSession> sessions;

  /// Every stored session, handed on so a session page can compare.
  final List<WorkoutSession> history;

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
              _SessionRow(session: session, history: history),
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
  const _SessionRow({required this.session, required this.history});

  final WorkoutSession session;
  final List<WorkoutSession> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    final isCompleted = session.status == SessionStatus.completed;
    final outcome = sessionOutcome(context, session.status);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isCompleted
              ? Icons.check_circle_outline
              : Icons.remove_circle_outline,
          color: outcome.color,
          size: 20,
        ),
        const SizedBox(width: GimmySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.planName, style: theme.textTheme.bodyLarge),
              const SizedBox(height: GimmySpacing.xxs),
              Text(
                '${DateFormat.Hm().format(session.startedAt)} · '
                '${DurationFormat.human(Duration(seconds: session.totalActiveSeconds))}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: GimmySpacing.xxs),
              Text(
                '${session.stepsCompleted} done · ${session.stepsSkipped} skipped',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          outcome.label.toUpperCase(),
          style: tokens.labelMono.copyWith(
            color: outcome.color,
            letterSpacing: GimmyType.capsTracking,
          ),
        ),
        Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      ],
    );

    return Semantics(
      button: true,
      label: '${session.planName}, ${outcome.label}, open session',
      excludeSemantics: true,
      // A Material above the row, so the ink shows on the sheet's surface.
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: GimmyRadii.button,
          onTap: () =>
              Navigator.of(context)
                  .push(SessionDetailPage.route(session, history: history)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: GimmySpacing.xs),
            child: row,
          ),
        ),
      ),
    );
  }
}
