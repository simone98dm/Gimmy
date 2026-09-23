part of 'heart_rate_bloc.dart';

enum HeartRateLink {
  /// Nothing paired.
  none,

  /// Paired, but no reading yet — out of range, switched off, or not
  /// broadcasting. The OS keeps looking.
  connecting,

  /// Readings are arriving.
  live,
}

class HeartRateState extends Equatable {
  const HeartRateState({
    this.link = HeartRateLink.none,
    this.bpm,
    this.nearby = const [],
    this.isScanning = false,
    this.scanError,
  });

  final HeartRateLink link;

  /// The latest reading, null unless [link] is [HeartRateLink.live].
  final int? bpm;

  /// What the last scan found, strongest signal first.
  final List<NearbyMonitor> nearby;
  final bool isScanning;

  /// Why the last scan could not start: Bluetooth off, permission refused.
  final String? scanError;

  HeartRateState copyWith({
    HeartRateLink? link,
    int? Function()? bpm,
    List<NearbyMonitor>? nearby,
    bool? isScanning,
    String? Function()? scanError,
  }) {
    return HeartRateState(
      link: link ?? this.link,
      bpm: bpm == null ? this.bpm : bpm(),
      nearby: nearby ?? this.nearby,
      isScanning: isScanning ?? this.isScanning,
      scanError: scanError == null ? this.scanError : scanError(),
    );
  }

  @override
  List<Object?> get props => [link, bpm, nearby, isScanning, scanError];
}
