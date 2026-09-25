part of 'app_bloc.dart';

sealed class AppEvent extends Equatable {
  const AppEvent();

  @override
  List<Object?> get props => const [];
}

/// Read settings, the active plan and the session history from storage.
///
/// Also used to refresh after an import or a wipe.
class AppStarted extends AppEvent {
  const AppStarted();
}

class AppThemeModeChanged extends AppEvent {
  const AppThemeModeChanged(this.themeMode);

  final ThemeMode themeMode;

  @override
  List<Object?> get props => [themeMode];
}

/// Picks the color theme — Hacker Green, Sophisticated Blue — applied on top
/// of light/dark. Applies immediately when changed.
class AppThemeChanged extends AppEvent {
  const AppThemeChanged(this.themeId);

  final GimmyThemeId themeId;

  @override
  List<Object?> get props => [themeId];
}

/// Turns the step and completion cues — sound and vibration — on or off.
class AppCuesToggled extends AppEvent {
  const AppCuesToggled(this.isEnabled);

  final bool isEnabled;

  @override
  List<Object?> get props => [isEnabled];
}

/// Remembers [id] as the heart-rate sensor to connect to, now and on every
/// launch after this one.
class AppHeartRateMonitorPaired extends AppEvent {
  const AppHeartRateMonitorPaired({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Forgets the paired heart-rate sensor, which also disconnects it.
class AppHeartRateMonitorForgotten extends AppEvent {
  const AppHeartRateMonitorForgotten();
}

/// Deletes every plan, session and setting.
class AppWipeRequested extends AppEvent {
  const AppWipeRequested();
}
