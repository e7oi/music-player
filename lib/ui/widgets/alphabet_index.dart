import 'dart:math' as math;

/// One entry of the alphabet index: "#" or a letter, with its item count.
class AlphabetLetter {
  const new({required this.label, required this.count});

  final String label;

  /// Items under this letter; a letter without items is greyed and skipped.
  final int count;

  bool get hasItems => count > 0;
}

const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// Accented Latin letters folded to their base letter (FR-010.4).
const _folded = {
  'À': 'A',
  'Á': 'A',
  'Â': 'A',
  'Ã': 'A',
  'Ä': 'A',
  'Å': 'A',
  'Ā': 'A',
  'Æ': 'A',
  'Ç': 'C',
  'Ć': 'C',
  'Č': 'C',
  'Ď': 'D',
  'È': 'E',
  'É': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Ē': 'E',
  'Ě': 'E',
  'Ì': 'I',
  'Í': 'I',
  'Î': 'I',
  'Ï': 'I',
  'Ī': 'I',
  'Ł': 'L',
  'Ñ': 'N',
  'Ń': 'N',
  'Ň': 'N',
  'Ò': 'O',
  'Ó': 'O',
  'Ô': 'O',
  'Õ': 'O',
  'Ö': 'O',
  'Ø': 'O',
  'Ō': 'O',
  'Œ': 'O',
  'Ř': 'R',
  'Ś': 'S',
  'Š': 'S',
  'ß': 'S',
  'Ť': 'T',
  'Ù': 'U',
  'Ú': 'U',
  'Û': 'U',
  'Ü': 'U',
  'Ū': 'U',
  'Ů': 'U',
  'Ý': 'Y',
  'Ÿ': 'Y',
  'Ź': 'Z',
  'Ž': 'Z',
  'Ż': 'Z',
};

/// The group of [text]: its first letter upper-cased with accents folded,
/// or "#" for digits, symbols, other scripts and empty text. Articles are not
/// skipped (v1).
String alphabetKey(String text) {
  final trimmed = text.trimLeft();
  if (trimmed.isEmpty) return '#';
  final first = String.fromCharCode(trimmed.runes.first).toUpperCase();
  final folded = _folded[first] ?? first;
  return _letters.contains(folded) && folded.length == 1 ? folded : '#';
}

/// A key that sorts [text] without regard to case or accents: the folded
/// letters first (digits, symbols and other scripts under "#" come before
/// any letter, as the "#" group leads the index).
String sortKey(String text) {
  final folded = StringBuffer();
  for (final rune in text.trimLeft().runes) {
    final char = String.fromCharCode(rune);
    final upper = char.toUpperCase();
    folded.write((_folded[upper] ?? upper).toLowerCase());
  }
  final group = alphabetKey(text) == '#' ? '0' : '1';
  return '$group$folded';
}

/// "#" then A to Z, each with the number of [titles] that fall under it.
List<AlphabetLetter> buildLetters(Iterable<String> titles) {
  final counts = <String, int>{};
  for (final title in titles) {
    counts.update(alphabetKey(title), (n) => n + 1, ifAbsent: () => 1);
  }
  return [
    for (final label in ['#', ..._letters.split('')])
      AlphabetLetter(label: label, count: counts[label] ?? 0),
  ];
}

/// The first position of each group in [titles], already sorted.
Map<String, int> firstIndexes(List<String> titles) {
  final first = <String, int>{};
  for (var i = 0; i < titles.length; i++) {
    first.putIfAbsent(alphabetKey(titles[i]), () => i);
  }
  return first;
}

/// The dock-like growth of the letters near the finger (HANDOFF section
/// 6.1): size and inward shift follow a smooth bell of the distance, counted
/// in letters, never by steps.
class AlphabetMagnifier {
  const new({
    required this.base,
    required this.max,
    required this.shiftMax,
    required this.influence,
  });

  /// Size of a letter at rest and under the finger, in dp.
  final double base;
  final double max;

  /// Inward shift of the letter under the finger, in dp.
  final double shiftMax;

  /// Letters on each side that still grow.
  final int influence;

  /// 1 under the finger, 0 past [influence] + 1 letters. Fitted on the
  /// reference values of the design: about 18 dp at one letter and 14 dp at
  /// two, with a rounded peak and no step.
  double _weight(double distance) {
    final d = distance.abs();
    if (d >= influence + 1) return 0;
    const rounding = 0.3;
    const decay = 0.976;
    final eased = math.sqrt(d * d + rounding * rounding) - rounding;
    final t = (d - influence).clamp(0.0, 1.0);
    final taper = 1 - t * t * (3 - 2 * t);
    return math.exp(-eased / decay) * taper;
  }

  double size(double distance) => base + (max - base) * _weight(distance);

  double shift(double distance) => shiftMax * _weight(distance);
}

/// The label of the letter with items nearest to a finger [dy] dp down a
/// column of [height] dp holding all of [letters]; null when none has items.
String? letterAt(List<AlphabetLetter> letters, double dy, double height) {
  if (letters.isEmpty || height <= 0) return null;
  final slot = height / letters.length;
  final over = (dy / slot).floor().clamp(0, letters.length - 1);
  AlphabetLetter? best;
  var bestDistance = letters.length;
  for (var i = 0; i < letters.length; i++) {
    if (!letters[i].hasItems) continue;
    final distance = (i - over).abs();
    if (distance < bestDistance) {
      best = letters[i];
      bestDistance = distance;
    }
  }
  return best?.label;
}
