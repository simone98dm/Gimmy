import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../data/models/plan_step.dart';
import '../../../data/models/step_record.dart';
import '../bloc/execution_bloc.dart';
import 'execution_controls.dart';
import 'step_demo_pager.dart';
import 'step_stage.dart';

/// The workout on a desktop: a progress strip across the top, then two
/// columns with no cards — the step and its controls on the left, the whole
/// plan on the right with the current step kept in view.
class DesktopRunner extends StatelessWidget {
  const DesktopRunner({super.key, required this.state});

  final ExecutionState state;

  @override
  Widget build(BuildContext context) {
    // Past the last step there is nothing to draw underneath the summary.
    final step = state.currentStep ?? state.plan.steps.last;

    return Column(
      children: [
        ProgressStrip(
          state: state,
          trailing: _Figures(state: state),
        ),
        const SizedBox(height: GimmySpacing.md),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: _Stage(state: state, step: step),
              ),
              const SizedBox(width: GimmySpacing.xl),
              Expanded(flex: 4, child: _PlanList(state: state)),
            ],
          ),
        ),
      ],
    );
  }
}

/// "5:20 active · 1 done · 1 skipped", in mono so it does not jitter.
class _Figures extends StatelessWidget {
  const _Figures({required this.state});

  final ExecutionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      '${DurationFormat.clock(Duration(seconds: state.totalActiveSeconds))} '
      'active · ${state.stepsCompleted} done · ${state.stepsSkipped} skipped',
      style: GimmyTokens.of(context).labelMono
          .copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.state, required this.step});

  final ExecutionState state;
  final PlanStep step;

  static const double _dial = 320;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ExecutionBloc>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: GimmySpacing.lg),
      child: Column(
        children: [
          StepHeading(index: state.currentIndex, step: step),
          if (step.notes case final notes?) ...[
            const SizedBox(height: GimmySpacing.sm),
            FormTipLine(key: ValueKey(state.currentIndex), notes: notes),
          ],
          const SizedBox(height: GimmySpacing.lg),
          // The demo, when there is one, beside the dial: no swipe on a
          // desktop, and room for both.
          LayoutBuilder(
            builder: (context, constraints) => StepDemoLoader(
              key: ValueKey(state.currentIndex),
              step: step,
              builder: (context, demo) {
                if (demo == null) {
                  return StepDial(state: state, step: step, diameter: _dial);
                }
                final size = ((constraints.maxWidth - GimmySpacing.lg) / 2)
                    .clamp(0.0, _dial);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StepDial(state: state, step: step, diameter: size),
                    const SizedBox(width: GimmySpacing.lg),
                    StepDemoFace(image: demo, stepName: step.name, size: size),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: GimmySpacing.lg),
          const LiveMetrics(),
          ExecutionControls(
            state: state,
            showKeyHints: true,
            onAdjust: () => bloc.add(const ExecutionTimerAdjusted()),
            onPrimary: () => bloc.add(const ExecutionPrimaryPressed()),
            onSkip: () => bloc.add(const ExecutionSkipped()),
          ),
        ],
      ),
    );
  }
}

/// Every step of the plan, marked with what happened to it, the current one
/// highlighted and scrolled into view as the workout moves on.
class _PlanList extends StatefulWidget {
  const _PlanList({required this.state});

  final ExecutionState state;

  @override
  State<_PlanList> createState() => _PlanListState();
}

class _PlanListState extends State<_PlanList> {
  final _controller = ScrollController();

  /// Fixed, so the current row's offset is arithmetic, not a measurement.
  static const double _rowExtent = 52;

  /// Rows kept above the current one, so what was just done stays in sight.
  static const int _lead = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _reveal(animate: false),
    );
  }

  @override
  void didUpdateWidget(_PlanList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentIndex != widget.state.currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
    }
  }

  void _reveal({bool animate = true}) {
    if (!mounted || !_controller.hasClients) return;
    final target = ((widget.state.currentIndex - _lead) * _rowExtent).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    if (!animate || GimmyMotion.isReduced(context)) {
      _controller.jumpTo(target);
      return;
    }
    _controller.animateTo(
      target,
      duration: GimmyMotion.stateChange,
      curve: GimmyMotion.enter,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final steps = state.plan.steps;

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.symmetric(vertical: GimmySpacing.lg),
      itemExtent: _rowExtent,
      itemCount: steps.length,
      itemBuilder: (context, i) => _PlanRow(
        number: i + 1,
        step: steps[i],
        outcome: i < state.pastOutcomes.length ? state.pastOutcomes[i] : null,
        isCurrent: i == state.currentIndex,
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.number,
    required this.step,
    required this.outcome,
    required this.isCurrent,
  });

  final int number;
  final PlanStep step;

  /// Null for the current step and everything queued after it.
  final StepOutcome? outcome;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    // Behind the user recedes; the current step leads; what is next is plain.
    final ink = isCurrent
        ? theme.colorScheme.primary
        : outcome != null
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;

    final mark = switch (outcome) {
      StepOutcome.done => Icon(
        Icons.check,
        size: 18,
        color: tokens.intensityActive,
      ),
      StepOutcome.skipped => Icon(
        Icons.redo,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      null => Text('$number', style: tokens.labelMono.copyWith(color: ink)),
    };

    final state = switch (outcome) {
      StepOutcome.done => 'done',
      StepOutcome.skipped => 'skipped',
      null => isCurrent ? 'current' : 'next',
    };

    return Semantics(
      label: 'Step $number, ${step.name}, ${stepTarget(step)}, $state',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.ms),
        decoration: BoxDecoration(
          color: isCurrent ? theme.colorScheme.surfaceContainerHigh : null,
          borderRadius: GimmyRadii.cell,
        ),
        child: Row(
          children: [
            SizedBox(
              width: GimmySpacing.lg,
              child: Center(child: mark),
            ),
            const SizedBox(width: GimmySpacing.ms),
            Expanded(
              child: Text(
                step.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(color: ink),
              ),
            ),
            const SizedBox(width: GimmySpacing.sm),
            Text(
              stepTarget(step),
              style: tokens.labelMono.copyWith(color: ink),
            ),
          ],
        ),
      ),
    );
  }
}
