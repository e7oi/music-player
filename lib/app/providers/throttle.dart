import 'dart:async';

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

/// Passes the first event at once, then at most one event per [interval], and
/// always the latest one: an event held back is sent when the interval ends,
/// so the last state is never lost (FR-011.11).
Stream<T> throttleLatest<T>(Stream<T> source, Duration interval) {
  late StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timer;
  T? pending;
  var hasPending = false;

  void release() {
    timer = null;
    if (!hasPending) return;
    final event = pending as T;
    pending = null;
    hasPending = false;
    controller.add(event);
    timer = Timer(interval, release);
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        (event) {
          if (timer == null) {
            controller.add(event);
            timer = Timer(interval, release);
          } else {
            pending = event;
            hasPending = true;
          }
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          if (hasPending) controller.add(pending as T);
          unawaited(controller.close());
        },
      );
    },
    onCancel: () {
      timer?.cancel();
      return subscription?.cancel();
    },
  );
  return controller.stream;
}
