import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final iconColor = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    final row = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDestructive
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
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: GimmySpacing.sm),
        if (trailing != null)
          trailing!
        else if (onTap != null)
          _ChevronButton(),
      ],
    );

    final content = below == null
        ? ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: GimmyLayout.minTapTarget,
            ),
            child: row,
          )
        : Column(
            children: [
              row,
              const SizedBox(height: GimmySpacing.sm),
              below!,
            ],
          );

    if (onTap == null) return content;

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
