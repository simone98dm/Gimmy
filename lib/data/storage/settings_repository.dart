import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../../core/logging/app_log.dart';

/// Stores the user's settings in `shared_preferences`, as one JSON blob.
///
/// One key rather than a key per field: settings are always read and written
/// together, and a single value cannot go half-updated.
class SettingsRepository {
  SettingsRepository({SharedPreferences? preferences})
    : _injected = preferences;

  static const String storageKey = 'gimmy.settings';

  final SharedPreferences? _injected;
  SharedPreferences? _cached;

  Future<SharedPreferences> _prefs() async {
    final injected = _injected;
    if (injected != null) return injected;
    return _cached ??= await SharedPreferences.getInstance();
  }

  Future<AppSettings> load() async {
    final raw = (await _prefs()).getString(storageKey);
    if (raw == null) return const AppSettings();

    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (error) {
      AppLog.warning('storage', 'settings unreadable, using defaults', error);
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    await (await _prefs()).setString(storageKey, jsonEncode(settings.toJson()));
  }

  Future<void> clear() async {
    await (await _prefs()).remove(storageKey);
  }
}
