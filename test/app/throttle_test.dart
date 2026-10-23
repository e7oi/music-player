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
}
