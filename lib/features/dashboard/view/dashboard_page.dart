import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../core/widgets/start_workout_banner.dart';
import '../widgets/day_sessions_sheet.dart';
import '../widgets/recent_logs.dart';
import '../widgets/session_calendar.dart';
import '../widgets/streak_pill.dart';
import '../widgets/theme_toggle_button.dart';

/// Streak, the active plan, the month calendar, and the last few sessions.
///
/// Ordered as the prototype has it: the streak pill sits at the very top with
/// no page heading above it, because the workout you are about to do is the
/// point of the screen.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, this.onStartWorkout, this.onImport});

  final VoidCallback? onStartWorkout;

  /// Opens the Import page when there is no plan to show.
  final VoidCallback? onImport;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppBloc>().state;
    final now = DateTime.now();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: GimmySpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: StreakPill(streak: state.streakOn(now))),
              const SizedBox(width: GimmySpacing.xs),
              const ThemeToggleButton(),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          if (state.plan case final plan?)
            StartWorkoutBanner(plan: plan, onStart: onStartWorkout)
          else
            _NoPlanCard(onImport: onImport),
          const SizedBox(height: GimmySpacing.md),
          SessionCalendar(
            sessions: state.sessions,
            today: now,
            onDaySelected: (day, sessions) =>
                showDaySessionsSheet(context, day: day, sessions: sessions),
          ),
          const SizedBox(height: GimmySpacing.md),
          RecentLogs(
            sessions: state.sessions,
            now: now,
            onSelected: (session) => showDaySessionsSheet(
              context,
              day: session.localDay,
              sessions: state.sessions
                  .where((s) => s.localDay == session.localDay)
                  .toList(),
            ),
          ),
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
