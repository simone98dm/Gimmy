import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gimmy/data/heart_rate/heart_rate_monitor.dart';
import 'package:gimmy/features/heart_rate/bloc/heart_rate_bloc.dart';

/// A [HeartRateMonitor] with no radio: tests push scan results and readings
/// through the controllers and inspect what was asked of it.
class FakeHeartRateMonitor implements HeartRateMonitor {
  final nearbyController = StreamController<List<NearbyMonitor>>.broadcast();
  final scanningController = StreamController<bool>.broadcast();
  final readings = StreamController<int?>.broadcast();

  /// Set to make [startScan] fail the way a phone with Bluetooth off does.
  Object? scanFailure;

  int scansStarted = 0;
  int scansStopped = 0;
  final List<String> watched = [];

  @override
  Stream<List<NearbyMonitor>> get nearby => nearbyController.stream;

  @override
  Stream<bool> get isScanning => scanningController.stream;

  @override
  Future<void> startScan() async {
    scansStarted++;
    final failure = scanFailure;
    if (failure != null) throw failure;
  }

  @override
  Future<void> stopScan() async => scansStopped++;

  @override
  Stream<int?> watch(String id) {
    watched.add(id);
    return readings.stream;
  }
}

/// Provides a [HeartRateBloc] over a [FakeHeartRateMonitor], for pages that
/// read it — Settings, and the metric strip on the Execution page.
Widget withHeartRate(Widget child, {HeartRateMonitor? monitor}) {
  return BlocProvider(
    create: (_) => HeartRateBloc(monitor: monitor ?? FakeHeartRateMonitor()),
    child: child,
  );
}
