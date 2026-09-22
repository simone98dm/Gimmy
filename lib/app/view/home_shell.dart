import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/motion.dart';
import '../../core/widgets/app_footer.dart';
import '../../data/fit/fit_file_picker.dart';
import '../../features/execution/bloc/ticker.dart';
import '../../core/widgets/gimmy_scaffold.dart';
import '../../features/active/view/active_page.dart';
import '../../features/dashboard/view/dashboard_page.dart';
import '../../features/settings/view/settings_page.dart';
import '../bloc/app_bloc.dart';
import 'execution_route.dart';
import 'import_route.dart';

/// Hosts the three nav destinations and owns which one is showing.
///
/// On first launch — no plan stored — Import is pushed over the top instead,
/// and is dismissed only once a plan has been saved.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.pickFile = pickFitFile,
    this.ticker = const Ticker(),
  });

  /// Injectable so the first-launch import flow can be driven in tests without
  /// a platform channel.
  final FitFilePicker pickFile;

  /// Injectable so a workout can be driven in tests without real time.
  final Ticker ticker;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  GimmyTab _tab = GimmyTab.dashboard;
  bool _isImportOpen = false;

  /// Runs once per tab change, fading and lifting whichever page just became
  /// visible. The `IndexedStack` below keeps every page alive, so this animates
  /// the arrival without costing anyone their scroll position.
  late final AnimationController _tabTransition = AnimationController(
    vsync: this,
    duration: GimmyMotion.tabChange,
    value: 1,
  );

  void _selectTab(GimmyTab tab) {
    if (tab == _tab) return;
    setState(() => _tab = tab);
    _tabTransition.forward(from: 0);
  }

  @override
  void dispose() {
    _tabTransition.dispose();
    super.dispose();
  }

  static const _labels = {
    GimmyTab.dashboard: 'Dashboard',
    GimmyTab.active: 'Workout',
    GimmyTab.settings: 'Settings',
  };

  Future<void> _openImport({required bool canPop}) async {
    if (_isImportOpen) return;
    setState(() => _isImportOpen = true);

    final imported = await Navigator.of(
      context,
    ).push<bool>(ImportRoute.route(canPop: canPop, pickFile: widget.pickFile));

    if (!mounted) return;
    setState(() => _isImportOpen = false);

    if (imported != true) return;

    // Pick up the plan that was just saved, and land on the Dashboard.
    context.read<AppBloc>().add(const AppStarted());
    setState(() => _tab = GimmyTab.dashboard);
  }

  /// Runs the active plan, then refreshes so the streak and calendar pick up
  /// the session that was just recorded.
  Future<void> _startWorkout() async {
    final plan = context.read<AppBloc>().state.plan;
    if (plan == null) return;

    await Navigator.of(context)
        .push(ExecutionRoute.route(plan: plan, ticker: widget.ticker));

    if (!mounted) return;
    context.read<AppBloc>().add(const AppStarted());
    setState(() => _tab = GimmyTab.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      // A ready state with no plan means either a fresh install or a wipe.
      // Either way there is nothing to show until something is imported.
      listenWhen: (previous, current) =>
          current.status == AppStatus.ready && !current.hasPlan,
      listener: (context, state) => _openImport(canPop: false),
      child: GimmyScaffold(
        label: _labels[_tab]!,
        tab: _tab,
        onSelectTab: _selectTab,
        child: _TabTransition(
          animation: _tabTransition,
          child: IndexedStack(
            index: GimmyTab.values.indexOf(_tab),
            children: [
              DashboardPage(
                onStartWorkout: _startWorkout,
                onImport: () => _openImport(canPop: true),
              ),
              ActivePage(
                onStartWorkout: _startWorkout,
                onImport: () => _openImport(canPop: true),
              ),
              SettingsPage(
                onImport: () => _openImport(canPop: true),
                onWiped: () => setState(() => _tab = GimmyTab.dashboard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and lifts [child] as [animation] runs.
class _TabTransition extends StatelessWidget {
  const _TabTransition({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (GimmyMotion.isReduced(context)) return child;

    final curved = CurvedAnimation(parent: animation, curve: GimmyMotion.enter);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, GimmyMotion.enterOffset),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
