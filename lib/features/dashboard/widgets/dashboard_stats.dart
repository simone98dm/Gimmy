import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/gimmy_badge.dart';
import '../../../data/training_stats.dart';
import 'streak_pill.dart';

/// The desktop dashboard's strip under the header: the streak, then how much
/// history there is.
class DashboardStatusStrip extends StatelessWidget {
  const DashboardStatusStrip({
    super.key,
    required this.stats,
    required this.sessionCount,
  });

  final TrainingStats stats;
  final int sessionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final muted = tokens.labelMono.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: GimmyType.capsTracking,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.lg,
        vertical: GimmySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          StreakPill(streak: stats.streak, best: stats.bestStreak),
          const Spacer(),
          Text(
            '$sessionCount ${sessionCount == 1 ? 'SESSION' : 'SESSIONS'} LOGGED',
            style: muted,
          ),
        ],
      ),
    );
  }
}

/// Three stat cards — the month, the week, the streak — in the prototype's
/// tonnage / microcycle / exertion slots.
class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.stats});

  final TrainingStats stats;

  @override
  Widget build(BuildContext context) {
    final tokens = GimmyTokens.of(context);
    final delta = stats.monthSessions - stats.lastMonthSessions;
    final completion = stats.monthSessions == 0
        ? 0.0
        : stats.monthCompleted / stats.monthSessions;
    final weekShare = stats.weekDays / DateTime.daysPerWeek;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatCard(
              label: 'This month',
              badge: GimmyBadge(
                label: '${delta >= 0 ? '+' : ''}$delta',
                icon: delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: delta >= 0 ? null : tokens.intensityRest,
              ),
              value: '${stats.monthSessions}',
              unit: 'sessions',
              caption:
                  '${stats.monthCompleted} completed · '
                  '${stats.monthSessions - stats.monthCompleted} partial · '
                  '${stats.lastMonthSessions} last month',
              progress: completion,
            ),
          ),
          const SizedBox(width: GimmySpacing.lg),
          Expanded(
            child: _StatCard(
              label: 'This week',
              badge: GimmyBadge(
                label: '${(weekShare * 100).round()}% rate',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              value: '${stats.weekDays}',
              unit: '/ 7 days',
              caption:
                  '${DurationFormat.human(Duration(seconds: stats.weekActiveSeconds))} '
                  'active since Monday',
              progress: weekShare,
            ),
          ),
          const SizedBox(width: GimmySpacing.lg),
          Expanded(
            child: _StatCard(
              label: 'Streak',
              badge: GimmyBadge(
                label: 'Best ${stats.bestStreak}',
                color: tokens.intensityRest,
              ),
              value: '${stats.streak}',
              unit: stats.streak == 1 ? 'day' : 'days',
              caption: _streakCaption(stats),
              progress: stats.bestStreak == 0
                  ? 0
                  : stats.streak / stats.bestStreak,
              progressColor: tokens.intensityRest,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Longest run yet" means nothing on day one, when there is no other run.
String _streakCaption(TrainingStats stats) {
  if (stats.streak == 0) return 'Train today to start one';
  if (stats.streak < stats.bestStreak) {
    return '${stats.bestStreak - stats.streak} to match your best';
  }
  return stats.streak == 1 ? 'Day one' : 'Your longest run yet';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.badge,
    required this.value,
    required this.unit,
    required this.caption,
    required this.progress,
    this.progressColor,
  });

  final String label;
  final Widget badge;
  final String value;
  final String unit;
  final String caption;
  final double progress;
  final Color? progressColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: GimmyType.capsTracking,
                  ),
                ),
              ),
              Flexible(child: badge),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: tokens.metricDisplay.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: GimmySpacing.sm),
              Text(
                unit.toUpperCase(),
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          const SizedBox(height: GimmySpacing.md),
          GimmyMeter(value: progress, color: progressColor),
        ],
      ),
    );
  }
}
