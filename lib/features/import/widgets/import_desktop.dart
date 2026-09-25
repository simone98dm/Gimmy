import 'package:flutter/material.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/gimmy_badge.dart';
import '../../../core/widgets/gimmy_card.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/plan.dart';
import '../../../data/models/plan_step.dart';

/// The pieces of the Stitch desktop import screen that the phone layout does
/// not have. Each states something the parser or the storage really does.

/// The page title and what it takes.
class ImportDesktopHeader extends StatelessWidget {
  const ImportDesktopHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Import a workout', style: theme.textTheme.displaySmall),
        const SizedBox(height: GimmySpacing.xs),
        Text(
          'Garmin-compatible .fit workout files, as exported from '
          'Garmin Connect.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The parsed file: its name, what it holds, and the way to pick another.
class ParsedFileCard extends StatelessWidget {
  const ParsedFileCard({
    super.key,
    required this.plan,
    required this.filename,
    required this.onChangeFile,
  });

  final Plan plan;
  final String? filename;

  /// Null while a file is being read.
  final VoidCallback? onChangeFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estimate = plan.estimatedDuration(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );

    return GimmyCard(
      padding: const EdgeInsets.all(GimmySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: GimmyRadii.cell,
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: GimmySpacing.ms),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename ?? plan.sourceFilename,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      plan.name,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChangeFile,
                child: const Text('Change file'),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.lg),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Est. duration',
                  value: DurationFormat.human(estimate),
                ),
              ),
              Expanded(
                child: StatTile(label: 'Steps', value: '${plan.stepCount}'),
              ),
              Expanded(
                child: StatTile(
                  label: 'Exercises',
                  value: '${plan.exerciseNames.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Where the plan's time goes, by intensity — in the prototype's
/// load-calibration slot.
class IntensityMixCard extends StatelessWidget {
  const IntensityMixCard({super.key, required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final seconds = plan.secondsByIntensity(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );
    final total = seconds.values.fold(0, (a, b) => a + b);

    return GimmyCard(
      padding: const EdgeInsets.all(GimmySpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DesktopCardHeader(
            icon: Icons.auto_graph,
            title: 'Intensity mix',
            caption: 'Estimated time per intensity',
          ),
          for (final intensity in StepIntensity.values)
            if (seconds[intensity]! > 0) ...[
              const SizedBox(height: GimmySpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intensity.name.toUpperCase(),
                      style: tokens.labelMono.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Text(
                    DurationFormat.human(
                      Duration(seconds: seconds[intensity]!),
                    ),
                    style: tokens.labelMono.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GimmySpacing.xs),
              GimmyMeter(
                value: total == 0 ? 0 : seconds[intensity]! / total,
                color: intensityColor(context, intensity),
                height: 6,
              ),
            ],
        ],
      ),
    );
  }
}

/// Above the step list: the plan's name and what was parsed out of it.
class ParsedPlanHeader extends StatelessWidget {
  const ParsedPlanHeader({super.key, required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final estimate = plan.estimatedDuration(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(plan.name, style: theme.textTheme.headlineMedium),
              Text(
                '${plan.stepCount} steps · '
                        '${plan.exerciseNames.length} exercises parsed'
                    .toUpperCase(),
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        GimmyBadge(
          label: 'Est. ${DurationFormat.human(estimate)}',
          icon: Icons.schedule,
        ),
      ],
    );
  }
}

/// Stands in for the step list until a file has been read.
class EmptyStepsCard extends StatelessWidget {
  const EmptyStepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GimmyCard(
      padding: const EdgeInsets.all(GimmySpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.format_list_numbered,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: GimmySpacing.sm),
          Text('No plan parsed yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            'Its steps will appear here, in order, before anything is saved.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// The desktop confirm bar: what is about to be saved, then Discard and Save.
class ImportDesktopConfirmBar extends StatelessWidget {
  const ImportDesktopConfirmBar({
    super.key,
    required this.plan,
    required this.isSaving,
    required this.onDiscard,
    required this.onConfirm,
  });

  final Plan plan;
  final bool isSaving;
  final VoidCallback onDiscard;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GimmySpacing.gutter,
        GimmySpacing.sm,
        GimmySpacing.gutter,
        GimmySpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(GimmySpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: GimmyRadii.card,
          border: Border.all(color: tokens.cardBorder),
          boxShadow: tokens.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: GimmyRadii.cell,
              ),
              child: Icon(Icons.verified, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: GimmySpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to save as your active plan',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '${plan.exerciseNames.length} exercises · '
                    '${plan.stepCount} steps staged',
                    style: tokens.labelMono.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: isSaving ? null : onDiscard,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, GimmyLayout.ctaHeight),
              ),
              child: const Text('Discard'),
            ),
            const SizedBox(width: GimmySpacing.sm),
            SizedBox(
              width: 300,
              child: isSaving
                  ? const GimmyCta.busy(label: 'Saving…')
                  : GimmyCta(
                      label: 'Confirm & Save Plan',
                      icon: Icons.task_alt,
                      onPressed: onConfirm,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
