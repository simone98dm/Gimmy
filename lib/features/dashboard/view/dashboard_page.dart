import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/start_workout_banner.dart';
import '../../../data/training_stats.dart';
import '../widgets/dashboard_hero.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/day_sessions_sheet.dart';
import '../widgets/recent_logs.dart';
import '../widgets/session_calendar.dart';
import '../widgets/streak_pill.dart';

/// Streak, the active plan, the month calendar, and the last few sessions.
///
/// Ordered as the prototype has it: the streak pill sits at the very top with
/// no page heading above it, because the workout you are about to do is the
/// point of the screen. On a desktop the calendar and the logs sit side by
/// side under the hero, as the Stitch desktop dashboard has them.
class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.onStartWorkout,
    this.onImport,
    this.clock = DateTime.now,
  });

  final VoidCallback? onStartWorkout;

  /// Opens the Import page when there is no plan to show.
  final VoidCallback? onImport;

  /// Injectable so the calendar and streak can be pinned to a date in tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    // Only what this page draws: a settings change must not rebuild it.
    final plan = context.select((AppBloc bloc) => bloc.state.plan);
    final sessions = context.select((AppBloc bloc) => bloc.state.sessions);
    final now = clock();
    final stats = TrainingStats.of(sessions, now: now);

    final calendar = SessionCalendar(
      sessions: sessions,
      today: now,
      onDaySelected: (day, sessions) =>
          showDaySessionsSheet(context, day: day, sessions: sessions),
    );
    final logs = RecentLogs(
      sessions: sessions,
      now: now,
      onSelected: (session) => showDaySessionsSheet(
        context,
        day: session.localDay,
        sessions: sessions
            .where((s) => s.localDay == session.localDay)
            .toList(),
      ),
    );

    if (isDesktopLayout(context)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: GimmySpacing.md),
            DashboardStatusStrip(stats: stats, sessionCount: sessions.length),
            const SizedBox(height: GimmySpacing.lg),
            if (plan != null)
              DashboardHero(
                plan: plan,
                onStart: onStartWorkout,
                onChangePlan: onImport,
              )
            else
              _NoPlanCard(onImport: onImport),
            const SizedBox(height: GimmySpacing.lg),
            DashboardStats(stats: stats),
            const SizedBox(height: GimmySpacing.lg),
            DesktopColumns(
              startFlex: 7,
              endFlex: 5,
              start: calendar,
              end: logs,
            ),
            const SizedBox(height: GimmySpacing.xl),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: GimmySpacing.sm),
          // The theme switch lives in Settings; one place is enough.
          Align(
            alignment: Alignment.centerLeft,
            child: StreakPill(streak: stats.streak, best: stats.bestStreak),
          ),
          const SizedBox(height: GimmySpacing.md),
          if (plan != null)
            StartWorkoutBanner(plan: plan, onStart: onStartWorkout)
          else
            _NoPlanCard(onImport: onImport),
          const SizedBox(height: GimmySpacing.md),
          calendar,
          const SizedBox(height: GimmySpacing.md),
          logs,
          const SizedBox(height: GimmySpacing.lg),
        ],
      ),
    );
  }
}

class _NoPlanCard extends StatelessWidget {
  const _NoPlanCard({required this.onImport});

  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'No plan imported yet.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: GimmySpacing.sm),
        GimmyCta(
          label: 'Import a workout plan',
          icon: Icons.upload_file,
          onPressed: onImport,
        ),
      ],
    );
  }
}
