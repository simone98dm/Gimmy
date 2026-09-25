import 'package:intl/intl.dart';

import '../../data/models/workout_session.dart';
import '../../data/session_comparison.dart';

/// Wording for [SessionComparison]: plain changes, a real minus sign, and no
/// verdict — longer is not better, and neither is shorter.

const _minus = '−';

String _sign(int value) => value < 0 ? _minus : '+';

/// "+3 min" / "−45 s", or with [clock] "+0:15" / "−1:05".
String signedDuration(int seconds, {bool clock = false}) {
  final size = seconds.abs();
  if (clock) {
    final s = (size % 60).toString().padLeft(2, '0');
    return '${_sign(seconds)}${size ~/ 60}:$s';
  }
  if (size < 60) return '${_sign(seconds)}$size s';
  return '${_sign(seconds)}${(size / 60).round()} min';
}

String _signed(int value) => '${_sign(value)}${value.abs()}';

/// "vs Wed 23: +3 min active · +2 done · −4 avg BPM"
String comparisonLine(SessionComparison c) {
  final day = DateFormat('EEE d').format(c.previous.startedAt);
  final bpm = c.averageBpmChange;
  return 'vs $day: ${[c.activeSecondsChange == 0 ? 'same time' : '${signedDuration(c.activeSecondsChange)} active', c.doneChange == 0 ? 'same steps done' : '${_signed(c.doneChange)} done', if (bpm != null) bpm == 0 ? 'same avg BPM' : '${_signed(bpm)} avg BPM'].join(' · ')}';
}

/// The same, in words a screen reader can say.
String spokenComparison(SessionComparison c) {
  final day = DateFormat.EEEE().format(c.previous.startedAt);
  String amount(int n, String one, String many) =>
      n == 1 ? '1 $one' : '$n $many';

  final time = c.activeSecondsChange;
  final minutes = (time.abs() / 60).round();
  final done = c.doneChange;
  final bpm = c.averageBpmChange;

  return 'Compared with $day: ${[if (time == 0) 'the same active time' else '${time.abs() < 60 ? amount(time.abs(), 'second', 'seconds') : amount(minutes, 'minute', 'minutes')} '
        '${time > 0 ? 'more' : 'less'} active', if (done == 0) 'the same steps done' else '${amount(done.abs(), 'step', 'steps').replaceFirst(' ', done > 0 ? ' more ' : ' fewer ')} done', if (bpm != null) bpm == 0 ? 'the same average heart rate' : '${bpm.abs()} BPM ${bpm > 0 ? 'higher' : 'lower'} average'].join(', ')}';
}

/// Under a step row: "skipped before · +0:15 · −4 BPM". Outcome first, since
/// doing a step you skipped last time is the bigger news.
String stepChangeLine(StepComparison c, StepOutcome now) {
  final outcomeChanged = c.previousOutcome != now;
  return [
    if (outcomeChanged)
      now == StepOutcome.done ? 'skipped before' : 'done before',
    // A skipped step's time and heart rate say nothing.
    if (now == StepOutcome.done) ...[
      if (c.secondsChange != 0) signedDuration(c.secondsChange, clock: true),
      if (c.averageBpmChange case final bpm? when bpm != 0)
        '${_signed(bpm)} BPM',
    ],
  ].join(' · ');
}
