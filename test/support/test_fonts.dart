import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the app's bundled fonts into the test binding.
///
/// Widget tests otherwise render every glyph as an identical box, which makes
/// goldens useless for judging layout and hides real overflow. Call this once
/// in `setUpAll` for any test that captures a golden.
Future<void> loadAppFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const families = {
    'Inter': [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-Medium.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
      'assets/fonts/Inter-Bold.ttf',
      'assets/fonts/Inter-ExtraBold.ttf',
    ],
    'JetBrains Mono': [
      'assets/fonts/JetBrainsMono-Medium.ttf',
      'assets/fonts/JetBrainsMono-SemiBold.ttf',
      'assets/fonts/JetBrainsMono-Bold.ttf',
    ],
  };

  await _loadMaterialIcons();

  for (final MapEntry(key: family, value: paths) in families.entries) {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}

/// Material's icon font ships inside the Flutter SDK rather than with the app,
/// so it has to be pulled from the SDK cache. Without it every icon in a golden
/// is an empty box.
Future<void> _loadMaterialIcons() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? _flutterRootFromDartExecutable();
  if (flutterRoot == null) return;

  final font = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!font.existsSync()) return;

  final bytes = font.readAsBytesSync();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
}

/// `flutter test` does not always export FLUTTER_ROOT, but the Dart binary
/// running the test lives inside the SDK.
String? _flutterRootFromDartExecutable() {
  final marker =
      '${Platform.pathSeparator}bin${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}dart-sdk';
  final index = Platform.resolvedExecutable.indexOf(marker);
  return index == -1 ? null : Platform.resolvedExecutable.substring(0, index);
}
