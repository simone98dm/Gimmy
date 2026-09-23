import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../about/view/about_page.dart';
import '../../about/view/legal_page.dart';
import '../../heart_rate/bloc/heart_rate_bloc.dart';
import '../../heart_rate/view/pairing_sheet.dart';
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
              // Web Bluetooth is Chrome-only and cannot reconnect without a
              // tap, so pairing is a mobile feature.
              if (!kIsWeb) const _HeartRateRow(),
              const _CuesRow(),
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

          SettingsSection(
            label: 'About',
            children: [
              SettingsRow(
                icon: Icons.info_outline,
                title: 'About Gimmy',
                subtitle: 'Version, how it is built, credits',
                onTap: () => Navigator.of(context).push(AboutPage.route()),
              ),
              SettingsRow(
                icon: Icons.gavel,
                title: 'Legal notes & terms',
                subtitle: 'Disclaimer, your data, trademarks',
                onTap: () => Navigator.of(context).push(LegalPage.route()),
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

/// Sound and vibration on every new step and at the finish.
class _CuesRow extends StatelessWidget {
  const _CuesRow();

  @override
  Widget build(BuildContext context) {
    final isEnabled = context.select(
      (AppBloc bloc) => bloc.state.settings.areCuesEnabled,
    );
    void toggle(bool value) =>
        context.read<AppBloc>().add(AppCuesToggled(value));

    return SettingsRow(
      icon: isEnabled
          ? Icons.notifications_active_outlined
          : Icons.notifications_off_outlined,
      title: 'Audio cues & haptics',
      subtitle: 'A beep and a buzz on every new step and at the finish',
      trailing: Switch(value: isEnabled, onChanged: toggle),
      onTap: () => toggle(!isEnabled),
    );
  }
}

/// The paired sensor and its live status; opens the pairing sheet.
class _HeartRateRow extends StatelessWidget {
  const _HeartRateRow();

  @override
  Widget build(BuildContext context) {
    final name = context.select(
      (AppBloc bloc) => bloc.state.settings.heartRateMonitorName,
    );
    final link = context.select((HeartRateBloc bloc) => bloc.state.link);
    final bpm = context.select((HeartRateBloc bloc) => bloc.state.bpm);

    final subtitle = switch (link) {
      HeartRateLink.none => 'Pair a Garmin watch or HRM strap for live BPM',
      HeartRateLink.connecting => '${name ?? 'Sensor'} · waiting for device',
      HeartRateLink.live => '${name ?? 'Sensor'} · $bpm bpm',
    };

    return SettingsRow(
      icon: Icons.watch_outlined,
      title: 'Garmin heart rate',
      subtitle: subtitle,
      onTap: () => showPairingSheet(context),
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
