import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/heart_rate/bloc/heart_rate_bloc.dart';

import 'package:wakelock_plus/wakelock_plus.dart';

import '../bloc/app_bloc.dart';
import '../../core/widgets/app_sidebar.dart';
import '../../core/widgets/gimmy_page_route.dart';
import '../../core/widgets/gimmy_scaffold.dart';
import '../../data/models/plan.dart';
import '../../data/storage/session_repository.dart';
import 'sidebar_stats.dart';
import '../../features/execution/bloc/execution_bloc.dart';
import '../../features/execution/bloc/ticker.dart';
import '../../features/execution/view/execution_page.dart';

/// Hosts a workout run: the bloc, the wakelock, and the guard against leaving
/// by accident.
class ExecutionRoute extends StatelessWidget {
  const ExecutionRoute({
    super.key,
    required this.plan,
    this.ticker = const Ticker(),
  });

  final Plan plan;

  /// Injectable so the flow can be driven in tests without real time.
  final Ticker ticker;

  static Route<void> route({
    required Plan plan,
    Ticker ticker = const Ticker(),
  }) => GimmyPageRoute<void>(
    settings: const RouteSettings(name: 'workout'),
    builder: (_) => ExecutionRoute(plan: plan, ticker: ticker),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ExecutionBloc(
        plan: plan,
        sessionRepository: context.read<SessionRepository>(),
        ticker: ticker,
        // Read on each counted second; null whenever no sensor is reporting.
        heartRate: () => context.read<HeartRateBloc>().state.bpm,
      )..add(const ExecutionStarted()),
      child: const _ExecutionHost(),
    );
  }
}

class _ExecutionHost extends StatefulWidget {
  const _ExecutionHost();

  @override
  State<_ExecutionHost> createState() => _ExecutionHostState();
}

class _ExecutionHostState extends State<_ExecutionHost> {
  @override
  void initState() {
    super.initState();
    // Nobody wants the screen dimming halfway through a plank. Failures here
    // are not worth interrupting a workout over — the platform may simply not
    // allow it.
    WakelockPlus.enable().catchError((_) {});
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((_) {});
    super.dispose();
  }

  /// Asks before throwing away a workout in progress.
  Future<bool> _confirmAbandon() async {
    final confirmed = await showDialog<bool>(
      routeSettings: const RouteSettings(name: 'leave-workout dialog'),
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave this workout?'),
        content: const Text(
          'It will be saved as abandoned. The day still counts towards your '
          'streak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ExecutionBloc>().state;

    return PopScope(
      // A finished workout is already saved, so it leaves freely. A running one
      // has to be confirmed and recorded as abandoned first.
      canPop: state.isFinished,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;

        // Resolved before the dialog, so nothing reaches across the await.
        final bloc = context.read<ExecutionBloc>();
        final navigator = Navigator.of(context);

        if (!await _confirmAbandon()) return;

        bloc.add(const ExecutionAbandoned());
        navigator.pop();
      },
      child: GimmyScaffold(
        label: 'Workout',
        // The control bar meets the bottom edge; see PhoneRunner.
        extendsToBottomEdge: true,
        // Inert: the way out of a workout is the back button and its
        // confirmation, not a sidebar click.
        sidebarItem: SidebarItem.active,
        sidebarFooter: const SidebarStats(),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
        child: ExecutionPage(
          areCuesEnabled: context.select(
            (AppBloc bloc) => bloc.state.settings.areCuesEnabled,
          ),
          history: context.select((AppBloc bloc) => bloc.state.sessions),
          // `pop`, not `maybePop`: the PopScope above would otherwise ask the
          // user to confirm leaving a workout they have already finished.
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
