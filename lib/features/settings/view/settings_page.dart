import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';
import '../widgets/theme_mode_selector.dart';
import '../widgets/wipe_confirmation_dialog.dart';

/// Theme, plan import, the phase-2/3 placeholders, and wiping the profile.
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.onImport,
    required this.onWiped,
  });

  /// Opens the Import page. Importing is reached from here rather than from the
  /// nav bar: it is a rare one-off, not a destination.
  final VoidCallback onImport;

  /// Called after the profile has been wiped, so the host can return to Import.
  final VoidCallback onWiped;

  @override
  Widget build(BuildContext context) {
    // Only what this page draws — not the session history behind the calendar.
    final themeMode = context.select(
      (AppBloc bloc) => bloc.state.settings.themeMode,
    );
    final plan = context.select((AppBloc bloc) => bloc.state.plan);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: GimmySpacing.sm),
          const _PageTitle(),
          const SizedBox(height: GimmySpacing.md),

          SettingsSection(
            label: 'Appearance',
            children: [
              SettingsRow(
                icon: Icons.dark_mode_outlined,
                title: 'Display interface',
                subtitle: 'Applies the moment you choose',
                below: ThemeModeSelector(
                  value: themeMode,
                  onChanged: (mode) =>
                      context.read<AppBloc>().add(AppThemeModeChanged(mode)),
                ),
              ),
              const SettingsRow(
                icon: Icons.palette_outlined,
                title: 'Accent colour',
                subtitle: 'Recolour the app to match your kit',
                isComingSoon: true,
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),

          SettingsSection(
            label: 'Workout & hardware',
            children: [
              SettingsRow(
                icon: Icons.file_open_outlined,
                title: 'Import new .fit plan',
                subtitle: plan == null
                    ? 'No plan imported yet'
                    : '${plan.name} · ${plan.stepCount} steps',
                onTap: onImport,
              ),
              const SettingsRow(
                icon: Icons.watch_outlined,
                title: 'Garmin & watch sync',
                subtitle: 'Pull workouts straight from Garmin Connect',
                isComingSoon: true,
              ),
              const SettingsRow(
                icon: Icons.notifications_active_outlined,
                title: 'Audio cues & haptic beeps',
                subtitle: 'Countdown beeps in the last seconds of a rest',
                isComingSoon: true,
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),

          SettingsSection(
            label: 'Data & privacy',
            children: [
              SettingsRow(
                icon: Icons.delete_forever_outlined,
                title: 'Wipe profile',
                subtitle: 'Delete every plan, session and setting',
                isDestructive: true,
                below: _WipeButton(onWiped: onWiped),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.md),

          const _Footer(),
          const SizedBox(height: GimmySpacing.lg),
        ],
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Settings', style: theme.textTheme.headlineLarge),
        Text(
          'APP & DATA CONFIG',
          style: tokens.labelMono.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _WipeButton extends StatelessWidget {
  const _WipeButton({required this.onWiped});

  final VoidCallback onWiped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: () async {
          final appBloc = context.read<AppBloc>();
          if (!await confirmWipe(context)) return;

          appBloc.add(const AppWipeRequested());
          onWiped();
        },
        icon: const Icon(Icons.warning_amber_rounded, size: 18),
        label: const Text('Wipe everything'),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.error,
          backgroundColor: theme.colorScheme.errorContainer.withValues(
            alpha: 0.2,
          ),
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.4),
          ),
          minimumSize: const Size.fromHeight(44),
        ),
      ),
    );
  }
}

/// The prototype's version strip, saying the thing that actually matters here.
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: GimmyRadii.card,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: GimmySpacing.sm),
              Text(
                'GIMMY',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.xs),
          Text(
            'Everything stays on this device. No account, no upload.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
