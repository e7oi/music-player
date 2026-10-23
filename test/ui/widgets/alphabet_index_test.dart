import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';

void main() {
  /// @verifies FR-010.4
  group('alphabetKey', () {
    test('uses the upper-case first letter', () {
      expect(alphabetKey('Aube sur le fleuve'), 'A');
      expect(alphabetKey('zebra'), 'Z');
    });

    test('folds accents and case', () {
      expect(alphabetKey('Écris-moi'), 'E');
      expect(alphabetKey('ça va'), 'C');
      expect(alphabetKey('Ørsted'), 'O');
      expect(alphabetKey('Ñandú'), 'N');
      expect(alphabetKey('œuvre'), 'O');
      expect(alphabetKey('Ångström'), 'A');
    });

    test('groups digits and symbols under #', () {
      expect(alphabetKey('01 - piste sans titre.flac'), '#');
      expect(alphabetKey('"Nemesis"'), '#');
      expect(alphabetKey('(Secret)'), '#');
      expect(alphabetKey('  '), '#');
      expect(alphabetKey(''), '#');
    });

    test('does not skip articles', () {
      expect(alphabetKey('The Cranberries'), 'T');
      expect(alphabetKey('Les Ogres'), 'L');
    });

    test('non Latin letters fall under #', () {
      expect(alphabetKey('東京'), '#');
    });
  });

  group('letters', () {
    test('counts every group and lists # then A to Z', () {
      final letters = buildLetters(['Aube', 'Ami', 'Zèbre', '01', '(x)']);

      expect(letters.map((l) => l.label), [
        '#',
        ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
      ]);
      int count(String label) =>
          letters.firstWhere((l) => l.label == label).count;
      expect(count('#'), 2);
      expect(count('A'), 2);
      expect(count('Z'), 1);
      expect(count('B'), 0);
    });

    test('firstIndexes gives the first position of each letter', () {
      final index = firstIndexes(['(x)', 'Aube', 'Ami', 'Zèbre']);

      expect(index, {'#': 0, 'A': 1, 'Z': 3});
    });
  });

  /// @verifies FR-010.4
  group('magnifier', () {
    const magnifier = AlphabetMagnifier(
      base: 11,
      max: 26,
      shiftMax: 34,
      influence: 2,
    );

    test('is largest under the finger and shrinks with the distance', () {
      expect(magnifier.size(0), 26);
      expect(magnifier.shift(0), 34);
      expect(magnifier.size(1), closeTo(18, 1));
      expect(magnifier.shift(1), closeTo(16, 3));
      expect(magnifier.size(2), closeTo(14, 1));
      expect(magnifier.shift(2), closeTo(7, 1.5));
      expect(magnifier.size(5), 11);
      expect(magnifier.shift(5), 0);
    });

    test('changes continuously, never by steps', () {
      var previous = magnifier.size(0);
      for (var d = 0.1; d <= 4; d += 0.1) {
        final now = magnifier.size(d);
        expect(now, lessThanOrEqualTo(previous));
        expect(previous - now, lessThan(3));
        previous = now;
      }
    });

    test('is symmetric around the finger', () {
      expect(magnifier.size(-1.3), magnifier.size(1.3));
    });
  });

  group('letterAt', () {
    final letters = buildLetters(['Aube', 'Mia', 'Zèbre']);
    const height = 270.0; // 27 letters, 10 dp each

    test('maps the finger position to the nearest letter with items', () {
      expect(letterAt(letters, 2, height), 'A');
      expect(letterAt(letters, height - 2, height), 'Z');
    });

    test('skips empty letters', () {
      // Over "G": the nearest letters with items are A (6 away) and M (6).
      final label = letterAt(letters, 7.5 * 10, height);
      expect(['A', 'M'], contains(label));
      // Over "N" the nearest is M.
      expect(letterAt(letters, 14.5 * 10, height), 'M');
    });

    test('clamps outside the column', () {
      expect(letterAt(letters, -50, height), 'A');
      expect(letterAt(letters, height + 50, height), 'Z');
    });

    test('returns null when nothing has items', () {
      expect(letterAt(buildLetters(const []), 10, height), isNull);
    });
  });
}
