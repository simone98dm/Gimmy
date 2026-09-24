import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/view/gimmy_app.dart';
import 'core/config/feature_flags.dart';
import 'core/logging/app_log.dart';
import 'core/logging/log_observers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Errors in a build, a layout or a gesture: log them, then let Flutter show
  // its usual red screen in debug.
  FlutterError.onError = (details) {
    AppLog.error(
      'flutter',
      details.context?.toString() ?? 'framework error',
      details.exception,
      details.stack,
    );
    FlutterError.presentError(details);
  };

  // Anything async that nobody awaited.
  WidgetsBinding.instance.platformDispatcher.onError = (error, stackTrace) {
    AppLog.error('platform', 'uncaught', error, stackTrace);
    return true;
  };

  // Event props in the log in release builds too, not just the class name.
  EquatableConfig.stringify = true;
  Bloc.observer = const LoggingBlocObserver();

  AppLog.info('app', 'launch v${AppConfig.appVersion}');
  runApp(const GimmyApp());
}
