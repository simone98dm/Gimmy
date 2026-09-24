import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/plan_step_list.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/section_heading.dart';

/// The active plan: its name and the Start button on top, then every step in
/// order.
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

    const padding = EdgeInsets.symmetric(horizontal: GimmySpacing.gutter);
    final estimate = plan.estimatedDuration(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );
    // The plan's detail page, not a second copy of the Dashboard's hero card:
    // the name, what it takes, and the way in.
    final intro = [
      const SizedBox(height: GimmySpacing.md),
      SectionHeading(
        title: plan.name,
        subtitle:
            '${plan.stepCount} steps · about ${DurationFormat.human(estimate)}',
      ),
      const SizedBox(height: GimmySpacing.md),
      GimmyCta(
        label: 'START WORKOUT',
        icon: Icons.play_arrow,
        onPressed: onStartWorkout,
      ),
      const SizedBox(height: GimmySpacing.lg),
    ];
    final steps = [
      SliverPadding(
        padding: padding,
        sliver: SliverList.list(
          children: [
            _StepsLabel(count: plan.stepCount),
            const SizedBox(height: GimmySpacing.sm),
          ],
        ),
      ),
      SliverPadding(
        padding: padding,
        sliver: SliverPlanStepList(plan: plan),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: GimmySpacing.lg)),
    ];

    final page = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverList.list(children: intro),
        ),
        ...steps,
      ],
    );

    // One centred column on a desktop: the heading is short, and beside the
    // list it left most of a column empty.
    if (!isDesktopLayout(context)) return page;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: GimmyLayout.readingWidth),
        child: page,
      ),
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
              'Import a Garmin .fit workout to get started.',
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
