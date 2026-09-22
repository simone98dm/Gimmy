import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';

/// The prototype's quick light/dark switch.
///
/// Flips to the opposite of whatever is on screen right now, which also
/// resolves `ThemeMode.system` into an explicit choice. The three-way control
/// still lives in Settings.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return IconButton(
      onPressed: () => context.read<AppBloc>().add(
        AppThemeModeChanged(isDark ? ThemeMode.light : ThemeMode.dark),
      ),
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 18),
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainer,
        foregroundColor: theme.colorScheme.onSurfaceVariant,
        shape: const CircleBorder(),
      ),
    );
  }
}
