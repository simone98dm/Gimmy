import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/gimmy_tokens.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/gimmy_badge.dart';
import '../../data/training_stats.dart';
import '../bloc/app_bloc.dart';

/// The foot of the desktop sidebar: the week so far and the streak — the
/// prototype's strain and heart-rate card, from numbers the app really has.
class SidebarStats extends StatelessWidget {
  const SidebarStats({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final sessions = context.select((AppBloc bloc) => bloc.state.sessions);
    final stats = TrainingStats.of(sessions, now: DateTime.now());

    final label = tokens.labelMono.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 1.2,
    );

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.button,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Expanded(child: Text('THIS WEEK', style: label)),
                Text(
                  '${stats.weekDays}/7 DAYS',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GimmySpacing.sm),
          // The row above already says it; the bar is its picture.
          ExcludeSemantics(
            child: GimmyMeter(value: stats.weekDays / DateTime.daysPerWeek),
          ),
          const SizedBox(height: GimmySpacing.md),
          // One announcement ("Streak 3 DAYS"), not three.
          MergeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text('Streak', style: label)),
                Text(
                  '${stats.streak}',
                  style: tokens.metricMd.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: GimmySpacing.xs),
                Text(stats.streak == 1 ? 'DAY' : 'DAYS', style: label),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
