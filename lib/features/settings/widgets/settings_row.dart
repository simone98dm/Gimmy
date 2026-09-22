import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pressable_scale.dart';

/// One row inside a [SettingsSection]: icon tile, title, subtitle, control.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.below,
    this.onTap,
    this.isDestructive = false,
    this.isComingSoon = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// The control on the right — a switch, a chevron, a badge.
  final Widget? trailing;

  /// A control too wide for the right-hand slot, placed under the row instead.
  final Widget? below;

  final VoidCallback? onTap;
  final bool isDestructive;

  /// Phase 2 and 3 features: shown, because the design shows them, but inert
  /// and labelled so they cannot be mistaken for something that works.
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleColor = switch ((isComingSoon, isDestructive)) {
      (true, _) => theme.colorScheme.onSurface.withValues(alpha: 0.5),
      (false, true) => theme.colorScheme.error,
      (false, false) => theme.colorScheme.onSurface,
    };
    final iconColor = isComingSoon
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
        : isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    final row = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDestructive && !isComingSoon
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainer,
            borderRadius: GimmyRadii.cell,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: GimmySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: isComingSoon ? 0.5 : 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: GimmySpacing.sm),
        if (isComingSoon)
          _SoonBadge()
        else if (trailing != null)
          trailing!
        else if (onTap != null)
          _ChevronButton(),
      ],
    );

    final content = below == null
        ? row
        : Column(
            children: [
              row,
              const SizedBox(height: GimmySpacing.sm),
              below!,
            ],
          );

    if (onTap == null || isComingSoon) return content;

    return PressableScale(
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.chevron_right,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Text(
        'SOON',
        style: tokens.labelMono.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
