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

/// Deletes every plan, session and setting.
class AppWipeRequested extends AppEvent {
  const AppWipeRequested();
}
