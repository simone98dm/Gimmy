/// One-second heartbeat for a running workout.
///
/// Injected rather than created inline so the execution bloc can be tested
/// without waiting in real time.
class Ticker {
  const Ticker();

  Stream<void> ticks() =>
      Stream<void>.periodic(const Duration(seconds: 1), (_) {});
}
