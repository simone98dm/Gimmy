import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/data/heart_rate/heart_rate_monitor.dart';
import 'package:gimmy/features/heart_rate/bloc/heart_rate_bloc.dart';

import '../../support/fake_heart_rate_monitor.dart';

void main() {
  late FakeHeartRateMonitor monitor;
  late HeartRateBloc bloc;

  setUp(() {
    monitor = FakeHeartRateMonitor();
    bloc = HeartRateBloc(monitor: monitor);
  });

  tearDown(() => bloc.close());

  group('the paired sensor', () {
    test(
      'connects when one is paired and goes live on the first reading',
      () async {
        bloc.add(const HeartRateMonitorChanged('AA:BB'));
        await pumpEventQueue();

        expect(monitor.watched, ['AA:BB']);
        expect(bloc.state.link, HeartRateLink.connecting);

        monitor.readings.add(72);
        await pumpEventQueue();

        expect(bloc.state.link, HeartRateLink.live);
        expect(bloc.state.bpm, 72);
      },
    );

    test(
      'falls back to connecting, without a stale BPM, when the link drops',
      () async {
        bloc.add(const HeartRateMonitorChanged('AA:BB'));
        await pumpEventQueue();
        monitor.readings.add(72);
        await pumpEventQueue();

        monitor.readings.add(null);
        await pumpEventQueue();

        expect(bloc.state.link, HeartRateLink.connecting);
        expect(bloc.state.bpm, isNull);
      },
    );

    test('disconnects and ignores late readings once forgotten', () async {
      bloc.add(const HeartRateMonitorChanged('AA:BB'));
      await pumpEventQueue();
      monitor.readings.add(72);
      await pumpEventQueue();

      bloc.add(const HeartRateMonitorChanged(null));
      await pumpEventQueue();
      monitor.readings.add(80);
      await pumpEventQueue();

      expect(bloc.state.link, HeartRateLink.none);
      expect(bloc.state.bpm, isNull);
      expect(monitor.readings.hasListener, isFalse);
    });

    test('does not reconnect when told about the same sensor again', () async {
      bloc
        ..add(const HeartRateMonitorChanged('AA:BB'))
        ..add(const HeartRateMonitorChanged('AA:BB'));
      await pumpEventQueue();

      expect(monitor.watched, ['AA:BB']);
    });
  });

  group('scanning', () {
    test('collects what the monitor finds', () async {
      bloc.add(const HeartRateScanRequested());
      await pumpEventQueue();
      monitor.scanningController.add(true);
      monitor.nearbyController.add(const [
        NearbyMonitor(id: '1', name: 'Forerunner 965', rssi: -56),
      ]);
      await pumpEventQueue();

      expect(monitor.scansStarted, 1);
      expect(bloc.state.isScanning, isTrue);
      expect(bloc.state.nearby.single.name, 'Forerunner 965');
    });

    test('reports why a scan could not start', () async {
      monitor.scanFailure = StateError('Bluetooth is off');

      bloc.add(const HeartRateScanRequested());
      await pumpEventQueue();

      expect(bloc.state.scanError, 'Bluetooth is off');
      expect(bloc.state.isScanning, isFalse);
    });

    test('a new scan clears the previous results and error', () async {
      monitor.scanFailure = StateError('Bluetooth is off');
      bloc.add(const HeartRateScanRequested());
      await pumpEventQueue();

      monitor.scanFailure = null;
      bloc.add(const HeartRateScanRequested());
      await pumpEventQueue();

      expect(bloc.state.scanError, isNull);
      expect(bloc.state.nearby, isEmpty);
    });
  });
}
