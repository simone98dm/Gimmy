import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/util/duration_format.dart';
import '../../../core/widgets/app_sidebar.dart';
import '../../../core/widgets/gimmy_badge.dart';
import '../../../core/widgets/gimmy_page_route.dart';
import '../../../core/widgets/gimmy_scaffold.dart';
import '../../../data/models/workout_session.dart';
import '../../../data/session_comparison.dart';
import '../session_outcome.dart';
import '../widgets/comparison_line.dart';
import '../widgets/step_record_row.dart';

/// One past session, replayed step by step.
///
/// View-only: history is a record. Sessions from before step records existed
/// show their totals and say plainly that the steps were not kept.
class SessionDetailPage extends StatelessWidget {
  const SessionDetailPage({
    super.key,
    required this.session,
    this.history = const [],
  });

  final WorkoutSession session;

  /// Every stored session, to find the last run of this plan to compare with.
  final List<WorkoutSession> history;

  static Route<void> route(
    WorkoutSession session, {
    List<WorkoutSession> history = const [],
  }) => GimmyPageRoute<void>(
    settings: const RouteSettings(name: 'session'),
    builder: (_) => SessionDetailPage(session: session, history: history),
  );

  SessionComparison? get _comparison {
    final previous = previousRun(history, session);
    return previous == null ? null : SessionComparison.of(session, previous);
  }

  @override
  Widget build(BuildContext context) {
    return GimmyScaffold(
      label: 'Session',
      sidebarItem: SidebarItem.dashboard,
      leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: GimmyLayout.readingWidth),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  GimmySpacing.gutter,
                  GimmySpacing.lg,
                  GimmySpacing.gutter,
                  GimmySpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: _Summary(
                    session: session,
                    comparison: _comparison,
                    // The earlier session opens with the same history, so
                    // it compares with the one before it in turn.
                    onOpenPrevious: (previous) =>
                        Navigator.of(context)
                            .push(route(previous, history: history)),
                  ),
                ),
              ),
              ..._steps(context),
              const SliverToBoxAdapter(
                child: SizedBox(height: GimmySpacing.xl),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _steps(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: GimmySpacing.gutter);

    if (!session.hasStepRecords) {
      return [
        const SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: _Note(
              "Step detail isn't available for sessions before this update.",
            ),
          ),
        ),
      ];
    }

    final notReached = session.stepsNotReached;
    return [
      if (session.steps.isEmpty)
        const SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(child: _Note('No steps reached.')),
        )
      else
        SliverPadding(
          padding: padding,
          // Built lazily: a plan can run to fifty-odd steps.
          sliver: SliverList.separated(
            itemCount: session.steps.length,
            itemBuilder: (context, i) => StepRecordRow(
              number: i + 1,
              record: session.steps[i],
              change: _comparison?.step(i),
            ),
            separatorBuilder: (context, _) =>
                Divider(color: GimmyTokens.of(context).cardBorder),
          ),
        ),
      if (notReached > 0 && session.steps.isNotEmpty)
        SliverPadding(
          padding: padding.copyWith(top: GimmySpacing.md),
          sliver: SliverToBoxAdapter(
            child: _Note(
              notReached == 1
                  ? '1 step not reached'
                  : '$notReached steps not reached',
            ),
          ),
        ),
    ];
  }
}

/// Plan, when, how it ended, and one line of totals.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.session,
    required this.comparison,
    required this.onOpenPrevious,
  });

  final WorkoutSession session;
  final SessionComparison? comparison;
  final ValueChanged<WorkoutSession> onOpenPrevious;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outcome = sessionOutcome(context, session.status);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GimmyBadge(label: outcome.label, color: outcome.color),
        const SizedBox(height: GimmySpacing.sm),
        Text(session.planName, style: theme.textTheme.headlineLarge),
        const SizedBox(height: GimmySpacing.xs),
        Text(
          DateFormat.yMMMMEEEEd().add_Hm().format(session.startedAt),
          style: muted,
        ),
        const SizedBox(height: GimmySpacing.md),
        Text(_totals(session), style: theme.textTheme.bodyLarge),
        if (comparison case final comparison?) ...[
          const SizedBox(height: GimmySpacing.xs),
          ComparisonLine(
            comparison: comparison,
            onTap: () => onOpenPrevious(comparison.previous),
          ),
        ],
      ],
    );
  }

  /// "38 min active · 18 of 22 done · 2 skipped · 132 avg / 171 max BPM"
  static String _totals(WorkoutSession session) {
    final active = DurationFormat.human(
      Duration(seconds: session.totalActiveSeconds),
    );
    final done = session.hasStepRecords
        ? '${session.stepsCompleted} of ${session.plannedSteps} done'
        : '${session.stepsCompleted} done';
    return [
          '$active active',
          done,
          if (session.stepsSkipped > 0) '${session.stepsSkipped} skipped',
          if (session.averageBpm case final avg?)
            '$avg avg / ${session.maxBpm} max BPM',
        ]
        // Non-breaking inside each figure: a line may only wrap between them.
        .map((figure) => figure.replaceAll(' ', '\u00A0'))
        .join(' · ');
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
