import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'document_store.dart';
import '../../core/logging/app_log.dart';

/// Opens [name] as a key in the browser's local storage.
DocumentStore openDocumentStore(String name) =>
    PreferencesDocumentStore('gimmy.$name');

/// A JSON document kept in `shared_preferences`, which on the web is backed by
/// `window.localStorage`.
///
/// There is no filesystem to write to and no partial-write to guard against:
/// a local-storage write either lands whole or does not happen.
class PreferencesDocumentStore implements DocumentStore {
  PreferencesDocumentStore(this.key, {SharedPreferences? preferences})
    : _injected = preferences;

  final String key;
  final SharedPreferences? _injected;
  SharedPreferences? _cached;

  Future<SharedPreferences> _prefs() async {
    final injected = _injected;
    if (injected != null) return injected;
    return _cached ??= await SharedPreferences.getInstance();
  }

  @override
  Future<Object?> read() async {
    final raw = (await _prefs()).getString(key);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      return jsonDecode(raw);
    } on FormatException catch (error) {
      AppLog.warning('storage', '$key holds invalid JSON, ignoring it', error);
      return null;
    }
  }

  @override
  Future<void> write(Object? document) async {
    await (await _prefs()).setString(key, jsonEncode(document));
  }

  @override
  Future<void> delete() async {
    await (await _prefs()).remove(key);
  }
}
