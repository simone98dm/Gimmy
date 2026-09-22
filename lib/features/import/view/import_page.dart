import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/gimmy_card.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/plan.dart';
import '../../../core/widgets/plan_step_list.dart';
import '../bloc/import_bloc.dart';

/// Picks a Garmin `.fit` workout file, shows what is in it, and saves it as the
/// active plan once the user confirms.
class ImportPage extends StatelessWidget {
  const ImportPage({super.key, this.onImported});

  /// Called after a plan is saved, so the host can move to the Dashboard.
  final VoidCallback? onImported;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportBloc, ImportState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ImportStatus.saved) onImported?.call();
      },
      builder: (context, state) => _ImportView(state: state),
    );
  }
}

class _ImportView extends StatelessWidget {
  const _ImportView({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final plan = state.plan;

    return Column(
      children: [
        Expanded(child: _scrollView(plan)),
        // Pinned rather than trailing the step list: with the sample plan that
        // list is 54 rows long, and the action that ends the flow should not be
        // buried under all of it.
        if (plan != null) _ConfirmBar(state: state),
      ],
    );
  }

  Widget _scrollView(Plan? plan) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: GimmySpacing.md),
              const SectionHeading(
                eyebrow: 'Workout ingestion',
                title: 'Import Workout',
                subtitle: 'Load a Garmin-compatible .fit workout file.',
              ),
              const SizedBox(height: GimmySpacing.lg),
              _DropZone(isBusy: state.isBusy),
              if (state.status == ImportStatus.failure) ...[
                const SizedBox(height: GimmySpacing.md),
                _ImportError(
                  message: state.errorMessage!,
                  filename: state.filename,
                ),
              ],
              if (plan != null) ...[
                const SizedBox(height: GimmySpacing.xl),
                _PlanSummary(plan: plan, filename: state.filename),
                const SizedBox(height: GimmySpacing.lg),
                _StepsLabel(),
                const SizedBox(height: GimmySpacing.sm),
              ],
            ],
          ),
        ),
        if (plan != null)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: GimmySpacing.gutter,
            ),
            sliver: SliverPlanStepList(plan: plan),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: GimmySpacing.lg)),
      ],
    );
  }
}

/// Caption above the step list.
class _StepsLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      'STEPS',
      style: GimmyTokens.of(context).labelMono.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// The file picker card. Tapping anywhere on it opens the system picker.
class _DropZone extends StatelessWidget {
  const _DropZone({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return GimmyCard(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.md,
        vertical: GimmySpacing.xl,
      ),
      onTap: isBusy
          ? null
          : () => context.read<ImportBloc>().add(const ImportFileRequested()),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: isBusy
                ? Padding(
                    padding: const EdgeInsets.all(GimmySpacing.md),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(
                    Icons.upload_file,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
          ),
          const SizedBox(height: GimmySpacing.md),
          Text(
            isBusy ? 'Reading your file' : 'Select a workout file',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            'Garmin .fit workout files only',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GimmySpacing.md),
          GimmyCta(
            label: 'Select .FIT File',
            icon: Icons.folder_open,
            onPressed: isBusy
                ? null
                : () => context.read<ImportBloc>().add(
                    const ImportFileRequested(),
                  ),
          ),
          const SizedBox(height: GimmySpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: GimmySpacing.xs),
              Flexible(
                child: Text(
                  'PARSED ON DEVICE. NOTHING UPLOADED.',
                  overflow: TextOverflow.ellipsis,
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown when a file is rejected. Nothing has been stored at this point.
class _ImportError extends StatelessWidget {
  const _ImportError({required this.message, this.filename});

  final String message;
  final String? filename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.12),
        borderRadius: GimmyRadii.card,
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
          const SizedBox(width: GimmySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COULD NOT IMPORT',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                if (filename != null) ...[
                  const SizedBox(height: 2),
                  Text(filename!, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: GimmySpacing.xs),
                Text(message, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Plan name and totals. The step list itself is a separate, lazy sliver.
class _PlanSummary extends StatelessWidget {
  const _PlanSummary({required this.plan, this.filename});

  final Plan plan;
  final String? filename;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final estimate = plan.estimatedDuration(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'PARSED PLAN',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<ImportBloc>().add(const ImportReset()),
              child: const Text('RESET'),
            ),
          ],
        ),
        const SizedBox(height: GimmySpacing.sm),
        GimmyCard(
          isHighlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.verified_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: GimmySpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: theme.textTheme.headlineSmall),
                        if (filename != null)
                          Text(
                            filename!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _ValidBadge(),
                ],
              ),
              const SizedBox(height: GimmySpacing.md),
              Divider(color: tokens.cardBorder),
              const SizedBox(height: GimmySpacing.md),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      label: 'Est. duration',
                      icon: Icons.schedule,
                      value: DurationFormat.human(estimate),
                    ),
                  ),
                  Expanded(
                    child: StatTile(
                      label: 'Steps',
                      icon: Icons.format_list_numbered,
                      value: '${plan.stepCount}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValidBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: GimmySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Text(
        'VALID',
        style: tokens.labelMono.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }
}

/// The pinned action bar under the preview.
class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final isSaving = state.status == ImportStatus.saving;

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.gutter),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: tokens.cardBorder)),
      ),
      child: isSaving
          ? const GimmyCta.busy(label: 'Saving…')
          : GimmyCta(
              label: 'Confirm & Save Plan',
              icon: Icons.task_alt,
              onPressed: state.canConfirm
                  ? () =>
                        context.read<ImportBloc>().add(const ImportConfirmed())
                  : null,
            ),
    );
  }
}
