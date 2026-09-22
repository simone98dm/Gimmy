import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show ThemeMode;

/// Everything the user can change, persisted locally.
///
/// The metric feature flags are deliberately *not* here: they live in
/// `FeatureFlags` as compile-time constants, which is what "off by default, all
/// in one config file" asks for. Putting them in settings would mean shipping a
/// switch for UI that has no data behind it yet.
class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColor,
    this.activePlanId,
  });

  /// Applies immediately when changed. Defaults to following the OS.
  final ThemeMode themeMode;

  /// Phase 3. Stored so the choice survives the feature landing; the Settings
  /// page shows the control disabled until then.
  final String? accentColor;

  /// The plan the Dashboard starts. Null until the first successful import.
  final String? activePlanId;

  bool get hasActivePlan => activePlanId != null;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    if (accentColor != null) 'accentColor': accentColor,
    if (activePlanId != null) 'activePlanId': activePlanId,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final mode = json['themeMode'] as String?;
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (v) => v.name == mode,
        // A settings file written by a newer build should not brick the app.
        orElse: () => ThemeMode.system,
      ),
      accentColor: json['accentColor'] as String?,
      activePlanId: json['activePlanId'] as String?,
    );
  }

  /// `copyWith` cannot clear a nullable field, so clearing is explicit.
  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentColor,
    String? activePlanId,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      activePlanId: activePlanId ?? this.activePlanId,
    );
  }

  AppSettings withoutActivePlan() =>
      AppSettings(themeMode: themeMode, accentColor: accentColor);

  @override
  List<Object?> get props => [themeMode, accentColor, activePlanId];
}
