import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/plan.dart';
import '../../data/models/workout_session.dart';
import '../../data/storage/plan_repository.dart';
import '../../data/storage/session_repository.dart';
import '../../data/storage/settings_repository.dart';
import '../../data/streak_calculator.dart';
import '../../core/logging/app_log.dart';
import '../../core/theme/gimmy_theme_id.dart';

part 'app_event.dart';
part 'app_state.dart';

/// Owns the state shared across the whole app: settings, the active plan, and
/// the session history.
class AppBloc extends Bloc<AppEvent, AppState> {
  AppBloc({
    required PlanRepository planRepository,
    required SessionRepository sessionRepository,
    required SettingsRepository settingsRepository,
  }) : _planRepository = planRepository,
       _sessionRepository = sessionRepository,
       _settingsRepository = settingsRepository,
       super(const AppState()) {
    on<AppStarted>(_onStarted);
    on<AppThemeModeChanged>(_onThemeModeChanged);
    on<AppThemeChanged>(_onThemeChanged);
    on<AppCuesToggled>(
      (event, emit) => _saveSettings(
        state.settings.copyWith(areCuesEnabled: event.isEnabled),
        emit,
      ),
    );
    on<AppHeartRateMonitorPaired>(
      (event, emit) => _saveSettings(
        state.settings.copyWith(
          heartRateMonitorId: event.id,
          heartRateMonitorName: event.name,
        ),
        emit,
      ),
    );
    on<AppHeartRateMonitorForgotten>(
      (event, emit) =>
          _saveSettings(state.settings.withoutHeartRateMonitor(), emit),
    );
    on<AppWipeRequested>(_onWipeRequested);
  }

  final PlanRepository _planRepository;
  final SessionRepository _sessionRepository;
  final SettingsRepository _settingsRepository;

  Future<void> _onStarted(AppStarted event, Emitter<AppState> emit) async {
    final settings = await _settingsRepository.load();
    final plan = await _planRepository.load();
    final sessions = await _sessionRepository.loadAll();
    AppLog.info(
      'app',
      'loaded ${plan == null ? 'no plan' : 'plan "${plan.name}"'}, '
          '${sessions.length} sessions, theme ${settings.themeMode.name}',
    );

    emit(
      AppState(
        status: AppStatus.ready,
        settings: settings,
        plan: plan,
        sessions: sessions,
      ),
    );
  }

  Future<void> _onThemeModeChanged(
    AppThemeModeChanged event,
    Emitter<AppState> emit,
  ) async {
    // Emit first: the theme should switch under the user's finger, not after
    // a disk write.
    await _saveSettings(
      state.settings.copyWith(themeMode: event.themeMode),
      emit,
    );
  }

  Future<void> _onThemeChanged(
    AppThemeChanged event,
    Emitter<AppState> emit,
  ) async {
    // Emit first: the theme should switch under the user's finger, not after
    // a disk write.
    await _saveSettings(state.settings.copyWith(themeId: event.themeId), emit);
  }

  Future<void> _saveSettings(
    AppSettings settings,
    Emitter<AppState> emit,
  ) async {
    emit(state.copyWith(settings: settings));
    await _settingsRepository.save(settings);
  }

  Future<void> _onWipeRequested(
    AppWipeRequested event,
    Emitter<AppState> emit,
  ) async {
    await _planRepository.clear();
    await _sessionRepository.clear();
    await _settingsRepository.clear();
    AppLog.info('app', 'profile wiped');

    emit(const AppState(status: AppStatus.ready));
  }
}
