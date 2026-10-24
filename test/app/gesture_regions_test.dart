import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/gesture_providers.dart';

void main() {
  late List<List<Rect>> sent;
  late GestureRegions regions;

  setUp(() {
    sent = [];
    regions = GestureRegions((rects) async => sent.add(rects));
  });

  const a = Rect.fromLTRB(0, 0, 10, 10);
  const b = Rect.fromLTRB(20, 20, 30, 30);

  /// @verifies ADR-016
  test('the rectangles of every owner are sent together', () async {
    await regions.set('tracks', [a]);
    await regions.set('albums', [b]);

    expect(sent.last, unorderedEquals([a, b]));
  });

  test('an owner that leaves takes only its own rectangles away', () async {
    await regions.set('tracks', [a]);
    await regions.set('albums', [b]);

    await regions.set('tracks', const []);

    expect(sent.last, [b]);
  });

  test('an owner that reports again replaces its rectangles', () async {
    await regions.set('tracks', [a]);

    await regions.set('tracks', [b]);

    expect(sent.last, [b]);
  });

  test('without any owner, the whole edge goes back to the system', () async {
    await regions.set('tracks', [a]);

    await regions.set('tracks', const []);

    expect(sent.last, isEmpty);
  });
}
