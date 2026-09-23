import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'heart_rate_monitor.dart';

/// [HeartRateMonitor] over Bluetooth LE, using the standard Heart Rate
/// Service.
///
/// Garmin exposes nothing else to third-party apps without the Connect IQ SDK:
/// a watch only advertises this service while "Broadcast Heart Rate" is on, and
/// an HRM strap advertises it whenever it is worn.
class BleHeartRateMonitor implements HeartRateMonitor {
  static final Guid _heartRateService = Guid('180d');
  static final Guid _heartRateMeasurement = Guid('2a37');

  static const Duration _scanTimeout = Duration(seconds: 15);

  @override
  Stream<List<NearbyMonitor>> get nearby => FlutterBluePlus.scanResults.map(
    (results) => [
      for (final result in results)
        NearbyMonitor(
          id: result.device.remoteId.str,
          name: _nameOf(result),
          rssi: result.rssi,
        ),
    ]..sort((a, b) => b.rssi.compareTo(a.rssi)),
  );

  @override
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  @override
  Future<void> startScan() async {
    final adapter = await FlutterBluePlus.adapterState
        .where((state) => state != BluetoothAdapterState.unknown)
        .first;
    if (adapter != BluetoothAdapterState.on) {
      throw StateError(switch (adapter) {
        BluetoothAdapterState.unauthorized =>
          'Bluetooth permission was refused',
        BluetoothAdapterState.unavailable => 'This device has no Bluetooth',
        _ => 'Bluetooth is off',
      });
    }
    await FlutterBluePlus.startScan(
      withServices: [_heartRateService],
      timeout: _scanTimeout,
    );
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  Stream<int?> watch(String id) {
    final device = BluetoothDevice.fromId(id);
    StreamSubscription<BluetoothConnectionState>? link;
    StreamSubscription<List<int>>? readings;
    late final StreamController<int?> controller;

    Future<void> subscribe() async {
      final services = await device.discoverServices();
      final measurement = services
          .where((s) => s.uuid == _heartRateService)
          .expand((s) => s.characteristics)
          .firstWhere((c) => c.uuid == _heartRateMeasurement);
      await readings?.cancel();
      readings = measurement.onValueReceived.listen((value) {
        final bpm = parseHeartRate(value);
        if (bpm != null) controller.add(bpm);
      });
      device.cancelWhenDisconnected(readings!);
      await measurement.setNotifyValue(true);
    }

    controller = StreamController<int?>(
      onListen: () {
        link = device.connectionState.listen((state) {
          if (state != BluetoothConnectionState.connected) {
            controller.add(null);
            return;
          }
          subscribe().catchError((Object error) {
            // A device without the heart-rate service, or one that dropped
            // mid-discovery. autoConnect will bring it back and retry.
            debugPrint('gimmy: heart-rate subscribe failed: $error');
          });
        });
        // License.nonprofit covers personal use only; a commercial release
        // of the app needs a FlutterBluePlus commercial license.
        // autoConnect never times out: the OS keeps looking for the device
        // and reconnects whenever it comes back in range.
        device
            .connect(license: License.nonprofit, autoConnect: true, mtu: null)
            .catchError((Object error) {
              debugPrint('gimmy: heart-rate connect failed: $error');
            });
      },
      onCancel: () async {
        await readings?.cancel();
        await link?.cancel();
        await device.disconnect();
      },
    );
    return controller.stream;
  }

  static String _nameOf(ScanResult result) {
    final advertised = result.advertisementData.advName;
    if (advertised.isNotEmpty) return advertised;
    final platform = result.device.platformName;
    return platform.isNotEmpty ? platform : 'Heart-rate sensor';
  }
}
