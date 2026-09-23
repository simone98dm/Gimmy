part of 'heart_rate_bloc.dart';

sealed class HeartRateEvent extends Equatable {
  const HeartRateEvent();

  @override
  List<Object?> get props => const [];
}

/// The paired sensor changed — at launch, on pairing, on forgetting, on a
/// wipe. Null drops the connection.
class HeartRateMonitorChanged extends HeartRateEvent {
  const HeartRateMonitorChanged(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

class HeartRateScanRequested extends HeartRateEvent {
  const HeartRateScanRequested();
}

class HeartRateScanStopped extends HeartRateEvent {
  const HeartRateScanStopped();
}

class _HeartRateReceived extends HeartRateEvent {
  const _HeartRateReceived(this.bpm);

  final int? bpm;

  @override
  List<Object?> get props => [bpm];
}

class _NearbyUpdated extends HeartRateEvent {
  const _NearbyUpdated(this.nearby);

  final List<NearbyMonitor> nearby;

  @override
  List<Object?> get props => [nearby];
}

class _ScanningChanged extends HeartRateEvent {
  const _ScanningChanged(this.isScanning);

  final bool isScanning;

  @override
  List<Object?> get props => [isScanning];
}
