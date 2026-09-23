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
    this.heartRateMonitorId,
    this.heartRateMonitorName,
    this.areCuesEnabled = true,
  });

  /// Applies immediately when changed. Defaults to following the OS.
  final ThemeMode themeMode;

  /// Phase 3. Stored so the choice survives the feature landing; the Settings
  /// page shows the control disabled until then.
  final String? accentColor;

  /// The plan the Dashboard starts. Null until the first successful import.
  final String? activePlanId;

  /// The paired heart-rate sensor's platform id, reconnected to on launch.
  /// Null until one is paired.
  final String? heartRateMonitorId;

  /// Shown in Settings, so the row can name the device while it is offline.
  final String? heartRateMonitorName;

  /// The beep and vibration on every new step and at the finish.
  final bool areCuesEnabled;

  bool get hasActivePlan => activePlanId != null;

  bool get hasHeartRateMonitor => heartRateMonitorId != null;

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    if (accentColor != null) 'accentColor': accentColor,
    if (activePlanId != null) 'activePlanId': activePlanId,
    if (heartRateMonitorId != null) 'heartRateMonitorId': heartRateMonitorId,
    if (heartRateMonitorName != null)
      'heartRateMonitorName': heartRateMonitorName,
    'cuesEnabled': areCuesEnabled,
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
      heartRateMonitorId: json['heartRateMonitorId'] as String?,
      heartRateMonitorName: json['heartRateMonitorName'] as String?,
      // Absent in settings saved before the toggle existed, when cues were on.
      areCuesEnabled: json['cuesEnabled'] as bool? ?? true,
    );
  }

  /// `copyWith` cannot clear a nullable field, so clearing is explicit.
  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentColor,
    String? activePlanId,
    String? heartRateMonitorId,
    String? heartRateMonitorName,
    bool? areCuesEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      activePlanId: activePlanId ?? this.activePlanId,
      heartRateMonitorId: heartRateMonitorId ?? this.heartRateMonitorId,
      heartRateMonitorName: heartRateMonitorName ?? this.heartRateMonitorName,
      areCuesEnabled: areCuesEnabled ?? this.areCuesEnabled,
    );
  }

  AppSettings withoutActivePlan() => AppSettings(
    themeMode: themeMode,
    accentColor: accentColor,
    heartRateMonitorId: heartRateMonitorId,
    heartRateMonitorName: heartRateMonitorName,
    areCuesEnabled: areCuesEnabled,
  );

  AppSettings withoutHeartRateMonitor() => AppSettings(
    themeMode: themeMode,
    accentColor: accentColor,
    activePlanId: activePlanId,
    areCuesEnabled: areCuesEnabled,
  );

  @override
  List<Object?> get props => [
    themeMode,
    accentColor,
    activePlanId,
    heartRateMonitorId,
    heartRateMonitorName,
    areCuesEnabled,
  ];
}
