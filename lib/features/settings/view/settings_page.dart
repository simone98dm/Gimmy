import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/widgets/desktop_layout.dart';
import '../../about/view/about_page.dart';
import '../../about/view/legal_page.dart';
import '../../heart_rate/bloc/heart_rate_bloc.dart';
import '../../heart_rate/view/pairing_sheet.dart';
import '../widgets/settings_desktop.dart';
import '../widgets/settings_row.dart';
import '../widgets/settings_section.dart';
import '../widgets/theme_mode_selector.dart';
import '../widgets/wipe_confirmation_dialog.dart';

/// Theme, plan import, sensor and cues, the data kept, and About.
///
/// On a desktop the four sections form a 2×2 grid, as in the Stitch desktop
/// settings screen.
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

    final isDesktop = isDesktopLayout(context);
    final sessionCount = context.select(
      (AppBloc bloc) => bloc.state.sessions.length,
    );
    void openAbout() => Navigator.of(context).push(AboutPage.route());
    void openLegal() => Navigator.of(context).push(LegalPage.route());

    final appearance = SettingsSection(
      label: 'Appearance',
      icon: Icons.display_settings,
      caption: 'Theme',
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
      ],
    );
    final workout = SettingsSection(
      label: 'Workout & hardware',
      icon: Icons.watch_outlined,
      caption: 'Plans, sensors & cues',
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
    );
    final data = SettingsSection(
      label: 'Data & privacy',
      icon: Icons.shield_outlined,
      // On a desktop the sidebar already says this on every page.
      caption: isDesktop
          ? 'What this device keeps'
          : 'Stored on this device only · no account, no upload',
      children: [
        if (isDesktop)
          LocalStorageCard(sessionCount: sessionCount, hasPlan: plan != null),
        // One quiet row: the confirmation dialog is the safeguard, so the
        // destructive action need not be the loudest thing on the page.
        SettingsRow(
          icon: Icons.delete_forever_outlined,
          title: 'Wipe profile',
          subtitle: 'Delete every plan, session and setting',
          isDestructive: true,
          onTap: () async {
            final appBloc = context.read<AppBloc>();
            if (!await confirmWipe(context)) return;

            appBloc.add(const AppWipeRequested());
            onWiped();
          },
        ),
      ],
    );
    final about = SettingsSection(
      label: 'About',
      icon: Icons.info_outline,
      caption: 'Version ${AppConfig.appVersion} · legal',
      children: [
        SettingsRow(
          icon: Icons.info_outline,
          title: 'About Gimmy',
          subtitle: 'Version, how it is built, credits',
          onTap: openAbout,
        ),
        SettingsRow(
          icon: Icons.gavel,
          title: 'Legal notes & terms',
          subtitle: 'Disclaimer, your data, trademarks',
          onTap: openLegal,
        ),
      ],
    );

    if (isDesktop) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: GimmySpacing.md),
            const SettingsDesktopHeader(),
            const SizedBox(height: GimmySpacing.lg),
            DesktopColumns(
              isEqualHeight: true,
              start: appearance,
              end: workout,
            ),
            const SizedBox(height: GimmySpacing.lg),
            DesktopColumns(isEqualHeight: true, start: data, end: about),
            const SizedBox(height: GimmySpacing.lg),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: GimmySpacing.sm),
          const _PageTitle(),
          const SizedBox(height: GimmySpacing.md),

          for (final section in [appearance, workout, data, about]) ...[
            section,
            const SizedBox(height: GimmySpacing.md),
          ],
          const SizedBox(height: GimmySpacing.sm),
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
      HeartRateLink.none => 'Pair a watch or chest strap for live BPM',
      HeartRateLink.connecting => '${name ?? 'Sensor'} · waiting for device',
      HeartRateLink.live => '${name ?? 'Sensor'} · $bpm bpm',
    };

    return SettingsRow(
      icon: Icons.watch_outlined,
      // Any standard BLE heart-rate sensor works, not only Garmin's.
      title: 'Heart-rate sensor',
      subtitle: subtitle,
      onTap: () => showPairingSheet(context),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return Text('Settings', style: Theme.of(context).textTheme.headlineLarge);
  }
}
