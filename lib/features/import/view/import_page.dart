import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/gimmy_card.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/plan.dart';
import '../../../data/sample_plan.dart';
import '../../../core/widgets/plan_step_list.dart';
import '../bloc/import_bloc.dart';
import '../widgets/exercise_demos_card.dart';
import '../widgets/import_desktop.dart';

/// Picks a Garmin `.fit` workout file, shows what is in it, and saves it as the
/// active plan once the user confirms.
class ImportPage extends StatelessWidget {
  const ImportPage({super.key, this.onImported, this.offerSample = false});

  /// Called after a plan is saved, so the host can move to the Dashboard.
  final VoidCallback? onImported;

  /// Offer the built-in sample workout. Only when there is no plan yet: from
  /// Settings it would let a real plan be swapped for a demo by accident.
  final bool offerSample;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportBloc, ImportState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == ImportStatus.saved) onImported?.call();
      },
      builder: (context, state) =>
          _ImportView(state: state, offerSample: offerSample),
    );
  }
}

class _ImportView extends StatelessWidget {
  const _ImportView({required this.state, required this.offerSample});

  final ImportState state;
  final bool offerSample;

  @override
  Widget build(BuildContext context) {
    final plan = state.plan;

    if (isDesktopLayout(context)) return _desktopView(context, plan);

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(slivers: [..._intro(plan), ..._steps(plan)]),
        ),
        // Pinned rather than trailing the step list: with the sample plan that
        // list is 54 rows long, and the action that ends the flow should not be
        // buried under all of it.
        if (plan != null) _ConfirmBar(state: state),
      ],
    );
  }

  /// The Stitch desktop layout: a full-width title, then the picker, the
  /// parsed file and its intensity mix on the left and the steps on the
  /// right, each scrolling on its own, over a confirm bar.
  Widget _desktopView(BuildContext context, Plan? plan) {
    final bloc = context.read<ImportBloc>();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(
            GimmySpacing.gutter,
            GimmySpacing.md,
            GimmySpacing.gutter,
            GimmySpacing.lg,
          ),
          child: ImportDesktopHeader(),
        ),
        Expanded(
          child: DesktopColumns(
            startFlex: 5,
            endFlex: 7,
            start: ListView(
              padding: _padding,
              children: [
                if (plan == null) ...[
                  _DropZone(isBusy: state.isBusy),
                  if (offerSample) _SampleOffer(isBusy: state.isBusy),
                  const SizedBox(height: GimmySpacing.sm),
                  const _FileHelp(),
                ],
                if (state.status == ImportStatus.failure) ...[
                  const SizedBox(height: GimmySpacing.md),
                  _ImportError(
                    message: state.errorMessage!,
                    filename: state.filename,
                  ),
                ],
                if (plan != null) ...[
                  ParsedFileCard(
                    plan: plan,
                    filename: state.filename,
                    onChangeFile: state.isBusy
                        ? null
                        : () => bloc.add(const ImportFileRequested()),
                  ),
                  const SizedBox(height: GimmySpacing.lg),
                  IntensityMixCard(plan: plan),
                  const SizedBox(height: GimmySpacing.lg),
                  ExerciseDemosCard(
                    plan: plan,
                    enabled: state.status == ImportStatus.preview,
                  ),
                ],
                const SizedBox(height: GimmySpacing.lg),
              ],
            ),
            end: CustomScrollView(
              slivers: [
                if (plan == null)
                  const SliverPadding(
                    padding: _padding,
                    sliver: SliverToBoxAdapter(child: EmptyStepsCard()),
                  )
                else ...[
                  SliverPadding(
                    padding: _padding,
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: GimmySpacing.md),
                        child: ParsedPlanHeader(plan: plan),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: _padding,
                    sliver: SliverPlanStepList(plan: plan),
                  ),
                ],
                const SliverToBoxAdapter(
                  child: SizedBox(height: GimmySpacing.lg),
                ),
              ],
            ),
          ),
        ),
        if (plan != null)
          ImportDesktopConfirmBar(
            plan: plan,
            isSaving: state.status == ImportStatus.saving,
            onDiscard: () => bloc.add(const ImportReset()),
            onConfirm: state.canConfirm
                ? () => bloc.add(const ImportConfirmed())
                : null,
          ),
      ],
    );
  }

  static const _padding = EdgeInsets.symmetric(horizontal: GimmySpacing.gutter);

  List<Widget> _intro(Plan? plan) => [
    SliverPadding(
      padding: _padding,
      sliver: SliverList.list(
        children: [
          const SizedBox(height: GimmySpacing.md),
          const SectionHeading(
            title: 'Import a workout',
            subtitle: 'Load a Garmin-compatible .fit workout file.',
          ),
          const SizedBox(height: GimmySpacing.lg),
          // Once a file is read, the picker shrinks to one line so the plan
          // being confirmed is what fills the screen.
          if (plan == null) ...[
            _DropZone(isBusy: state.isBusy),
            if (offerSample) _SampleOffer(isBusy: state.isBusy),
            const SizedBox(height: GimmySpacing.sm),
            const _FileHelp(),
          ] else
            _ChosenFile(filename: state.filename, isBusy: state.isBusy),
          if (state.status == ImportStatus.failure) ...[
            const SizedBox(height: GimmySpacing.md),
            _ImportError(
              message: state.errorMessage!,
              filename: state.filename,
            ),
          ],
          if (plan != null) ...[
            const SizedBox(height: GimmySpacing.md),
            _PlanSummary(plan: plan),
            const SizedBox(height: GimmySpacing.md),
            ExerciseDemosCard(
              plan: plan,
              enabled: state.status == ImportStatus.preview,
            ),
            const SizedBox(height: GimmySpacing.lg),
          ],
        ],
      ),
    ),
  ];

  List<Widget> _steps(Plan? plan) => [
    if (plan != null) ...[
      SliverPadding(
        padding: _padding,
        sliver: SliverList.list(
          children: [
            _StepsLabel(),
            const SizedBox(height: GimmySpacing.sm),
          ],
        ),
      ),
      SliverPadding(
        padding: _padding,
        sliver: SliverPlanStepList(plan: plan),
      ),
    ],
    const SliverToBoxAdapter(child: SizedBox(height: GimmySpacing.lg)),
  ];
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
        letterSpacing: GimmyType.capsTracking,
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
        ],
      ),
    );
  }
}

/// The way in for someone with no file: a secondary action under the picker,
/// because importing their own plan is still the point.
class _SampleOffer extends StatelessWidget {
  const _SampleOffer({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // Built only to be measured: the numbers come from the plan itself.
    final sample = buildSamplePlan(id: '', importedAt: DateTime(0));
    final minutes = sample
        .estimatedDuration(secondsPerRep: AppConfig.estimatedSecondsPerRep)
        .inMinutes;

    return Padding(
      padding: const EdgeInsets.only(top: GimmySpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: GimmySpacing.ms,
                ),
                child: Text('No workout file yet?', style: muted),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          OutlinedButton.icon(
            onPressed: isBusy
                ? null
                : () => context.read<ImportBloc>().add(
                    const ImportSampleRequested(),
                  ),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Try a sample workout'),
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            '$minutes min · ${sample.stepCount} steps · '
            'replaced when you import your own',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// The picked file, once parsed, with the way to pick another.
class _ChosenFile extends StatelessWidget {
  const _ChosenFile({required this.filename, required this.isBusy});

  final String? filename;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(Icons.description_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: GimmySpacing.sm),
        Expanded(
          child: Text(
            filename ?? 'Workout file',
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        TextButton(
          onPressed: isBusy
              ? null
              : () =>
                    context.read<ImportBloc>().add(const ImportFileRequested()),
          child: const Text('Change file'),
        ),
      ],
    );
  }
}

/// Where a .fit workout comes from — the one thing a first-timer cannot guess.
class _FileHelp extends StatelessWidget {
  const _FileHelp();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Theme(
      // ExpansionTile draws dividers above and below by default.
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        // Open on first run, when there is no way out but to import: that is
        // exactly when someone has not got a file yet.
        initiallyExpanded:
            ModalRoute.of(context)?.popDisposition ==
            RoutePopDisposition.doNotPop,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: GimmySpacing.sm),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(
          'How do I get a workout file?',
          style: theme.textTheme.bodyLarge,
        ),
        children: [
          Text(
            'Build the workout in Garmin Connect, then export it as a .fit '
            'file from the workout page on connect.garmin.com.',
            style: body,
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            'Or plug in your watch and copy the file from its '
            'GARMIN/Workouts folder.',
            style: body,
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            'The file is read on this device and never uploaded.',
            style: body,
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
                  const SizedBox(height: GimmySpacing.xxs),
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
  const _PlanSummary({required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final estimate = plan.estimatedDuration(
      secondsPerRep: AppConfig.estimatedSecondsPerRep,
    );

    return GimmyCard(
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
                child: Text(plan.name, style: theme.textTheme.headlineSmall),
              ),
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
