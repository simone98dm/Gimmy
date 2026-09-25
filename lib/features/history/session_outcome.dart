import 'package:flutter/material.dart';

import '../../core/theme/gimmy_tokens.dart';
import '../../data/models/workout_session.dart';

/// How a session ended, in words and in the functional accent, the same
/// everywhere a session is listed.
///
/// "Ended early", not "abandoned": the history is a record, not a verdict.
({String label, Color color}) sessionOutcome(
  BuildContext context,
  SessionStatus? status,
) {
  final tokens = GimmyTokens.of(context);
  return switch (status) {
    SessionStatus.completed => (
      label: 'Completed',
      color: tokens.intensityActive,
    ),
    SessionStatus.abandoned => (
      label: 'Ended early',
      color: tokens.intensityRest,
    ),
    null => (
      label: 'In progress',
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  };
}
