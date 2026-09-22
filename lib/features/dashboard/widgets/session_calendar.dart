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

/// The strip under the grid: what the month adds up to.
class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.activeDays, required this.sessions});

  final int activeDays;
  final int sessions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.sm + 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: GimmySpacing.sm),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: sessions == 1
                              ? '1 workout '
                              : '$sessions workouts ',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: 'this month',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: GimmySpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: GimmySpacing.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: GimmyRadii.cell,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeDays == 1 ? '1 ACTIVE DAY' : '$activeDays ACTIVE DAYS',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: GimmySpacing.xs),
                Icon(Icons.bolt, size: 14, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ],
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
      iconSize: 16,
      tooltip: semanticLabel,
      constraints: const BoxConstraints(
        minWidth: GimmyLayout.minTapTarget,
        minHeight: GimmyLayout.minTapTarget,
      ),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
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

    return _DayCell(
      day: day,
      isToday: day == DateTime(today.year, today.month, today.day),
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

  final DateTime day;
  final bool isToday;
  final List<WorkoutSession> sessions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final hasSessions = sessions.isNotEmpty;

    // Today outranks everything: it is the one cell you look for.
    final (background, foreground) = switch ((isToday, hasSessions)) {
      (true, _) => (theme.colorScheme.primary, theme.colorScheme.onPrimary),
      (false, true) => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      (false, false) => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Semantics(
      button: hasSessions,
      label: hasSessions
          ? '${day.day}, ${sessions.length} workout'
                '${sessions.length == 1 ? '' : 's'}'
          : '${day.day}, no workout',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            height: 36,
            child: Center(
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${day.day}',
                  style: tokens.labelMono.copyWith(
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
      height: 36,
      child: Center(
        child: Text(
          '$day',
          style: tokens.labelMono.copyWith(
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
