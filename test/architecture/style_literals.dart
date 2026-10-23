/// BR-007, rule 1: no colour, font size, radius or spacing literal outside
/// the design tokens, as a pure function so that the rule is tested on
/// synthetic code.
library;

final _literals = <(RegExp, String)>[
  (RegExp(r'\bColor\(\s*0x'), 'Color literal'),
  (RegExp(r'\bColors\.(?!transparent\b)\w+'), 'Colors.* constant'),
  (RegExp(r'\bfontSize\s*:'), 'fontSize'),
  (RegExp(r'\bRadius\.circular\(\s*\d'), 'Radius literal'),
  (RegExp(r'\bBorderRadius\.circular\(\s*\d'), 'BorderRadius literal'),
  (RegExp(r'\bEdgeInsets(?:Directional)?\.\w+\([^)]*\d'), 'EdgeInsets literal'),
  (RegExp(r'\bSizedBox\([^)]*\b(?:width|height)\s*:\s*\d'), 'SizedBox gap'),
];

/// Where the rule applies, relative to `lib/`: screens and components, not the
/// token file itself.
bool isStyleChecked(String file) =>
    file.startsWith('features/') ||
    file.startsWith('ui/widgets/') ||
    file.startsWith('ui/demo/');

/// One message per forbidden literal found in [source].
List<String> styleViolationsOf(String file, String source) => [
  if (isStyleChecked(file))
    for (final (pattern, name) in _literals)
      for (final match in pattern.allMatches(_withoutComments(source)))
        'lib/$file: $name (${match.group(0)})',
];

String _withoutComments(String source) => source
    .split('\n')
    .map((line) {
      final i = line.indexOf('//');
      return i < 0 ? line : line.substring(0, i);
    })
    .join('\n');
