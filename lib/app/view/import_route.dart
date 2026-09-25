import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/widgets/app_sidebar.dart';
import '../../core/widgets/gimmy_page_route.dart';
import '../../core/widgets/gimmy_scaffold.dart';
import '../../data/exercises/exercise_demos.dart';
import '../../data/fit/fit_file_picker.dart';
import '../../data/storage/plan_repository.dart';
import '../../data/storage/settings_repository.dart';
import 'sidebar_stats.dart';
import '../../features/import/bloc/import_bloc.dart';
import '../../features/import/view/import_page.dart';

/// The Import page as a standalone route.
///
/// It is not a nav-bar destination: it is pushed from Settings, or shown on
/// launch when no plan exists yet. Pops with `true` once a plan is saved.
class ImportRoute extends StatelessWidget {
  const ImportRoute({
    super.key,
    this.canPop = true,
    this.pickFile = pickFitFile,
    this.onSidebarSelect,
  });

  /// False on first launch, when there is nothing to go back to.
  final bool canPop;

  /// Injectable so the route can be driven in tests without a platform channel.
  final FitFilePicker pickFile;

  /// Desktop sidebar navigation away from Import. Null keeps the sidebar
  /// inert, as it must be on first launch.
  final ValueChanged<SidebarItem>? onSidebarSelect;

  static Route<bool> route({
    bool canPop = true,
    FitFilePicker pickFile = pickFitFile,
    ValueChanged<SidebarItem>? onSidebarSelect,
  }) => GimmyPageRoute<bool>(
    settings: const RouteSettings(name: 'import'),
    builder: (_) => ImportRoute(
      canPop: canPop,
      pickFile: pickFile,
      onSidebarSelect: onSidebarSelect,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImportBloc(
        pickFile: pickFile,
        planRepository: context.read<PlanRepository>(),
        settingsRepository: context.read<SettingsRepository>(),
        demos: context.read<ExerciseDemos>(),
      ),
      child: PopScope(
        // On first launch there is no dashboard behind this page, so a swipe
        // back would land the user on an empty app.
        //
        // This gates *user-initiated* pops only. The exit below uses `pop`
        // rather than `maybePop` precisely because `maybePop` asks this
        // `PopScope` for permission and is refused — which left the first-run
        // import stuck on screen after a successful save.
        canPop: canPop,
        child: GimmyScaffold(
          label: 'Import plan',
          sidebarItem: SidebarItem.import,
          onSidebarSelect: onSidebarSelect,
          sidebarFooter: const SidebarStats(),
          leading: canPop
              ? BackButton(onPressed: () => Navigator.of(context).pop(false))
              : null,
          child: ImportPage(
            onImported: () => Navigator.of(context).pop(true),
            // Can't pop means there is no plan behind this page.
            offerSample: !canPop,
          ),
        ),
      ),
    );
  }
}
