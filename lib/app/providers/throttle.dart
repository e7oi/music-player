/// Passes at most one event of [source] per [interval]. An event for which
/// [always] is true (the end of a progress, say) is never dropped.
Stream<T> throttle<T>(
  Stream<T> source,
  Duration interval, {
  bool Function(T event)? always,
}) async* {
  final clock = Stopwatch();
  await for (final event in source) {
    final forced = always?.call(event) ?? false;
    if (forced || !clock.isRunning || clock.elapsed >= interval) {
      yield event;
      clock
        ..reset()
        ..start();
    }
  }
}
