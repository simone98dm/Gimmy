part of 'app_bloc.dart';

enum AppStatus {
  /// Reading from storage. The launch screen shows nothing but the chrome.
  loading,

  /// Storage has been read; [AppState.plan] says which page to open on.
  ready,
}

/// Everything the three tabs share: the settings, the active plan, and the
/// session history behind the streak and the calendar.
///
/// One source of truth so switching tabs does not re-read the disk, and so an
/// import or a wipe updates every page at once.
class AppState extends Equatable {
  const AppState({
    this.status = AppStatus.loading,
    this.settings = const AppSettings(),
    this.plan,
    this.sessions = const [],
  });

  final AppStatus status;
  final AppSettings settings;

  /// Null until a plan has been imported. Drives the launch destination.
  final Plan? plan;

  /// Every session ever recorded, oldest first.
  final List<WorkoutSession> sessions;

  bool get hasPlan => plan != null;

  /// Consecutive days, counted at the moment of asking.
  int streakOn(DateTime now) => StreakCalculator.calculate(sessions, now: now);

  AppState copyWith({
    AppStatus? status,
    AppSettings? settings,
    Plan? plan,
    List<WorkoutSession>? sessions,
  }) {
    return AppState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      plan: plan ?? this.plan,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  List<Object?> get props => [status, settings, plan, sessions];
}
