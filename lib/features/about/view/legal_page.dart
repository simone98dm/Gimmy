import 'package:flutter/material.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/gimmy_page_route.dart';
import '../../../core/widgets/gimmy_scaffold.dart';
import '../../../core/widgets/section_heading.dart';
import '../widgets/info_card.dart';

/// Legal notes and terms of use, pushed from Settings and from About.
class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static Route<void> route() =>
      GimmyPageRoute<void>(builder: (_) => const LegalPage());

  /// Bump whenever the text below changes.
  static const lastRevised = '23 September 2026';

  static const _sections = [
    (
      icon: Icons.description_outlined,
      title: '1. Licence',
      paragraphs: [
        'Gimmy is open-source software released under the MIT License. '
            'You may use, copy, modify and distribute it under the terms of '
            'that licence, which ships with the source code.',
        'The software is provided "as is", without warranty of any kind, '
            'express or implied.',
      ],
    ),
    (
      icon: Icons.fitness_center,
      title: '2. Using the app',
      paragraphs: [
        'You train at your own risk. Warm up, use equipment you know how to '
            'use, and stop if anything hurts. You are responsible for the '
            'plans you import and for judging whether a workout suits you.',
        'Timers, step counts and durations are guidance. Heart-rate readings '
            'depend on your sensor and its fit, and may be late, missing or '
            'wrong.',
      ],
    ),
    (
      icon: Icons.lock_outline,
      title: '3. Your data',
      paragraphs: [
        'Everything Gimmy stores — your plan, your sessions, your settings '
            'and the id of a paired heart-rate sensor — stays on this device. '
            'There is no account, no analytics and no server; the app makes '
            'no network requests while it runs.',
        'Bluetooth is used only to read heart rate from the sensor you pair. '
            '"Wipe profile" in Settings deletes everything, and so does '
            'uninstalling the app.',
      ],
    ),
    (
      icon: Icons.file_open_outlined,
      title: '4. Imported .fit files',
      paragraphs: [
        'Workout files are read on the device and never uploaded. Only the '
            'workout definition is kept; the file itself is not.',
        'Gimmy supports Garmin workout files. Activity files, courses and '
            'damaged files are rejected, and no guarantee is given that every '
            'workout file will import.',
      ],
    ),
    (
      icon: Icons.copyright,
      title: '5. Trademarks',
      paragraphs: [
        'Garmin, Garmin Connect and FIT are trademarks of Garmin Ltd. or its '
            'subsidiaries. The Bluetooth word mark is owned by Bluetooth SIG, '
            'Inc. Other names belong to their respective owners.',
        'Gimmy is an independent project. It is not affiliated with, '
            'sponsored by or endorsed by Garmin.',
      ],
    ),
    (
      icon: Icons.integration_instructions_outlined,
      title: '6. Third-party software',
      paragraphs: [
        'Gimmy is built with Flutter and open-source packages, each under its '
            'own licence; the full texts are under "Open-source licences" on '
            'the About page.',
        'Bluetooth support comes from flutter_blue_plus, which is free for '
            'personal use only.',
      ],
    ),
    (
      icon: Icons.shield_outlined,
      title: '7. Limitation of liability',
      paragraphs: [
        'To the fullest extent the law allows, the author is not liable for '
            'injury, loss of data or any other damage arising from the use of '
            'the app.',
      ],
    ),
    (
      icon: Icons.update,
      title: '8. Changes',
      paragraphs: [
        'These terms may change in a later version of the app. The revision '
            'date at the top of this page says which version you are reading.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GimmyScaffold(
      label: 'Legal',
      leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.gutter),
        children: [
          const SizedBox(height: GimmySpacing.sm),
          const SectionHeading(
            eyebrow: 'Terms of use & disclaimer',
            title: 'Legal notes & terms',
          ),
          const SizedBox(height: GimmySpacing.sm),
          const _RevisionStrip(),
          const SizedBox(height: GimmySpacing.md),
          const InfoCard(
            icon: Icons.medical_services_outlined,
            title: 'Not a medical device',
            isHighlighted: true,
            paragraphs: [
              'Gimmy is a workout guide. It does not diagnose, treat or '
                  'prevent any condition, and its heart-rate readout is not '
                  'for medical use.',
              'Talk to a doctor before starting a new training programme, '
                  'especially a high-intensity one or if you have a heart '
                  'condition.',
            ],
          ),
          for (final section in _sections) ...[
            const SizedBox(height: GimmySpacing.md),
            InfoCard(
              icon: section.icon,
              title: section.title,
              paragraphs: section.paragraphs,
            ),
          ],
          const SizedBox(height: GimmySpacing.md),
          const InfoCard(
            icon: Icons.alternate_email,
            title: 'Contact',
            paragraphs: [
              'Questions, bugs or takedown requests: open an issue at '
                  'github.com/${AppConfig.author}/Gimmy.',
            ],
          ),
          const SizedBox(height: GimmySpacing.lg),
        ],
      ),
    );
  }
}

/// Revision date and version, in the mono telemetry style.
class _RevisionStrip extends StatelessWidget {
  const _RevisionStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Wrap(
      spacing: GimmySpacing.sm,
      runSpacing: GimmySpacing.xs,
      children: [
        _Chip(
          icon: Icons.verified_outlined,
          label: 'Last revised ${LegalPage.lastRevised}',
          style: tokens.labelMono.copyWith(color: theme.colorScheme.primary),
        ),
        _Chip(
          icon: Icons.tag,
          label: 'v${AppConfig.appVersion}',
          style: tokens.labelMono.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label, required this.style});

  final IconData icon;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GimmySpacing.sm,
        vertical: GimmySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(GimmyRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: style.color),
          const SizedBox(width: GimmySpacing.xs),
          Flexible(child: Text(label, style: style)),
        ],
      ),
    );
  }
}
