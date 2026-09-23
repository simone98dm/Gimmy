import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/config/feature_flags.dart';

void main() {
  test('AppConfig.appVersion matches the version in pubspec.yaml', () {
    // release-please bumps both; this catches a hand edit to only one.
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version: ([0-9.]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);

    expect(AppConfig.appVersion, version);
  });
}
