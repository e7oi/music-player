import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';

import 'support.dart';

void main() {
  const light = TsColors.light;

  /// @verifies FR-010.3
  group('marks', () {
    test('Local is a neutral circle', () {
      final mark = SourceMark.local(light);

      expect(mark.shape, SourceMarkShape.circle);
      expect(mark.color, light.sourceLocal);
      expect(mark.outlined, isFalse);
    });

    test('the first four disks differ by shape and colour', () {
      final marks = [for (var i = 0; i < 4; i++) SourceMark.disk(i, light)];

      expect(marks.map((m) => m.shape), [
        SourceMarkShape.square,
        SourceMarkShape.diamond,
        SourceMarkShape.triangle,
        SourceMarkShape.hexagon,
      ]);
      expect({
        for (final m in marks) m.shape,
        SourceMarkShape.circle,
      }, hasLength(5));
      expect({for (final m in marks) m.color}, hasLength(4));
      expect(marks.every((m) => !m.outlined), isTrue);
    });

    test('from the fifth disk the shapes come back as outlines', () {
      final fifth = SourceMark.disk(4, light);

      expect(fifth.shape, SourceMarkShape.square);
      expect(fifth.outlined, isTrue);
      expect(fifth.color, light.sourceColor(0));
      expect(SourceMark.disk(7, light).shape, SourceMarkShape.hexagon);
    });
  });

  group('rendering', () {
    for (final dark in themes) {
      testWidgets('every shape paints at 12 dp in ${themeName(dark: dark)}', (
        tester,
      ) async {
        final colors = dark ? TsColors.dark : TsColors.light;
        await pumpUi(
          tester,
          Row(
            children: [
              for (final shape in SourceMarkShape.values)
                SourceMark(shape: shape, color: colors.sourceLocal),
              SourceMark.disk(5, colors),
            ],
          ),
          dark: dark,
        );

        for (final mark in tester.widgetList<SourceMark>(
          find.byType(SourceMark),
        )) {
          expect(mark.size, TsSize.sourceMark);
        }
        expect(tester.takeException(), isNull);
        final sized = tester.getSize(find.byType(SourceMark).first);
        expect(sized, const Size.square(TsSize.sourceMark));
      });
    }

    /// @verifies FR-010.6
    testWidgets('is decorative for TalkBack', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpUi(
        tester,
        Semantics(label: 'row', child: SourceMark.disk(0, light)),
      );

      expect(
        find.descendant(
          of: find.byType(SourceMark),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
