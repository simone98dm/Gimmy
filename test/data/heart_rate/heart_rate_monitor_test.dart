import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/heart_rate/heart_rate_monitor.dart';

void main() {
  group('parseHeartRate', () {
    test('reads a one-byte BPM when flag bit 0 is clear', () {
      expect(parseHeartRate([0x00, 72]), 72);
    });

    test('reads a little-endian uint16 BPM when flag bit 0 is set', () {
      expect(parseHeartRate([0x01, 0x2C, 0x01]), 300);
    });

    test('ignores the RR intervals and energy fields that follow', () {
      // Flags: uint8 BPM, energy expended present, RR intervals present.
      expect(parseHeartRate([0x18, 64, 0x10, 0x00, 0x00, 0x04]), 64);
    });

    test('returns null for a value too short to hold a reading', () {
      expect(parseHeartRate([]), isNull);
      expect(parseHeartRate([0x00]), isNull);
      expect(parseHeartRate([0x01, 0x2C]), isNull);
    });
  });

  group('NearbyMonitor.signalPercent', () {
    NearbyMonitor at(int rssi) => NearbyMonitor(id: 'x', name: 'x', rssi: rssi);

    test('maps −100 dBm to 0% and −50 dBm or stronger to 100%', () {
      expect(at(-100).signalPercent, 0);
      expect(at(-76).signalPercent, 48);
      expect(at(-50).signalPercent, 100);
      expect(at(-30).signalPercent, 100);
      expect(at(-120).signalPercent, 0);
    });
  });
}
