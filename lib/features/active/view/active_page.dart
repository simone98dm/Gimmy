import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/plan_step_list.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/start_workout_banner.dart';

/// The active plan: the start banner on top, then every step in order.
///
/// The step list is the same `SliverPlanStepList` the import preview uses, so a
/// plan reads identically before and after it is saved.
class ActivePage extends StatelessWidget {
  const ActivePage({super.key, this.onStartWorkout, this.onImport});

  final VoidCallback? onStartWorkout;
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    // Only the plan: a settings or session change must not rebuild this list.
    final plan = context.select((AppBloc bloc) => bloc.state.plan);

    if (plan == null) {
      return _NoPlan(onImport: onImport);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: GimmySpacing.md),
              const SectionHeading(
                eyebrow: 'Ready when you are',
                title: 'Active Workout',
              ),
              const SizedBox(height: GimmySpacing.lg),
              StartWorkoutBanner(plan: plan, onStart: onStartWorkout),
              const SizedBox(height: GimmySpacing.lg),
              _StepsLabel(count: plan.stepCount),
              const SizedBox(height: GimmySpacing.sm),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
          sliver: SliverPlanStepList(plan: plan),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: GimmySpacing.lg)),
      ],
    );
  }
}

class _StepsLabel extends StatelessWidget {
  const _StepsLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '$count STEPS',
      style: GimmyTokens.of(context).labelMono.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _NoPlan extends StatelessWidget {
  const _NoPlan({required this.onImport});

  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GimmySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: GimmySpacing.md),
            Text('No active plan', style: theme.textTheme.headlineSmall),
            const SizedBox(height: GimmySpacing.xs),
            Text(
              'Import a Garmin .fit workout from Settings to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: GimmySpacing.md),
            GimmyCta(
              label: 'Import a workout plan',
              icon: Icons.upload_file,
              onPressed: onImport,
            ),
          ],
        ),
      ),
    );
  }
}
