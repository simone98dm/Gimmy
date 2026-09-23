import 'package:equatable/equatable.dart';

/// A heart-rate sensor seen in a scan: a Garmin watch broadcasting its wrist
/// heart rate, a Garmin HRM strap, or any other strap speaking the standard
/// Bluetooth Heart Rate profile.
class NearbyMonitor extends Equatable {
  const NearbyMonitor({
    required this.id,
    required this.name,
    required this.rssi,
  });

  /// The platform's handle for the device: a MAC address on Android, a
  /// per-phone UUID on iOS. Stable across launches, which is what lets the app
  /// reconnect without scanning.
  final String id;

  final String name;

  /// Received signal strength in dBm, roughly −100 (barely there) to −40.
  final int rssi;

  /// [rssi] as the 0–100 figure the pairing sheet shows.
  int get signalPercent => ((rssi + 100) * 2).clamp(0, 100);

  @override
  List<Object?> get props => [id, name, rssi];
}

/// The Bluetooth side of heart rate, kept behind an interface so the bloc and
/// the pairing sheet can be tested without a radio.
abstract interface class HeartRateMonitor {
  /// Every heart-rate sensor seen since the last [startScan], strongest first.
  Stream<List<NearbyMonitor>> get nearby;

  Stream<bool> get isScanning;

  /// Throws when Bluetooth is off or permission was refused.
  Future<void> startScan();

  Future<void> stopScan();

  /// Connects to [id] and emits its heart rate in BPM, or `null` while the
  /// link is down. Keeps reconnecting on its own until the subscription is
  /// cancelled, which disconnects.
  Stream<int?> watch(String id);
}

/// Decodes a Heart Rate Measurement characteristic (0x2A37) value.
///
/// Bit 0 of the flags byte says whether the BPM that follows is one byte or a
/// little-endian `uint16`. Everything after it (energy expended, RR intervals)
/// is ignored. Returns null for a value too short to hold a reading.
int? parseHeartRate(List<int> value) {
  if (value.length < 2) return null;
  final isUint16 = value[0] & 0x01 == 1;
  if (!isUint16) return value[1];
  if (value.length < 3) return null;
  return value[1] | (value[2] << 8);
}
