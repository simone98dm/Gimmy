---
name: flutter
description: Foundations for building a standalone Flutter project from scratch — project setup, feature-based structure, Riverpod state management, go_router navigation, Material 3 theming, widget testing. Use for any Flutter or Dart mobile app task.
---

# Flutter Foundations

## Project Setup

```bash
flutter create --org com.simone98dm --platforms ios,android my_app
cd my_app
flutter pub add flutter_riverpod go_router
flutter pub add --dev flutter_lints
```

- Dart SDK constraint from `flutter --version`; commit `pubspec.lock` for apps.
- `analysis_options.yaml`: keep `flutter_lints`, treat warnings as errors in CI (`flutter analyze --fatal-infos`).

## Structure (feature-first)

```
lib/
├── main.dart              # bootstrap only: ProviderScope + App
├── app/
│   ├── app.dart           # MaterialApp.router + theme
│   ├── router.dart        # go_router config
│   └── theme.dart         # Material 3 theme
├── features/
│   └── items/
│       ├── data/          # repositories, DTOs, API clients
│       ├── domain/        # models (plain Dart)
│       └── presentation/  # screens, widgets, providers
└── shared/
    ├── widgets/           # reusable UI
    └── utils/
```

Rule: features don't import each other's `presentation/`; cross-feature access goes through `domain`/`data`.

## State — Riverpod

```dart
// presentation/providers/items_provider.dart
final itemsRepositoryProvider = Provider((ref) => ItemsRepository());

final itemsProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  return ref.watch(itemsRepositoryProvider).fetchItems();
});

// in a widget
class ItemsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider);
    return items.when(
      data: (list) => ItemsList(items: list),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorRetry(onRetry: () => ref.invalidate(itemsProvider)),
    );
  }
}
```

- `Provider` for dependencies, `FutureProvider` for async reads, `NotifierProvider`/`AsyncNotifierProvider` for mutable state with actions.
- `autoDispose` by default; opt out only for genuinely app-lifetime state.
- No business logic in widgets — widgets watch providers and render.
- `AsyncValue.when` forces handling loading/error/data — always use it, never `.value!`.

## Navigation — go_router

```dart
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/items/:id',
      builder: (_, state) => ItemScreen(id: state.pathParameters['id']!),
    ),
  ],
);
```

- Path parameters over passing objects; screens load their own data by ID (deep-link safe).
- Auth guards via `redirect:` reading a provider, not per-screen checks.

## Theming — Material 3

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
)
```

- One seed color; use `Theme.of(context).colorScheme.primary` etc. — never hardcode colors in widgets.
- Dark mode free via `darkTheme: ... brightness: Brightness.dark` + `themeMode: ThemeMode.system`.
- Spacing: constant scale (4/8/12/16/24/32) in one place (`shared/utils/spacing.dart`).

## Testing

```dart
// test/features/items/items_screen_test.dart
testWidgets('shows items after load', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itemsRepositoryProvider.overrideWithValue(FakeItemsRepository()),
      ],
      child: const MaterialApp(home: ItemsScreen()),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.text('Test Item'), findsOneWidget);
});
```

- Override providers with fakes at `ProviderScope` — never hit real APIs in tests.
- Unit-test domain/data with plain `test()`; widget-test screens for the loading/error/data triple.
- `flutter test` in CI alongside `flutter analyze`.

## Checklist

- [ ] Feature-first structure, logic out of widgets
- [ ] Every async UI handles loading/error/data via `AsyncValue.when`
- [ ] Colors/spacing from theme, never inline
- [ ] Routes deep-link safe (ID params, self-loading screens)
- [ ] Provider overrides in tests, no real network
