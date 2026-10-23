import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/alphabet_index.dart';
import 'package:tuneshell/ui/widgets/alphabet_scroller.dart';

import 'support.dart';

/// 5 000 titles: 200 per letter except Q, X and Y, and the rest under "#".
List<String> fakeTitles() {
  const present = 'ABCDEFGHIJKLMNOPRSTUVWZ';
  final titles = <String>[
    for (var i = 0; i < 400; i++) '${i.toString().padLeft(4, '0')} piste',
  ];
  for (final letter in present.split('')) {
    titles.addAll([
      for (var i = 0; i < 200; i++) '$letter${i.toString().padLeft(3, '0')}',
    ]);
  }
  return titles;
}

void main() {
  const rowExtent = 64.0;
  final titles = fakeTitles();
  final letters = buildLetters(titles);
  final first = firstIndexes(titles);
  late ScrollController controller;
  late List<String> selected;
  late List<Rect> handleRects;
  var haptics = 0;

  setUp(() {
    controller = ScrollController();
    selected = [];
    handleRects = [];
    haptics = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics++;
          return null;
        });
    addTearDown(() {
      controller.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });

  Widget host({
    int? itemCount,
    bool alignStart = false,
    List<AlphabetLetter>? overrideLetters,
  }) => AlphabetScroller(
    letters: overrideLetters ?? letters,
    itemCount: itemCount ?? titles.length,
    alignStart: alignStart,
    gridTitle: 'Aller à la lettre',
    countLabel: (count) => '$count pistes',
    letterSemantics: (letter, count) => 'Lettre $letter, $count pistes',
    onHandleRect: handleRects.add,
    onLetterSelected: (letter) {
      selected.add(letter);
      controller.jumpTo((first[letter] ?? 0) * rowExtent);
    },
    child: ListView.builder(
      controller: controller,
      itemExtent: rowExtent,
      itemCount: itemCount ?? titles.length,
      itemBuilder: (context, i) => Text(i < titles.length ? titles[i] : '$i'),
    ),
  );

  Offset handleCenter(WidgetTester tester) {
    final size = tester.view.physicalSize;
    return Offset(
      size.width - TsSize.indexHandleTouch.width / 2,
      size.height / 2,
    );
  }

  double yOfLetter(WidgetTester tester, String label) {
    final i = letters.indexWhere((l) => l.label == label);
    final height = tester.view.physicalSize.height - 2 * TsSpace.l;
    return TsSpace.l + (i + 0.5) * height / letters.length;
  }

  /// A drag only starts after the touch slop: leave the handle first.
  Future<TestGesture> dragTo(WidgetTester tester, String label) async {
    final gesture = await tester.startGesture(handleCenter(tester));
    final x = tester.view.physicalSize.width - 16;
    await gesture.moveTo(Offset(x, yOfLetter(tester, 'F')));
    await gesture.moveTo(Offset(x, yOfLetter(tester, label)));
    await tester.pump();
    return gesture;
  }

  /// @verifies FR-010.4
  group('handle', () {
    testWidgets('appears only for a long list', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpUi(tester, host(itemCount: 100));
      expect(handle, isNotNull);
      expect(find.bySemanticsLabel('Aller à la lettre'), findsNothing);

      await pumpUi(tester, host(itemCount: 101));
      expect(find.bySemanticsLabel('Aller à la lettre'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('is 6 x 48 dp in a 32 x 64 dp touch area at the edge', (
      tester,
    ) async {
      await pumpUi(tester, host());

      final touch = tester.getRect(
        find
            .ancestor(
              of: find.byType(AnimatedOpacity),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(touch.size, TsSize.indexHandleTouch);
      expect(touch.right, tester.view.physicalSize.width);
      final bar = tester.getRect(
        find.descendant(
          of: find.byType(AnimatedOpacity),
          matching: find.byType(SizedBox),
        ),
      );
      expect(
        bar.size,
        const Size(TsSize.indexHandleWidth, TsSize.indexHandleHeight),
      );
    });

    testWidgets('sits on the start side when asked', (tester) async {
      await pumpUi(tester, host(alignStart: true));

      final touch = tester.getRect(
        find
            .ancestor(
              of: find.byType(AnimatedOpacity),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(touch.left, 0);
    });

    testWidgets('is lit while the list scrolls, faint after 1.5 s', (
      tester,
    ) async {
      await pumpUi(tester, host());
      double opacity() =>
          tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
      expect(opacity(), lessThan(1));

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      expect(opacity(), 1);

      await tester.pump(
        TsMotion.handleIdleHide + const Duration(milliseconds: 100),
      );
      await tester.pumpAndSettle();
      expect(opacity(), lessThan(1));
    });

    testWidgets('reports its rectangle for the gesture exclusion', (
      tester,
    ) async {
      await pumpUi(tester, host());
      await tester.pump();

      expect(handleRects, isNotEmpty);
      expect(handleRects.last.size, TsSize.indexHandleTouch);
      expect(handleRects.last.right, tester.view.physicalSize.width);
    });
  });

  /// @verifies FR-010.4
  group('drag', () {
    testWidgets('a normal scroll never opens the column', (tester) async {
      await pumpUi(tester, host());

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(selected, isEmpty);
      expect(find.textContaining('pistes'), findsNothing);
    });

    testWidgets('a drag beside the handle does not select a letter', (
      tester,
    ) async {
      await pumpUi(tester, host());
      final edge = Offset(
        tester.view.physicalSize.width - TsSize.indexHandleTouch.width - 4,
        100,
      );

      final gesture = await tester.startGesture(edge);
      await gesture.moveBy(const Offset(0, 300));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selected, isEmpty);
    });

    testWidgets('from the handle: bubble with the letter and its count', (
      tester,
    ) async {
      await pumpUi(tester, host());

      final gesture = await tester.startGesture(handleCenter(tester));
      await gesture.moveTo(
        Offset(tester.view.physicalSize.width - 16, yOfLetter(tester, 'C')),
      );
      await tester.pump();

      expect(selected.last, 'C');
      expect(find.text('200 pistes'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlphabetScroller),
          matching: find.text('C'),
        ),
        findsWidgets,
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the list follows in real time, without animation', (
      tester,
    ) async {
      await pumpUi(tester, host());

      final gesture = await dragTo(tester, 'M');

      expect(
        controller.offset,
        first['M']! * rowExtent,
        reason: 'max ${controller.position.maxScrollExtent}',
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('empty letters are skipped', (tester) async {
      await pumpUi(tester, host());

      final gesture = await tester.startGesture(handleCenter(tester));
      await gesture.moveTo(
        Offset(tester.view.physicalSize.width - 16, yOfLetter(tester, 'Q')),
      );
      await tester.pump();

      expect(['P', 'R'], contains(selected.last));
      expect(selected, isNot(contains('Q')));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('one light vibration per change of letter, not per move', (
      tester,
    ) async {
      await pumpUi(tester, host());

      final gesture = await tester.startGesture(handleCenter(tester));
      final x = tester.view.physicalSize.width - 16;
      await gesture.moveTo(Offset(x, yOfLetter(tester, 'C')));
      await gesture.moveBy(const Offset(0, 1));
      await gesture.moveBy(const Offset(0, 1));
      final afterFirst = haptics;
      await gesture.moveTo(Offset(x, yOfLetter(tester, 'D')));
      await tester.pump();

      expect(afterFirst, selected.where((s) => s == 'C').length);
      expect(haptics, afterFirst + 1);
      expect(selected.last, 'D');
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the # group leads the column', (tester) async {
      await pumpUi(tester, host());

      final gesture = await tester.startGesture(handleCenter(tester));
      await gesture.moveTo(
        Offset(tester.view.physicalSize.width - 16, yOfLetter(tester, '#')),
      );
      await tester.pump();

      expect(selected.last, '#');
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the column goes away 600 ms after release', (tester) async {
      await pumpUi(tester, host());
      final gesture = await tester.startGesture(handleCenter(tester));
      await gesture.moveTo(
        Offset(tester.view.physicalSize.width - 16, yOfLetter(tester, 'C')),
      );
      await tester.pump();
      await gesture.up();

      await tester.pump(
        TsMotion.indexHideDelay - const Duration(milliseconds: 50),
      );
      expect(find.text('200 pistes'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('200 pistes'), findsNothing);
    });

    testWidgets('letters grow near the finger, continuously', (tester) async {
      await pumpUi(tester, host());
      final gesture = await dragTo(tester, 'M');

      // The column holds each letter inside a scaled Transform; the bubble
      // holds one more "M" without it.
      double scaleOf(String label) {
        final scales = <double>[
          for (final text in find.text(label).evaluate())
            for (final transform
                in find
                    .ancestor(
                      of: find.byWidget(text.widget),
                      matching: find.byType(Transform),
                    )
                    .evaluate())
              (transform.widget as Transform).transform.getMaxScaleOnAxis(),
        ];
        return scales.isEmpty ? 1 : scales.reduce((a, b) => a > b ? a : b);
      }

      expect(scaleOf('M'), greaterThan(scaleOf('K')));
      expect(scaleOf('L'), greaterThan(scaleOf('J')));
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  /// @verifies FR-010.4
  group('grid', () {
    testWidgets('touching the handle without dragging opens it', (
      tester,
    ) async {
      await pumpUi(tester, host());

      await tester.tapAt(handleCenter(tester));
      await tester.pumpAndSettle();

      expect(find.text('Aller à la lettre'), findsWidgets);
      expect(find.widgetWithText(TextButton, 'M'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '#'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'Q'))
            .onPressed,
        isNull,
      );
      expect(
        tester.getSize(find.widgetWithText(TextButton, 'M')).shortestSide,
        greaterThanOrEqualTo(TsSize.touchTarget),
      );
    });

    testWidgets('choosing a letter jumps to it and closes the grid', (
      tester,
    ) async {
      await pumpUi(tester, host());
      await tester.tapAt(handleCenter(tester));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'M'));
      await tester.pumpAndSettle();

      expect(selected, ['M']);
      expect(controller.offset, first['M']! * rowExtent);
      expect(find.widgetWithText(TextButton, 'M'), findsNothing);
    });
  });

  /// @verifies FR-010.6
  group('TalkBack', () {
    testWidgets('increase and decrease move to the next and previous letter', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpUi(tester, host());

      tester.semantics.performAction(handleLabel, SemanticsAction.increase);
      await tester.pump();
      expect(selected, ['#']);

      tester.semantics.performAction(handleLabel, SemanticsAction.increase);
      await tester.pump();
      expect(selected, ['#', 'A']);

      tester.semantics.performAction(handleLabel, SemanticsAction.decrease);
      await tester.pump();
      expect(selected, ['#', 'A', '#']);
      handle.dispose();
    });

    testWidgets('the value says the letter and its count', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpUi(tester, host());
      tester.semantics.performAction(handleLabel, SemanticsAction.increase);
      await tester.pump();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Aller à la lettre')).value,
        'Lettre #, 400 pistes',
      );
      handle.dispose();
    });
  });
}

final FinderBase<SemanticsNode> handleLabel = find.semantics.byLabel(
  'Aller à la lettre',
);
