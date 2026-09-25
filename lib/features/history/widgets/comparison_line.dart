import 'package:flutter/material.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/session_comparison.dart';
import '../comparison_text.dart';

/// "vs Wed 23: +3 min active · +2 done · −4 avg BPM", quietly.
///
/// Neutral on purpose: only more steps done takes the peak colour, since that
/// is the one change that is plainly good. With [onTap] it opens the earlier
/// session.
class ComparisonLine extends StatelessWidget {
  const ComparisonLine({super.key, required this.comparison, this.onTap});

  final SessionComparison comparison;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final gain = GimmyTokens.of(context).intensityActive;
    final parts = comparisonLine(comparison).split(' · ');

    final text = Text.rich(
      TextSpan(
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const TextSpan(text: ' · '),
            TextSpan(
              text: part,
              style: comparison.doneChange > 0 && part.endsWith(' done')
                  ? TextStyle(color: gain, fontWeight: FontWeight.w600)
                  : null,
            ),
          ],
        ],
      ),
      style: muted,
    );

    return Semantics(
      label: spokenComparison(comparison),
      button: onTap != null,
      excludeSemantics: true,
      child: onTap == null
          ? text
          : InkWell(
              onTap: onTap,
              borderRadius: GimmyRadii.cell,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: GimmyLayout.minTapTarget,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: text),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
