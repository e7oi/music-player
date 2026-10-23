import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/throttle.dart';

void main() {
  /// @verifies FR-010.3 progress updates are at most four a second.
  test('lets one event through per interval', () async {
    final source = StreamController<int>();
    final seen = <int>[];
    final done = throttle(
      source.stream,
      const Duration(milliseconds: 100),
    ).forEach(seen.add);

    for (var i = 0; i < 5; i++) {
      source.add(i);
    }
    await Future<void>.delayed(const Duration(milliseconds: 150));
    source.add(5);
    await source.close();
    await done;

    expect(seen, [0, 5]);
  });

  test('never drops an event that must pass', () async {
    final source = StreamController<int>();
    final seen = <int>[];
    final done = throttle(
      source.stream,
      const Duration(seconds: 10),
      always: (event) => event < 0,
    ).forEach(seen.add);

    source
      ..add(1)
      ..add(2)
      ..add(-1);
    await source.close();
    await done;

    expect(seen, [1, -1]);
  });

  test('passes the first event at once', () async {
    final seen = await throttle(
      Stream.value(7),
      const Duration(seconds: 10),
    ).toList();

    expect(seen, [7]);
  });

  /// @verifies FR-011.11 the latest state is never lost.
  group('throttleLatest', () {
    test('passes the first event at once and holds the others', () async {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttleLatest(
        source.stream,
        const Duration(milliseconds: 100),
      ).listen(seen.add);

      source
        ..add(1)
        ..add(2)
        ..add(3);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(seen, [1]);
      await sub.cancel();
      await source.close();
    });

    test('sends the latest held event when the interval ends', () async {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttleLatest(
        source.stream,
        const Duration(milliseconds: 60),
      ).listen(seen.add);

      source
        ..add(1)
        ..add(2)
        ..add(3);
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(seen, [1, 3]);
      await sub.cancel();
      await source.close();
    });

    test('an event after a quiet interval goes through at once', () async {
      final source = StreamController<int>();
      final seen = <int>[];
      final sub = throttleLatest(
        source.stream,
        const Duration(milliseconds: 40),
      ).listen(seen.add);

      source.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      source.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(seen, [1, 2]);
      await sub.cancel();
      await source.close();
    });

    test('the end of the stream flushes the held event', () async {
      final seen = await throttleLatest(
        Stream.fromIterable([1, 2, 3]),
        const Duration(seconds: 10),
      ).toList();

      expect(seen, [1, 3]);
    });

    test('cancelling stops everything', () async {
      final source = StreamController<int>();
      final sub = throttleLatest(
        source.stream,
        const Duration(milliseconds: 20),
      ).listen((_) {});

      await sub.cancel();

      expect(source.hasListener, isFalse);
    });
  });
}
