import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/plan_step_tile.dart';
import '../../../data/models/plan_step.dart';
import '../bloc/execution_bloc.dart';
import 'execution_controls.dart';
import 'step_demo_pager.dart';
import 'step_stage.dart';

/// The workout on a phone: a progress strip, the step on the page itself, and
/// the controls pinned in a bar at the bottom where a thumb finds them.
///
/// Nothing above the bar can push the controls away or cover them. The bar
/// is the bottom slot of its own [Scaffold], under its own messenger
/// ([messengerKey]), so the undo snackbar floats above the bar, not over it.
class PhoneRunner extends StatelessWidget {
  const PhoneRunner({
    super.key,
    required this.state,
    required this.messengerKey,
  });

  final ExecutionState state;
  final GlobalKey<ScaffoldMessengerState> messengerKey;

  @override
  Widget build(BuildContext context) {
    // Past the last step there is nothing to draw underneath the summary.
    final step = state.currentStep ?? state.plan.steps.last;

    return ScaffoldMessenger(
      key: messengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            ProgressStrip(state: state),
            Expanded(
              child: _Stage(state: state, step: step),
            ),
          ],
        ),
        bottomNavigationBar: _ControlBar(state: state),
      ),
    );
  }
}

/// The current step, straight on the page: heading, form tip, dial, metrics.
///
/// The dial takes the height the rest leaves, between [_minDial] and
/// [_maxDial]. When even the smallest dial does not fit (a short phone, large
/// text, an open form tip), this area scrolls — the control bar never moves.
class _Stage extends StatelessWidget {
  const _Stage({required this.state, required this.step});

  final ExecutionState state;
  final PlanStep step;

  static const double _minDial = 200;
  static const double _maxDial = 320;

  /// The height of everything above and below the dial except the text,
  /// which is measured through the text scaler.
  double _reserved(BuildContext context, {required bool hasMetrics}) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    double line(TextStyle? style) {
      final size = style?.fontSize ?? 14;
      return scaler.scale(size) * (style?.height ?? 1.2);
    }

    return GimmySpacing.lg + // top
        line(theme.textTheme.headlineLarge) +
        GimmySpacing.xs +
        line(theme.textTheme.bodyMedium) +
        (step.notes != null ? GimmySpacing.sm + GimmyLayout.minTapTarget : 0) +
        GimmySpacing.lg + // above the dial
        GimmySpacing.lg + // below the dial
        (step.exerciseId != null ? StepDemoPager.dotsHeight : 0) +
        (hasMetrics ? line(GimmyTokens.of(context).metricLg) * 2 + 32 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final hasMetrics = LiveMetrics.isShown(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final fit =
            constraints.maxHeight - _reserved(context, hasMetrics: hasMetrics);
        final diameter = [
          fit,
          constraints.maxWidth - 2 * GimmySpacing.gutter,
          _maxDial,
        ].reduce((a, b) => a < b ? a : b).clamp(_minDial, _maxDial);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            GimmySpacing.gutter,
            GimmySpacing.lg,
            GimmySpacing.gutter,
            GimmySpacing.lg,
          ),
          // At least the full height, so on a tall phone the dial sits in the
          // middle of what is left rather than leaving a gap above the bar.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 2 * GimmySpacing.lg,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  StepHeading(index: state.currentIndex, step: step),
                  if (step.notes case final notes?) ...[
                    const SizedBox(height: GimmySpacing.sm),
                    // Keyed by step, so a tip opened on one step starts
                    // closed on the next.
                    FormTipLine(
                      key: ValueKey(state.currentIndex),
                      notes: notes,
                    ),
                  ],
                  const SizedBox(height: GimmySpacing.lg),
                  Expanded(
                    child: Center(
                      // Keyed by step, so each one opens on its dial.
                      child: StepDemoPager(
                        key: ValueKey(state.currentIndex),
                        state: state,
                        step: step,
                        diameter: diameter,
                      ),
                    ),
                  ),
                  const SizedBox(height: GimmySpacing.lg),
                  const LiveMetrics(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What is next, and the three controls, fixed above the home indicator.
class _ControlBar extends StatelessWidget {
  const _ControlBar({required this.state});

  final ExecutionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final bloc = context.read<ExecutionBloc>();
    final next = state.nextStep;
    final strong = TextStyle(
      color: theme.colorScheme.onSurface,
      fontWeight: FontWeight.w700,
    );

    return DecoratedBox(
      key: const ValueKey('runner-control-bar'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: tokens.chromeShadowColor,
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        // The bar's surface runs to the screen edge; its controls stop above
        // the home indicator.
        padding: EdgeInsets.fromLTRB(
          GimmySpacing.gutter,
          GimmySpacing.md,
          GimmySpacing.gutter,
          GimmySpacing.md + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Read from the floor between sets: the next step's name at title
            // size, the rest of the line quieter, and clear air above the
            // buttons so the eye doesn't take it for a label on them.
            Text.rich(
              TextSpan(
                children: next == null
                    ? [TextSpan(text: 'Last step', style: strong)]
                    : [
                        const TextSpan(text: 'Next · '),
                        TextSpan(text: next.name, style: strong),
                        TextSpan(text: ' · ${stepTarget(next)}'),
                      ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: GimmySpacing.lg),
            ExecutionControls(
              state: state,
              onAdjust: () => bloc.add(const ExecutionTimerAdjusted()),
              onPrimary: () => bloc.add(const ExecutionPrimaryPressed()),
              onSkip: () => bloc.add(const ExecutionSkipped()),
            ),
          ],
        ),
      ),
    );
  }
}
