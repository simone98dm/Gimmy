import 'package:flutter/material.dart';

import '../../data/models/plan.dart';
import '../theme/gimmy_tokens.dart';
import '../theme/tokens.dart';
import 'plan_step_tile.dart';

/// A plan's steps, as a lazily built sliver.
///
/// Built lazily on purpose: the sample plan expands to 54 steps, and building
/// them all in one frame is long enough to look like the app has hung at the
/// exact moment the plan appears. `SliverList` only builds what is on screen.
class SliverPlanStepList extends StatelessWidget {
  const SliverPlanStepList({super.key, required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final tokens = GimmyTokens.of(context);
    final theme = Theme.of(context);

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
      ),
      sliver: SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: GimmySpacing.md,
          vertical: GimmySpacing.sm,
        ),
        sliver: SliverList.separated(
          itemCount: plan.steps.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: tokens.cardBorder),
          itemBuilder: (context, index) =>
              PlanStepTile(position: index + 1, step: plan.steps[index]),
        ),
      ),
    );
  }
}
