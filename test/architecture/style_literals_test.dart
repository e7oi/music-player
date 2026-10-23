import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'style_literals.dart';

void main() {
  group('rules on synthetic files', () {
    List<String> check(String source, [String file = 'features/x/y.dart']) =>
        styleViolationsOf(file, source);

    /// @verifies BR-007
    test('flags colours, font sizes, radii and spacing', () {
      expect(check('final c = Color(0xFF00695C);'), hasLength(1));
      expect(check('final c = Colors.teal;'), hasLength(1));
      expect(check('TextStyle(fontSize: 14);'), hasLength(1));
      expect(check('BorderRadius.circular(8);'), hasLength(1));
      expect(check('const EdgeInsets.all(16);'), hasLength(1));
      expect(check('const EdgeInsets.symmetric(horizontal: 8);'), hasLength(1));
      expect(check('const SizedBox(height: 16);'), hasLength(1));
    });

    test('accepts tokens, transparent and unrelated numbers', () {
      expect(check('EdgeInsets.all(TsSpace.l);'), isEmpty);
      expect(check('BorderRadius.all(TsRadius.card);'), isEmpty);
      expect(check('color: Colors.transparent,'), isEmpty);
      expect(check('SizedBox(height: TsSpace.s);'), isEmpty);
      expect(check('final retries = 3;'), isEmpty);
      expect(check('// Color(0xFF000000) in a comment'), isEmpty);
    });

    test('leaves the token file and the other layers alone', () {
      expect(
        check('Color(0xFF00695C)', 'ui/theme/tuneshell_tokens.dart'),
        isEmpty,
      );
      expect(check('Color(0xFF00695C)', 'domain/x.dart'), isEmpty);
      expect(check('Color(0xFF00695C)', 'ui/widgets/x.dart'), hasLength(1));
      expect(check('Color(0xFF00695C)', 'ui/demo/x.dart'), hasLength(1));
    });
  });

  /// @verifies BR-007
  test('screens and components use the design tokens only', () {
    final lib = Directory('lib');
    final violations = <String>[
      for (final entity in lib.listSync(recursive: true))
        if (entity is File && entity.path.endsWith('.dart'))
          ...styleViolationsOf(
            entity.path.substring(lib.path.length + 1),
            entity.readAsStringSync(),
          ),
    ];

    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
