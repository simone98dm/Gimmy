import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// Asks before deleting everything, as the prototype's centred alert.
///
/// Returns true only on an explicit confirmation — dismissing it keeps the
/// data.
Future<bool> confirmWipe(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);

      return AlertDialog(
        icon: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.crisis_alert,
            size: 28,
            color: theme.colorScheme.error,
          ),
        ),
        title: const Text('Wipe profile?', textAlign: TextAlign.center),
        content: const Text(
          'This deletes your plan, your whole workout history and your '
          'settings. It cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Text('Yes, wipe everything'),
                ),
              ),
              const SizedBox(height: GimmySpacing.xs),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel and keep my data'),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  return confirmed ?? false;
}
