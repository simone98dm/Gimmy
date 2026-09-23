import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/heart_rate/heart_rate_monitor.dart';

part 'heart_rate_event.dart';
part 'heart_rate_state.dart';

/// The live link to the paired heart-rate sensor, and the scan that finds one.
///
/// Which sensor is paired lives in `AppSettings`, owned by `AppBloc`; this bloc
/// is told about changes through [HeartRateMonitorChanged] and only owns what
/// is live: the connection, the latest BPM, and scan results.
class HeartRateBloc extends Bloc<HeartRateEvent, HeartRateState> {
  HeartRateBloc({required HeartRateMonitor monitor})
    : _monitor = monitor,
      super(const HeartRateState()) {
    on<HeartRateMonitorChanged>(_onMonitorChanged);
    on<_HeartRateReceived>(_onReceived);
    on<HeartRateScanRequested>(_onScanRequested);
    on<HeartRateScanStopped>(_onScanStopped);
    on<_NearbyUpdated>(
      (event, emit) => emit(state.copyWith(nearby: event.nearby)),
    );
    on<_ScanningChanged>(
      (event, emit) => emit(state.copyWith(isScanning: event.isScanning)),
    );
  }

  final HeartRateMonitor _monitor;

  String? _watchedId;
  StreamSubscription<int?>? _readings;
  StreamSubscription<List<NearbyMonitor>>? _nearby;
  StreamSubscription<bool>? _scanning;

  Future<void> _onMonitorChanged(
    HeartRateMonitorChanged event,
    Emitter<HeartRateState> emit,
  ) async {
    if (event.id == _watchedId) return;
    _watchedId = event.id;
    await _readings?.cancel();
    _readings = null;

    final id = event.id;
    if (id == null) {
      emit(state.copyWith(link: HeartRateLink.none, bpm: () => null));
      return;
    }
    emit(state.copyWith(link: HeartRateLink.connecting, bpm: () => null));
    _readings = _monitor
        .watch(id)
        .listen(
          (bpm) => add(_HeartRateReceived(bpm)),
          onError: (Object error) =>
              debugPrint('gimmy: heart-rate stream failed: $error'),
        );
  }

  void _onReceived(_HeartRateReceived event, Emitter<HeartRateState> emit) {
    // A reading already in flight when the sensor was forgotten.
    if (_watchedId == null) return;
    emit(
      state.copyWith(
        link: event.bpm == null ? HeartRateLink.connecting : HeartRateLink.live,
        bpm: () => event.bpm,
      ),
    );
  }

  Future<void> _onScanRequested(
    HeartRateScanRequested event,
    Emitter<HeartRateState> emit,
  ) async {
    emit(state.copyWith(nearby: const [], scanError: () => null));
    _nearby ??= _monitor.nearby.listen((found) => add(_NearbyUpdated(found)));
    _scanning ??= _monitor.isScanning.listen(
      (isScanning) => add(_ScanningChanged(isScanning)),
    );
    try {
      await _monitor.startScan();
    } on Object catch (error) {
      emit(state.copyWith(isScanning: false, scanError: () => _reason(error)));
    }
  }

  Future<void> _onScanStopped(
    HeartRateScanStopped event,
    Emitter<HeartRateState> emit,
  ) async {
    await _monitor.stopScan();
  }

  static String _reason(Object error) =>
      error is StateError ? error.message : 'Could not start scanning';

  @override
  Future<void> close() async {
    await _readings?.cancel();
    await _nearby?.cancel();
    await _scanning?.cancel();
    return super.close();
  }
}
