import 'package:flutter/material.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/gimmy_page_route.dart';
import '../../../core/widgets/gimmy_scaffold.dart';
import '../../../core/widgets/section_heading.dart';
import '../widgets/info_card.dart';

/// The privacy policy (GDPR art. 13), cookies included: Gimmy sets none, so
/// there is no consent banner and no separate cookie policy. The inventory it
/// is written from is docs/privacy-audit.md; keep the two in step.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static Route<void> route() => GimmyPageRoute<void>(
    settings: const RouteSettings(name: 'privacy'),
    builder: (_) => const PrivacyPage(),
  );

  /// Bump whenever the text below changes.
  static const lastRevised = '8 October 2026';

  static const controllerName = 'Simone Dal Mas';
  static const controllerEmail = 'simone.dalmas@outlook.it';

  static const _sections = [
    (
      icon: Icons.person_outline,
      title: '1. Who is responsible',
      paragraphs: [
        'The data controller is $controllerName, a private individual who '
            'develops Gimmy as a non-commercial, open-source project. For '
            'anything about your data, write to $controllerEmail.',
      ],
    ),
    (
      icon: Icons.phone_iphone,
      title: '2. Data that stays on your device',
      paragraphs: [
        'Gimmy keeps your workout plan, your past sessions (including the '
            'heart-rate readings taken during them), your settings and the id '
            'of a paired heart-rate sensor. They are stored only on your '
            'device — in a file on a phone, in the browser\'s local storage on '
            'the web — and are never sent to me or to anyone else. I cannot '
            'see, copy or delete them.',
        'Heart rate can reveal something about your health. It is read only '
            'to show it to you and to record it in your own session history, '
            'on your device.',
        'You stay in control: "Wipe profile" in Settings erases everything, '
            'and so does uninstalling the app or clearing this site\'s data '
            'in your browser.',
      ],
    ),
    (
      icon: Icons.language,
      title: '3. The web version',
      paragraphs: [
        'The web version is hosted by Vercel Inc. (United States). Opening it '
            'sends Vercel\'s servers the technical data every web request '
            'carries: your IP address, browser type, the file requested and '
            'the time.',
        'This is needed to deliver the site and keep it secure, which is the '
            'legal basis for it: legitimate interest (GDPR art. 6(1)(f)). '
            'Vercel processes it on my behalf and keeps its logs under its own '
            'retention rules (vercel.com/legal/privacy-policy); to ask how long '
            'they are kept, write to $controllerEmail. Transfers to '
            'the United States rely on the EU-US Data Privacy Framework and '
            'the Standard Contractual Clauses in Vercel\'s data processing '
            'addendum.',
        'Everything the app needs, its rendering engine included, is served '
            'from that same site. No other third party is contacted.',
      ],
    ),
    (
      icon: Icons.bluetooth,
      title: '4. The mobile apps',
      paragraphs: [
        'The apps send nothing anywhere. Bluetooth is used only to read heart '
            'rate from the sensor you pair.',
        'If you download Gimmy from Google Play or the App Store, Google or '
            'Apple process the data of that download as independent '
            'controllers, under their own privacy policies.',
      ],
    ),
    (
      icon: Icons.cookie_outlined,
      title: '5. Cookies and local storage',
      paragraphs: [
        'Gimmy sets no cookies and uses no analytics, advertising, tracking '
            'or profiling of any kind.',
        'On the web it uses the browser\'s local storage (entries starting '
            'with "flutter.") to keep your plan, sessions and settings. This is '
            'strictly necessary for the service you asked for, so it needs no '
            'consent and there is no cookie banner. Clear it with "Wipe '
            'profile", or from your browser\'s site settings.',
      ],
    ),
    (
      icon: Icons.download_outlined,
      title: '6. Exercise demos',
      paragraphs: [
        if (FeatureFlags.showExerciseDemos)
          'When you save a plan, the demo of each exercise is downloaded from '
              'GitHub (GitHub Inc., part of Microsoft, United States). These '
              'requests name the demo files and nothing else, but like any web '
              'request they reveal your IP address to GitHub, under its own '
              'privacy policy and the EU-US Data Privacy Framework.'
        else
          'Exercise demos are switched off in this version, so nothing is '
              'downloaded.',
      ],
    ),
    (
      icon: Icons.rule,
      title: '7. What you have to provide',
      paragraphs: [
        'Nothing. There is no account and no form. The only data that leaves '
            'your device is the network data needed to load the web version.',
        'No decision about you is made automatically and no profile of you is '
            'built.',
      ],
    ),
    (
      icon: Icons.verified_user_outlined,
      title: '8. Your rights',
      paragraphs: [
        'Under GDPR articles 15 to 22 you can ask for access to your data, '
            'its correction or erasure, a restriction of its processing or a '
            'copy of it, and you can object to its processing. Your workout '
            'data lives only on your device, so you exercise most of these '
            'directly in the app.',
        'For anything else, write to $controllerEmail. I will answer within '
            'one month.',
        'You can also complain to the Italian data protection authority, the '
            'Garante per la protezione dei dati personali (garanteprivacy.it), '
            'or to the authority of the EU country where you live.',
      ],
    ),
    (
      icon: Icons.update,
      title: '9. Changes',
      paragraphs: [
        'This policy changes when the app does. The date at the top says '
            'which version you are reading.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GimmyScaffold(
      label: 'Privacy',
      leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: GimmyLayout.readingWidth),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: GimmySpacing.gutter,
            ),
            children: [
              const SizedBox(height: GimmySpacing.sm),
              const SectionHeading(
                title: 'Privacy policy',
                subtitle: 'Last updated $lastRevised',
              ),
              const SizedBox(height: GimmySpacing.md),
              const InfoCard(
                icon: Icons.lock_outline,
                title: 'In short',
                isHighlighted: true,
                paragraphs: [
                  'No account, no cookies, no analytics, no ads. Your plans, '
                      'sessions and heart rate stay on your device and never '
                      'reach me.',
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
              const SizedBox(height: GimmySpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}
