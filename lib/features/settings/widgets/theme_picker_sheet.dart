import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/bloc/app_bloc.dart';
import '../../../core/theme/gimmy_colors.dart';
import '../../../core/theme/gimmy_theme_id.dart';
import '../../../core/theme/gimmy_tokens.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/pressable_scale.dart';

/// Picks the color theme applied on top of light/dark. Applies immediately.
Future<void> showThemePicker(BuildContext context) {
  return showModalBottomSheet<void>(
    routeSettings: const RouteSettings(name: 'theme picker'),
    context: context,
    builder: (_) => const ThemePickerSheet(),
  );
}

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = context.select(
      (AppBloc bloc) => bloc.state.settings.themeId,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GimmySpacing.md,
          0,
          GimmySpacing.md,
          GimmySpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme', style: theme.textTheme.headlineSmall),
            const SizedBox(height: GimmySpacing.md),
            for (final id in GimmyThemeId.values) ...[
              _ThemeOption(id: id, isSelected: id == selected),
              if (id != GimmyThemeId.values.last)
                const SizedBox(height: GimmySpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.id, required this.isSelected});

  final GimmyThemeId id;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The preview swatches come from the theme being previewed, not the one
    // currently applied — that's the whole point of a picker.
    final previewScheme = gimmyColorsFor(id, theme.brightness).scheme;

    void select() {
      context.read<AppBloc>().add(AppThemeChanged(id));
      Navigator.of(context).pop();
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label: id.label,
      excludeSemantics: true,
      child: PressableScale(
        child: Material(
          color: isSelected
              ? theme.colorScheme.surfaceContainerHighest
              : GimmyTokens.of(context).insetSurface,
          borderRadius: GimmyRadii.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: select,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: GimmyLayout.minTapTarget,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: GimmySpacing.md,
                vertical: GimmySpacing.sm,
              ),
              child: Row(
                children: [
                  _Swatch(color: previewScheme.primaryContainer),
                  const SizedBox(width: GimmySpacing.xs),
                  _Swatch(color: previewScheme.secondaryContainer),
                  const SizedBox(width: GimmySpacing.xs),
                  _Swatch(color: previewScheme.tertiaryContainer),
                  const SizedBox(width: GimmySpacing.sm),
                  Expanded(
                    child: Text(
                      id.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  else
                    const SizedBox(width: GimmySpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
