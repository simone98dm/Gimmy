import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/gimmy_card.dart';
import '../../../data/exercises/exercise_catalog.dart';
import '../../../data/exercises/exercise_demos.dart';
import '../../../data/exercises/exercise_media_store.dart';
import '../../../data/models/plan.dart';
import '../bloc/import_bloc.dart';

/// The demo each exercise of the previewed plan will show in the runner,
/// one row per exercise, each changeable before the plan is saved.
class ExerciseDemosCard extends StatelessWidget {
  const ExerciseDemosCard({super.key, required this.plan, this.enabled = true});

  final Plan plan;

  /// False while saving, so a choice cannot land after the plan is written.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final names = plan.exerciseNames;
    if (names.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tokens = GimmyTokens.of(context);

    return FutureBuilder(
      future: context.read<ExerciseDemos>().catalog(),
      builder: (context, snapshot) {
        final catalog = snapshot.data;
        if (catalog == null) return const SizedBox.shrink();

        return GimmyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Exercise demos', style: theme.textTheme.titleMedium),
              const SizedBox(height: GimmySpacing.xxs),
              Text(
                'Shown next to the timer during the workout.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: GimmySpacing.sm),
              for (final name in names)
                _DemoRow(
                  stepName: name,
                  entry: _entryFor(name, catalog),
                  catalog: catalog,
                  enabled: enabled,
                ),
              const SizedBox(height: GimmySpacing.sm),
              Text(
                'Demos ${AppConfig.exerciseMediaCredit}',
                style: tokens.labelMono.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  CatalogEntry? _entryFor(String name, ExerciseCatalog catalog) {
    final id = plan.steps.firstWhere((s) => s.name == name).exerciseId;
    return id == null ? null : catalog.byId(id);
  }
}

class _DemoRow extends StatelessWidget {
  const _DemoRow({
    required this.stepName,
    required this.entry,
    required this.catalog,
    required this.enabled,
  });

  final String stepName;
  final CatalogEntry? entry;
  final ExerciseCatalog catalog;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = this.entry;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GimmySpacing.xs),
      child: Row(
        children: [
          _Thumbnail(entry: entry),
          const SizedBox(width: GimmySpacing.ms),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stepName, style: theme.textTheme.bodyLarge),
                Text(
                  entry?.name ?? 'No demo',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: enabled ? () => _change(context) : null,
            child: Semantics(
              label: 'Change the demo for $stepName',
              excludeSemantics: true,
              child: const Text('Change'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _change(BuildContext context) async {
    final bloc = context.read<ImportBloc>();
    final pick = await showExercisePickerSheet(
      context,
      stepName: stepName,
      currentId: entry?.id,
      catalog: catalog,
    );
    if (pick == null) return;
    bloc.add(ImportExerciseChanged(name: stepName, exerciseId: pick.id));
  }
}

/// The still of the chosen demo. Nothing is downloaded before the plan is
/// saved, so it comes straight from the network, and a failure shows the
/// same placeholder as no demo at all.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.entry});

  final CatalogEntry? entry;

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    final tokens = GimmyTokens.of(context);
    final placeholder = Icon(
      Icons.fitness_center,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final entry = this.entry;

    return ClipRRect(
      borderRadius: GimmyRadii.cell,
      child: ColoredBox(
        color: tokens.insetSurface,
        child: SizedBox.square(
          dimension: _size,
          child: entry == null
              ? placeholder
              : Image.network(
                  exerciseMediaUri(entry.image).toString(),
                  fit: BoxFit.cover,
                  semanticLabel: entry.name,
                  errorBuilder: (_, _, _) => placeholder,
                ),
        ),
      ),
    );
  }
}

/// Lets the user pick the demo for [stepName]. Null when dismissed; a
/// record with a null id when they chose "No demo".
Future<({String? id})?> showExercisePickerSheet(
  BuildContext context, {
  required String stepName,
  required String? currentId,
  required ExerciseCatalog catalog,
}) {
  return showModalBottomSheet<({String? id})>(
    context: context,
    routeSettings: const RouteSettings(name: 'exercise-picker sheet'),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ExercisePicker(
      stepName: stepName,
      currentId: currentId,
      catalog: catalog,
    ),
  );
}

class _ExercisePicker extends StatefulWidget {
  const _ExercisePicker({
    required this.stepName,
    required this.currentId,
    required this.catalog,
  });

  final String stepName;
  final String? currentId;
  final ExerciseCatalog catalog;

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  // Starts on the step's own name: the likely candidates are right there.
  late final _query = TextEditingController(
    text: widget.stepName.toLowerCase(),
  );

  static const double _sheetHeightFactor = 0.85;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<CatalogEntry> _matches() {
    final words = _query.text
        .toLowerCase()
        .split(' ')
        .where((w) => w.isNotEmpty);
    return [
      for (final entry in widget.catalog.entries)
        if (words.every(entry.name.contains)) entry,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final matches = _matches();

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * _sheetHeightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GimmySpacing.md),
            child: Text(
              'Demo for ${widget.stepName}',
              style: theme.textTheme.headlineSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(GimmySpacing.md),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search exercises',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: matches.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _PickerTile(
                    title: 'No demo',
                    subtitle: 'Show the timer only',
                    isSelected: widget.currentId == null,
                    onTap: () => Navigator.of(context).pop((id: null)),
                  );
                }
                final entry = matches[index - 1];
                return _PickerTile(
                  title: entry.name,
                  subtitle: entry.equipment,
                  isSelected: entry.id == widget.currentId,
                  onTap: () => Navigator.of(context).pop((id: entry.id)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
