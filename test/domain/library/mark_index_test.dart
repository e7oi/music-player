import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/domain/library/model/mark_index.dart';

void main() {
  /// @verifies FR-012.2
  group('nextFreeMarkIndex', () {
    test('starts at 0 for the first disk', () {
      expect(nextFreeMarkIndex(const []), 0);
    });

    test('takes the next index after consecutive ones', () {
      expect(nextFreeMarkIndex(const [0, 1, 2]), 3);
    });

    test('fills the smallest gap', () {
      expect(nextFreeMarkIndex(const [0, 2]), 1);
      expect(nextFreeMarkIndex(const [1]), 0);
      expect(nextFreeMarkIndex(const [0, 1, 3]), 2);
    });

    test('ignores order and repeats', () {
      expect(nextFreeMarkIndex(const [2, 0, 0, 1, 2]), 3);
    });

    test('never hands out an index twice', () {
      final used = <int>[];
      for (var i = 0; i < 12; i++) {
        used.add(nextFreeMarkIndex(used));
      }
      expect(used.toSet(), hasLength(12));
      expect(used, [for (var i = 0; i < 12; i++) i]);
    });
  });
}
