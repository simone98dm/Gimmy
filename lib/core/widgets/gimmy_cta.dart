import 'package:flutter/material.dart';

import 'pressable_scale.dart';

/// The app's primary call to action.
///
/// A themed `FilledButton` that also answers to the finger with the design
/// system's press-scale. Exists so every CTA in the app behaves identically
/// without each call site remembering to wrap itself.
class GimmyCta extends StatelessWidget {
  const GimmyCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;

  /// Null disables the button, and with it the press animation.
  final VoidCallback? onPressed;

  /// A CTA whose leading slot shows progress rather than an icon.
  const GimmyCta.busy({super.key, required this.label})
    : icon = null,
      onPressed = null;

  @override
  Widget build(BuildContext context) {
    final leading = icon == null
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon, size: 20);

    return PressableScale(
      enabled: onPressed != null,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: leading,
        label: Text(label),
      ),
    );
  }
}
