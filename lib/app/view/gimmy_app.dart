import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/storage/plan_repository.dart';
import '../../data/storage/session_repository.dart';
import '../../data/storage/settings_repository.dart';
import '../bloc/app_bloc.dart';
import 'home_shell.dart';

/// Root of the app: repositories, the shared [AppBloc], and the theme.
class GimmyApp extends StatelessWidget {
  const GimmyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => PlanRepository()),
        RepositoryProvider(create: (_) => SessionRepository()),
        RepositoryProvider(create: (_) => SettingsRepository()),
      ],
      child: BlocProvider(
        create: (context) => AppBloc(
          planRepository: context.read<PlanRepository>(),
          sessionRepository: context.read<SessionRepository>(),
          settingsRepository: context.read<SettingsRepository>(),
        )..add(const AppStarted()),
        child: const _ThemedApp(),
      ),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    // Only the theme rebuilds the MaterialApp; plan and session changes are
    // watched further down by the pages that care.
    final themeMode = context.select(
      (AppBloc bloc) => bloc.state.settings.themeMode,
    );

    return MaterialApp(
      title: 'Gimmy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) => _PhoneFrame(child: child),
      home: const HomeShell(),
    );
  }
}

/// Keeps the app at phone width on a wide screen.
///
/// The layout is designed for one thumb on a 4-column mobile grid. Letting it
/// stretch across a desktop browser gives you 1200px-wide buttons and line
/// lengths nobody can read, so it is centred in a phone-sized column instead
/// and the surplus becomes background.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget? child;

  /// Above the design system's mobile breakpoint there is nothing to gain from
  /// more width, so this is where the column stops growing.
  static const double _maxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (MediaQuery.sizeOf(context).width <= _maxWidth) return content;

    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.symmetric(
                vertical: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
