import 'package:flutter/material.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/gimmy_card.dart';
import '../../../core/widgets/gimmy_logo.dart';
import '../../../core/widgets/gimmy_page_route.dart';
import '../../../core/widgets/gimmy_scaffold.dart';
import '../../../core/widgets/section_heading.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../settings/widgets/settings_row.dart';
import '../../settings/widgets/settings_section.dart';
import '../widgets/info_card.dart';
import 'legal_page.dart';

/// What Gimmy is, how it is built, who made it — and the way to the legal
/// notes and the open-source licences.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static Route<void> route() =>
      GimmyPageRoute<void>(builder: (_) => const AboutPage());

  static const _modules = [
    (
      icon: Icons.terminal,
      title: 'Flutter & Dart',
      tag: 'Material 3',
      body: 'One codebase for iOS, Android and the web, with Bloc for state.',
    ),
    (
      icon: Icons.developer_board,
      title: 'On-device .fit decoder',
      tag: 'Offline',
      body:
          'A decoder written for Gimmy: it checks the signature and CRC, '
          'reads the workout and its steps, and expands repeat blocks.',
    ),
    (
      icon: Icons.monitor_heart_outlined,
      title: 'Bluetooth heart rate',
      tag: 'BLE 0x180D',
      body:
          'Live BPM from a Garmin watch broadcasting heart rate, or any '
          'standard HRM strap.',
    ),
    (
      icon: Icons.save_outlined,
      title: 'Local storage',
      tag: 'No cloud',
      body:
          'Plans and sessions are saved as files on your phone, or in the '
          "browser's local storage on the web.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GimmyScaffold(
      label: 'About',
      leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
        children: [
          const SizedBox(height: GimmySpacing.sm),
          const SectionHeading(
            eyebrow: 'Version & credits',
            title: 'About Gimmy',
            subtitle: 'What the app does, how it is built, and who made it.',
          ),
          const SizedBox(height: GimmySpacing.md),
          const _Hero(),
          const SizedBox(height: GimmySpacing.md),
          const InfoCard(
            icon: Icons.psychology_outlined,
            title: 'Local-first',
            paragraphs: [
              'Gimmy reads your Garmin workout file on the device and guides '
                  'you through it one step at a time. Nothing is uploaded: no '
                  'account, no server, no tracking.',
              'Your streak and calendar are built from the sessions stored on '
                  'this phone, so the app works the same in a basement gym '
                  'with no signal.',
            ],
          ),
          const SizedBox(height: GimmySpacing.lg),
          _ModulesHeading(count: _modules.length),
          const SizedBox(height: GimmySpacing.sm),
          for (final module in _modules) ...[
            _ModuleCard(
              icon: module.icon,
              title: module.title,
              tag: module.tag,
              body: module.body,
            ),
            const SizedBox(height: GimmySpacing.sm),
          ],
          const SizedBox(height: GimmySpacing.md),
          const _AuthorCard(),
          const SizedBox(height: GimmySpacing.lg),
          SettingsSection(
            label: 'Legal & licences',
            children: [
              SettingsRow(
                icon: Icons.gavel,
                title: 'Legal notes & terms',
                subtitle: 'Disclaimer, your data, trademarks',
                onTap: () => Navigator.of(context).push(LegalPage.route()),
              ),
              SettingsRow(
                icon: Icons.integration_instructions_outlined,
                title: 'Open-source licences',
                subtitle: 'Flutter and every package Gimmy uses',
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Gimmy',
                  applicationVersion: AppConfig.appVersion,
                  applicationIcon: const Padding(
                    padding: EdgeInsets.all(GimmySpacing.sm),
                    child: GimmyLogo(size: 48),
                  ),
                  applicationLegalese: _copyright,
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.lg),
          const _Copyright(),
          const SizedBox(height: GimmySpacing.lg),
        ],
      ),
    );
  }
}

const _copyright = '© 2026 ${AppConfig.author} · MIT License';

/// The logo, name and version, over three facts that are actually true.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return GimmyCard(
      isHighlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GimmyLogo(size: 56),
              const SizedBox(width: GimmySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Gimmy', style: theme.textTheme.headlineLarge),
                    Text(
                      'v${AppConfig.appVersion}',
                      style: tokens.labelMono.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GimmySpacing.sm),
          Text(
            'A simple gym assistant for Garmin workout plans.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: GimmySpacing.md),
          const Row(
            children: [
              Expanded(
                child: StatTile(label: 'Network', value: '0 calls'),
              ),
              Expanded(
                child: StatTile(label: 'Account', value: 'None'),
              ),
              Expanded(
                child: StatTile(label: 'Data', value: 'Local'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModulesHeading extends StatelessWidget {
  const _ModulesHeading({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Row(
      children: [
        Expanded(
          child: Text('How it is built', style: theme.textTheme.headlineSmall),
        ),
        Text(
          '$count MODULES',
          style: tokens.labelMono.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.tag,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String tag;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return GimmyCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: GimmySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: GimmySpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      tag.toUpperCase(),
                      style: tokens.labelMono.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GimmySpacing.xs),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return GimmyCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              AppConfig.author[0].toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: GimmySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MADE BY',
                  style: tokens.labelMono.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  AppConfig.author,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Design & development · github.com/${AppConfig.author}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Copyright extends StatelessWidget {
  const _Copyright();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Text(
      _copyright,
      textAlign: TextAlign.center,
      style: tokens.labelMono.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
