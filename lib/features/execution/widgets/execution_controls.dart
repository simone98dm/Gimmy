import 'package:flutter/material.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../bloc/execution_bloc.dart';

/// −10s, the context-dependent primary action, and Skip.
///
/// Three circles, icon only, matching the prototype: two 48px secondaries
/// flanking a 64px primary.
class ExecutionControls extends StatelessWidget {
  const ExecutionControls({
    super.key,
    required this.state,
    required this.onAdjust,
    required this.onPrimary,
    required this.onSkip,
  });

  final ExecutionState state;
  final VoidCallback onAdjust;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (state.primaryAction) {
      PrimaryAction.play => (Icons.play_arrow, 'Play'),
      PrimaryAction.pause => (Icons.pause, 'Pause'),
      PrimaryAction.next => (Icons.skip_next, 'Next'),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SecondaryControl(
          icon: Icons.replay_10,
          label: 'Subtract ${AppConfig.timerAdjustmentSeconds} seconds',
          // Timer steps only, as specified.
          onPressed: state.canAdjustTimer ? onAdjust : null,
        ),
        const SizedBox(width: GimmySpacing.lg),
        _PrimaryControl(icon: icon, label: label, onPressed: onPrimary),
        const SizedBox(width: GimmySpacing.lg),
        _SecondaryControl(
          icon: Icons.skip_next,
          label: 'Skip this step',
          onPressed: onSkip,
        ),
      ],
    );
  }
}

class _PrimaryControl extends StatelessWidget {
  const _PrimaryControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: tokens.activeGlow,
          ),
          child: Material(
            color: theme.colorScheme.primaryContainer,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(
                  icon,
                  size: 34,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryControl extends StatelessWidget {
  const _SecondaryControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null;
    final color = isEnabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35);

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      excludeSemantics: true,
      child: PressableScale(
        enabled: isEnabled,
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: 24, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
