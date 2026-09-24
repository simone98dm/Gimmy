import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_log.dart';

/// Logs every event a bloc receives — which is every user action that changes
/// state — and every error a bloc reports.
class LoggingBlocObserver extends BlocObserver {
  const LoggingBlocObserver();

  /// Events that fire on a clock or a radio rather than a user, and would
  /// bury everything else: the workout tick, heart-rate readings, scan results.
  static const _quiet = {
    'ExecutionTicked',
    '_HeartRateReceived',
    '_NearbyUpdated',
  };

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (_quiet.contains(event.runtimeType.toString())) return;
    AppLog.action(bloc.runtimeType.toString(), '$event');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    AppLog.error(bloc.runtimeType.toString(), 'unhandled', error, stackTrace);
  }
}

/// Logs every page, dialog and sheet that opens or closes.
class LoggingNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      AppLog.action('navigation', 'open ${_name(route)}');

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      AppLog.action('navigation', 'close ${_name(route)}');

  static String _name(Route<dynamic> route) =>
      route.settings.name ?? route.runtimeType.toString();
}
