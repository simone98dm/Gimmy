import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/util/relative_day.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/gimmy_badge.dart';
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
    final theme = Theme.of(context);
    if (sessions.isEmpty) {
      return Text(
        'Finished workouts will show up here.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    // Two on a desktop, where they sit beside the calendar and should end
    // about where it does.
    final isDesktop = isDesktopLayout(context);
    final recent = sessions.reversed.take(isDesktop ? 2 : _maxEntries).toList();

    if (isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: GimmySpacing.sm),
              Text('Recent sessions', style: theme.textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          for (final session in recent) ...[
            _LogCard(
              session: session,
              now: now,
              onTap: () => onSelected(session),
            ),
            if (session != recent.last) const SizedBox(height: GimmySpacing.md),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.xs),
          child: Text('Recent sessions', style: theme.textTheme.headlineSmall),
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

/// The desktop log entry: status and age, the plan, then a recessed row of
/// what the session added up to.
class _LogCard extends StatelessWidget {
  const _LogCard({
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
      SessionStatus.completed => ('Completed', tokens.intensityActive),
      SessionStatus.abandoned => ('Partial', tokens.intensityRest),
      null => ('Running', theme.colorScheme.onSurfaceVariant),
    };
    // Seconds under a minute, as everywhere else — "0 min" read as nothing.
    final seconds = session.totalActiveSeconds;
    final (timeValue, timeUnit) = seconds < 60
        ? ('$seconds', 's')
        : ('${seconds ~/ 60}', 'min');
    final time = DateFormat.Hm();

    return Material(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: GimmyRadii.card,
        side: BorderSide(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(GimmySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  GimmyBadge(label: statusLabel, color: statusColor),
                  const SizedBox(width: GimmySpacing.sm),
                  Text(
                    RelativeDay.format(session.startedAt, now: now),
                    style: tokens.labelMono.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: GimmySpacing.xs),
              Text(
                session.planName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: GimmySpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: GimmySpacing.sm + 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: GimmyRadii.button,
                ),
                child: Row(
                  children: [
                    _Figure(label: 'Time', value: timeValue, unit: timeUnit),
                    _Figure(
                      label: 'Steps done',
                      value: '${session.stepsCompleted}',
                    ),
                    _Figure(
                      label: 'Skipped',
                      value: '${session.stepsSkipped}',
                      color: session.stepsSkipped > 0
                          ? tokens.intensityRest
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GimmySpacing.sm + 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.endedAt == null
                          ? 'Started ${time.format(session.startedAt)}'
                          : '${time.format(session.startedAt)} – '
                                '${time.format(session.endedAt!)}',
                      style: tokens.labelMono.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (session.status == SessionStatus.completed)
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.unit,
    this.color,
  });

  final String label;
  final String value;
  final String? unit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text.rich(
            TextSpan(
              text: value,
              style: tokens.metricMd.copyWith(
                color: color ?? theme.colorScheme.onSurface,
              ),
              children: [
                if (unit != null)
                  TextSpan(text: ' $unit', style: tokens.labelMono),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
