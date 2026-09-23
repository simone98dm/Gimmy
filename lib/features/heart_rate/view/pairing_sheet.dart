import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/gimmy_cta.dart';
import '../../../data/heart_rate/heart_rate_monitor.dart';
import '../../execution/widgets/live_dot.dart';
import '../bloc/heart_rate_bloc.dart';

/// The Stitch "Garmin Device Pairing Modal": scans for heart-rate sensors and
/// pairs one. Scanning runs for as long as the sheet is open.
Future<void> showPairingSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const PairingSheet(),
  );
}

class PairingSheet extends StatefulWidget {
  const PairingSheet({super.key});

  @override
  State<PairingSheet> createState() => _PairingSheetState();
}

class _PairingSheetState extends State<PairingSheet> {
  late final HeartRateBloc _bloc = context.read<HeartRateBloc>();

  @override
  void initState() {
    super.initState();
    _bloc.add(const HeartRateScanRequested());
  }

  @override
  void dispose() {
    _bloc.add(const HeartRateScanStopped());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pairedId = context.select(
      (AppBloc bloc) => bloc.state.settings.heartRateMonitorId,
    );
    final pairedName = context.select(
      (AppBloc bloc) => bloc.state.settings.heartRateMonitorName,
    );
    final state = context.watch<HeartRateBloc>().state;
    final found = [
      for (final monitor in state.nearby)
        if (monitor.id != pairedId) monitor,
    ];

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            GimmySpacing.md,
            0,
            GimmySpacing.md,
            GimmySpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Header(),
              const SizedBox(height: GimmySpacing.md),
              _ScanCard(state: state),
              if (pairedId != null) ...[
                const SizedBox(height: GimmySpacing.md),
                _PairedRow(
                  name: pairedName ?? 'Heart-rate sensor',
                  state: state,
                ),
              ],
              const SizedBox(height: GimmySpacing.md),
              _FoundHeading(count: found.length, isScanning: state.isScanning),
              const SizedBox(height: GimmySpacing.sm),
              if (found.isEmpty && !state.isScanning)
                const _EmptyHint()
              else
                for (final (index, monitor) in found.indexed) ...[
                  _MonitorRow(monitor: monitor, isStrongest: index == 0),
                  const SizedBox(height: GimmySpacing.sm),
                ],
              const SizedBox(height: GimmySpacing.sm),
              const _BroadcastNote(),
              const SizedBox(height: GimmySpacing.md),
              GimmyCta(
                label: 'Done',
                icon: Icons.check,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.sensors, color: theme.colorScheme.primary),
                  const SizedBox(width: GimmySpacing.sm),
                  Flexible(
                    child: Text(
                      'Pair Garmin device',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'BLUETOOTH LOW ENERGY · HEART RATE',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.state});

  final HeartRateState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final error = state.scanError;

    final status =
        error ??
        (state.isScanning ? 'Searching nearby devices…' : 'Scan finished');

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.card,
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.watch,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: GimmySpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (error == null) ...[
                LiveDot(isLive: state.isScanning),
                const SizedBox(width: GimmySpacing.sm),
              ],
              Flexible(
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: error == null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PairedRow extends StatelessWidget {
  const _PairedRow({required this.name, required this.state});

  final String name;
  final HeartRateState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    final status = switch (state.link) {
      HeartRateLink.live => 'Connected · ${state.bpm} bpm',
      _ => 'Waiting for the device…',
    };

    return _RowShell(
      isHighlighted: true,
      icon: _iconFor(name),
      title: name,
      subtitle: Text(
        status,
        style: tokens.labelMono.copyWith(
          color: state.link == HeartRateLink.live
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      action: OutlinedButton(
        style: _compact,
        onPressed: () =>
            context.read<AppBloc>().add(const AppHeartRateMonitorForgotten()),
        child: const Text('Forget'),
      ),
    );
  }
}

class _FoundHeading extends StatelessWidget {
  const _FoundHeading({required this.count, required this.isScanning});

  final int count;
  final bool isScanning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'DEVICES FOUND ($count)',
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton.icon(
          onPressed: isScanning
              ? null
              : () => context.read<HeartRateBloc>().add(
                  const HeartRateScanRequested(),
                ),
          icon: const Icon(Icons.sync, size: 18),
          label: const Text('Scan again'),
        ),
      ],
    );
  }
}

class _MonitorRow extends StatelessWidget {
  const _MonitorRow({required this.monitor, required this.isStrongest});

  final NearbyMonitor monitor;
  final bool isStrongest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);
    final percent = monitor.signalPercent;

    final (signalIcon, quality) = switch (percent) {
      >= 75 => (Icons.signal_cellular_alt, 'Excellent'),
      >= 50 => (Icons.signal_cellular_alt_2_bar, 'Good'),
      _ => (Icons.signal_cellular_alt_1_bar, 'Weak'),
    };

    void pair() {
      context.read<HeartRateBloc>().add(const HeartRateScanStopped());
      context.read<AppBloc>().add(
        AppHeartRateMonitorPaired(id: monitor.id, name: monitor.name),
      );
    }

    const label = Text('Pair');
    const icon = Icon(Icons.link, size: 18);

    return _RowShell(
      isHighlighted: isStrongest,
      icon: _iconFor(monitor.name),
      title: monitor.name,
      subtitle: Row(
        children: [
          Icon(signalIcon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 2),
          Text(
            '$percent% $quality',
            style: tokens.labelMono.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      action: Semantics(
        label: 'Pair ${monitor.name}',
        excludeSemantics: true,
        button: true,
        child: isStrongest
            ? FilledButton.icon(
                style: _compact,
                onPressed: pair,
                icon: icon,
                label: label,
              )
            : OutlinedButton.icon(
                style: _compact,
                onPressed: pair,
                icon: icon,
                label: label,
              ),
      ),
    );
  }
}

/// The card every device row shares: icon tile, name, one line of detail, and
/// an action on the right.
class _RowShell extends StatelessWidget {
  const _RowShell({
    required this.isHighlighted,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final bool isHighlighted;
  final IconData icon;
  final String title;
  final Widget subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: GimmyRadii.button,
        border: Border.all(
          color: isHighlighted
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : tokens.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: GimmyRadii.cell,
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: GimmySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
          const SizedBox(width: GimmySpacing.sm),
          action,
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GimmySpacing.sm),
      child: Text(
        'No heart-rate sensors found nearby.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BroadcastNote extends StatelessWidget {
  const _BroadcastNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(GimmySpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: GimmyRadii.cell,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: GimmySpacing.sm),
          Expanded(
            child: Text(
              'On a Garmin watch, turn on Broadcast Heart Rate '
              '(Settings › Wrist Heart Rate) so it shows up here. '
              'HRM straps appear as soon as you put them on.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The theme's buttons are full-width CTAs; a row action has to size to its
/// label instead.
const ButtonStyle _compact = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, GimmyLayout.minTapTarget)),
  padding: WidgetStatePropertyAll(
    EdgeInsets.symmetric(horizontal: GimmySpacing.md),
  ),
);

IconData _iconFor(String name) =>
    name.toUpperCase().contains('HRM') ? Icons.monitor_heart : Icons.watch;
