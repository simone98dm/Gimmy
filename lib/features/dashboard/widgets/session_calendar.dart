import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/models/workout_session.dart';

/// A month of day cells, with a marker on every day that has a session.
///
/// Shows one month at a time and navigates backwards through history. Forward
/// navigation stops at the current month — there is nothing to see in the
/// future.
class SessionCalendar extends StatefulWidget {
  const SessionCalendar({
    super.key,
    required this.sessions,
    required this.today,
    required this.onDaySelected,
  });

  final List<WorkoutSession> sessions;

  /// Injected rather than read from the clock so the widget is testable.
  final DateTime today;

  /// Called with the day and its sessions when a marked day is tapped.
  final void Function(DateTime day, List<WorkoutSession> sessions)
  onDaySelected;

  @override
  State<SessionCalendar> createState() => _SessionCalendarState();
}

class _SessionCalendarState extends State<SessionCalendar> {
  late DateTime _visibleMonth = _monthOf(widget.today);

  static DateTime _monthOf(DateTime day) => DateTime(day.year, day.month);

  /// Sessions grouped by the local day they started on.
  Map<DateTime, List<WorkoutSession>> get _byDay {
    final grouped = <DateTime, List<WorkoutSession>>{};
    for (final session in widget.sessions) {
      grouped.putIfAbsent(session.localDay, () => []).add(session);
    }
    return grouped;
  }

  bool get _canGoForward => _visibleMonth.isBefore(_monthOf(widget.today));

  void _shiftMonth(int months) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + months,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final byDay = _byDay;

    final monthSessionCount = byDay.entries
        .where(
          (e) =>
              e.key.year == _visibleMonth.year &&
              e.key.month == _visibleMonth.month,
        )
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: GimmySpacing.sm),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(_visibleMonth),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              _MonthButton(
                icon: Icons.chevron_left,
                semanticLabel: 'Previous month',
                onPressed: () => _shiftMonth(-1),
              ),
              const SizedBox(width: GimmySpacing.xs),
              _MonthButton(
                icon: Icons.chevron_right,
                semanticLabel: 'Next month',
                onPressed: _canGoForward ? () => _shiftMonth(1) : null,
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),
          _WeekdayHeader(),
          const SizedBox(height: GimmySpacing.xs),
          _MonthGrid(
            month: _visibleMonth,
            today: widget.today,
            byDay: byDay,
            onDaySelected: widget.onDaySelected,
          ),
          const SizedBox(height: GimmySpacing.md),
          _MonthSummary(
            activeDays: monthSessionCount,
            sessions: _monthSessionTotal(byDay),
          ),
        ],
      ),
    );
  }

  /// Sessions recorded in the visible month, which can exceed the number of
  /// days if more than one workout was started on the same day.
  int _monthSessionTotal(Map<DateTime, List<WorkoutSession>> byDay) {
    var total = 0;
    for (final entry in byDay.entries) {
      if (entry.key.year == _visibleMonth.year &&
          entry.key.month == _visibleMonth.month) {
        total += entry.value.length;
      }
    }
    return total;
  }
}

/// The line under the grid: what the month adds up to, as one sentence.
///
/// Workouts and days are different counts — two sessions can share a day — so
/// the days are only mentioned when they differ, rather than sitting beside
/// the workouts as a second number that looks like the same fact.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.activeDays, required this.sessions});

  final int activeDays;
  final int sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final workouts = sessions == 1 ? '1 workout' : '$sessions workouts';
    final days = activeDays == 1 ? '1 day' : '$activeDays days';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GimmySpacing.ms),
      decoration: BoxDecoration(
        color: GimmyTokens.of(context).insetSurface,
        borderRadius: GimmyRadii.card,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: workouts,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: sessions == activeDays
                  ? ' this month'
                  : ' on $days this month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        style: theme.textTheme.bodySmall,
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 20,
      tooltip: semanticLabel,
      constraints: const BoxConstraints(
        minWidth: GimmyLayout.minTapTarget,
        minHeight: GimmyLayout.minTapTarget,
      ),
      style: IconButton.styleFrom(
        foregroundColor: theme.colorScheme.onSurface,
        disabledForegroundColor: theme.colorScheme.onSurfaceVariant.withValues(
          alpha: 0.4,
        ),
        shape: const RoundedRectangleBorder(borderRadius: GimmyRadii.cell),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    // Monday-first, matching the design's "M T W T F S S" row.
    final labels = DateFormat.E().dateSymbols.NARROWWEEKDAYS;
    final mondayFirst = [...labels.sublist(1), labels.first];

    return Row(
      children: [
        for (final label in mondayFirst)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.byDay,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime today;
  final Map<DateTime, List<WorkoutSession>> byDay;
  final void Function(DateTime day, List<WorkoutSession> sessions)
  onDaySelected;

  @override
  Widget build(BuildContext context) {
    // DateTime.weekday is 1 (Mon) to 7 (Sun), so this is the count of blank
    // cells before the 1st in a Monday-first grid.
    final leadingBlanks = DateTime(month.year, month.month).weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cellCount = leadingBlanks + daysInMonth;
    final rows = (cellCount / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(child: _cellAt(row * 7 + column - leadingBlanks)),
            ],
          ),
      ],
    );
  }

  Widget _cellAt(int dayNumber) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // Days either side of the visible month still get drawn, muted, so the
    // grid reads as a continuous calendar rather than one with holes in it.
    if (dayNumber < 0) {
      final previous = DateTime(month.year, month.month, 0).day;
      return _AdjacentDayCell(day: previous + dayNumber + 1);
    }
    if (dayNumber >= daysInMonth) {
      return _AdjacentDayCell(day: dayNumber - daysInMonth + 1);
    }

    final day = DateTime(month.year, month.month, dayNumber + 1);
    final sessions = byDay[day] ?? const <WorkoutSession>[];

    final todayDate = DateTime(today.year, today.month, today.day);

    return _DayCell(
      day: day,
      isToday: day == todayDate,
      sessions: sessions,
      onTap: sessions.isEmpty ? null : () => onDaySelected(day, sessions),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.sessions,
    required this.onTap,
  });

  /// Tall enough to be a comfortable tap target, not just a dot.
  static const double _cellHeight = GimmyLayout.minTapTarget;
  static const double _dotSize = 34;

  final DateTime day;
  final bool isToday;
  final List<WorkoutSession> sessions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final hasSessions = sessions.isNotEmpty;

    // The fill says what happened; today is a ring on top of that, so it never
    // gets mistaken for a session day.
    // Only sessions get a fill. Missed and future days are both bare, so a
    // month of absences does not outweigh the days that were trained.
    final (background, foreground) = hasSessions
        ? (
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
          )
        : (Colors.transparent, theme.colorScheme.onSurfaceVariant);
    final workouts = hasSessions
        ? '${sessions.length} workout${sessions.length == 1 ? '' : 's'}'
        : 'no workout';

    return Semantics(
      button: hasSessions,
      label: '${isToday ? 'Today, ' : ''}${day.day}, $workouts',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: _cellHeight,
            child: Center(
              child: Container(
                width: _dotSize,
                height: _dotSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: theme.colorScheme.primary, width: 2)
                      : null,
                ),
                child: Text(
                  '${day.day}',
                  // Numbers, not caps: no tracking, or two digits sit
                  // off-centre in the dot.
                  style: tokens.labelMono.copyWith(
                    letterSpacing: 0,
                    color: foreground,
                    fontWeight: hasSessions || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A day belonging to the month either side of the one on screen.
///
/// Drawn as a bare muted number rather than a circle, so the visible month
/// reads as a block without the grid looking ragged.
class _AdjacentDayCell extends StatelessWidget {
  const _AdjacentDayCell({required this.day});

  final int day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return SizedBox(
      height: _DayCell._cellHeight,
      child: Center(
        child: Text(
          '$day',
          style: tokens.labelMono.copyWith(
            letterSpacing: 0,
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
