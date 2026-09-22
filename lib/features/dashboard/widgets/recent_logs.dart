import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/util/relative_day.dart';
import '../../../data/models/workout_session.dart';

/// The last few sessions, newest first.
class RecentLogs extends StatelessWidget {
  const RecentLogs({
    super.key,
    required this.sessions,
    required this.now,
    required this.onSelected,
  });

  final List<WorkoutSession> sessions;

  /// Injected rather than read from the clock, so "Yesterday" is testable.
  final DateTime now;

  final void Function(WorkoutSession session) onSelected;

  /// Enough to show a pattern without turning the dashboard into a list page.
  static const int _maxEntries = 3;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final recent = sessions.reversed.take(_maxEntries).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.xs),
          child: Text('Recent Logs', style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: GimmySpacing.sm),
        for (final session in recent) ...[
          _LogRow(session: session, now: now, onTap: () => onSelected(session)),
          if (session != recent.last) const SizedBox(height: GimmySpacing.xs),
        ],
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({
    required this.session,
    required this.now,
    required this.onTap,
  });

  final WorkoutSession session;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    final (statusLabel, statusColor) = switch (session.status) {
      SessionStatus.completed => ('DONE', tokens.intensityActive),
      SessionStatus.abandoned => ('PARTIAL', tokens.intensityRest),
      null => ('RUNNING', theme.colorScheme.onSurfaceVariant),
    };

    return Semantics(
      button: true,
      label:
          '${session.planName}, '
          '${RelativeDay.format(session.startedAt, now: now)}, $statusLabel',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: GimmyRadii.card,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GimmySpacing.sm + 6),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: GimmyRadii.card,
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: GimmySpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.planName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${RelativeDay.format(session.startedAt, now: now)}'
                        ' • ${DurationFormat.human(Duration(seconds: session.totalActiveSeconds))}'
                        ' • ${session.stepsCompleted} steps',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.labelMono.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: GimmySpacing.sm),
                Text(
                  statusLabel,
                  style: tokens.labelMono.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
