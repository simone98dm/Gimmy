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
    this.showKeyHints = false,
  });

  final ExecutionState state;
  final VoidCallback onAdjust;
  final VoidCallback onPrimary;
  final VoidCallback onSkip;

  /// Keycaps under each control, and the key in its spoken label. Desktop
  /// only: the keyboard shortcuts live in `RunnerKeyboard`.
  final bool showKeyHints;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (state.primaryAction) {
      PrimaryAction.play => (Icons.play_arrow, 'Play'),
      PrimaryAction.pause => (Icons.pause, 'Pause'),
      // A tick, not skip-next: Skip sits beside it and must not look alike.
      PrimaryAction.next => (Icons.check, 'Done'),
    };

    String spoken(String label, String key) =>
        showKeyHints ? '$label, $key' : label;
    Widget hinted(Widget control, String key) => showKeyHints
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              control,
              const SizedBox(height: GimmySpacing.sm),
              _KeyCap(key),
            ],
          )
        : control;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hinted(
          _SecondaryControl(
            // Text, not replay_10: that icon means rewind, and this takes time
            // off the countdown.
            text: '−${AppConfig.timerAdjustmentSeconds}',
            label: spoken(
              'Subtract ${AppConfig.timerAdjustmentSeconds} seconds',
              'minus',
            ),
            // Timer steps only, as specified.
            onPressed: state.canAdjustTimer ? onAdjust : null,
          ),
          '−',
        ),
        const SizedBox(width: GimmySpacing.lg),
        hinted(
          _PrimaryControl(
            icon: icon,
            label: spoken(label, 'Space'),
            onPressed: onPrimary,
          ),
          // Says what Space does right now.
          'Space · $label',
        ),
        const SizedBox(width: GimmySpacing.lg),
        hinted(
          _SecondaryControl(
            icon: Icons.skip_next,
            label: spoken('Skip this step', 'S'),
            onPressed: onSkip,
          ),
          'S',
        ),
      ],
    );
  }
}

/// A key, drawn as a small keycap.
class _KeyCap extends StatelessWidget {
  const _KeyCap(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GimmySpacing.xs,
          vertical: GimmySpacing.xxs,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: tokens.cardBorder),
          borderRadius: BorderRadius.circular(GimmyRadii.sm),
        ),
        child: Text(
          text,
          style: tokens.labelMono.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
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
    this.icon,
    this.text,
    required this.label,
    required this.onPressed,
  }) : assert((icon == null) != (text == null), 'an icon or a text, not both');

  final IconData? icon;
  final String? text;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
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
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 24, color: color)
                    : Text(
                        text!,
                        style: tokens.metricMd.copyWith(color: color),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
