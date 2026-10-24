import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';

import 'support.dart';

void main() {
  /// @verifies FR-013.5
  testWidgets('without an arrow when it leads to the player', (tester) async {
    await pumpUi(
      tester,
      Center(
        child: JumpToCurrentFab(
          label: 'En cours',
          showArrow: false,
          onPressed: () {},
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    expect(find.text('En cours'), findsOneWidget);
  });

  Future<void> pumpFab(
    WidgetTester tester, {
    JumpDirection direction = JumpDirection.down,
    bool visible = true,
    bool lastPlayed = false,
    bool folded = false,
    bool showArrow = true,
    VoidCallback? onPressed,
    bool dark = false,
  }) => pumpUi(
    tester,
    Center(
      child: JumpToCurrentFab(
        label: lastPlayed ? 'Dernière jouée' : 'En cours',
        direction: direction,
        visible: visible,
        lastPlayed: lastPlayed,
        folded: folded,
        showArrow: showArrow,
        onPressed: onPressed ?? () {},
      ),
    ),
    dark: dark,
  );

  for (final dark in themes) {
    group('in ${themeName(dark: dark)}', () {
      /// @verifies FR-010.3
      testWidgets('shows the label and points toward the track', (
        tester,
      ) async {
        await pumpFab(tester, direction: JumpDirection.up, dark: dark);

        expect(find.text('En cours'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
        expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);

        await pumpFab(tester, dark: dark);

        expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      });

      testWidgets('last played: a quieter variant with its own icon', (
        tester,
      ) async {
        await pumpFab(tester, lastPlayed: true, dark: dark);

        expect(find.text('Dernière jouée'), findsOneWidget);
        expect(find.byIcon(Icons.history_rounded), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
        final scheme = Theme.of(tester.element(find.text('Dernière jouée')));
        final material = tester.widget<Material>(
          find.descendant(
            of: find.byType(JumpToCurrentFab),
            matching: find.byType(Material),
          ),
        );
        expect(material.color, scheme.colorScheme.surfaceContainerHigh);
      });

      testWidgets('folded: the icon only', (tester) async {
        await pumpFab(tester, folded: true, dark: dark);

        expect(find.text('En cours'), findsNothing);
        expect(find.byIcon(Icons.equalizer_rounded), findsOneWidget);
      });
    });
  }

  /// @verifies FR-010.3
  testWidgets('hidden: scaled to nothing and not touchable', (tester) async {
    var taps = 0;
    await pumpFab(tester, visible: false, onPressed: () => taps++);
    await tester.pumpAndSettle();

    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 0);
    await tester.tap(find.byType(JumpToCurrentFab), warnIfMissed: false);
    expect(taps, 0);
  });

  testWidgets('fades and scales in when it becomes visible', (tester) async {
    await pumpFab(tester, visible: false);
    await tester.pumpAndSettle();

    await pumpFab(tester);
    await tester.pump(TsMotion.medium ~/ 2);
    final scale = tester
        .widget<AnimatedScale>(find.byType(AnimatedScale))
        .scale;
    expect(scale, 1);
    await tester.pumpAndSettle();
  });

  /// @verifies FR-010.6
  testWidgets('a 56 dp high touch target that fires and speaks', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await pumpFab(tester, onPressed: () => taps++);

    expect(tester.getSize(find.byType(JumpToCurrentFab)).height, TsSize.fab);
    await tester.tap(find.byType(JumpToCurrentFab));
    expect(taps, 1);
    expect(find.bySemanticsLabel('En cours'), findsOneWidget);
    handle.dispose();
  });

  /// @verifies BR-007 rule 7
  testWidgets('no motion when animations are disabled', (tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app({required bool visible}) => MaterialApp(
      theme: TsTheme.light(),
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: Center(
            child: JumpToCurrentFab(
              label: 'En cours',
              visible: visible,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(visible: false));
    await tester.pumpWidget(app(visible: true));

    // Not a single animation frame: it is there at once.
    expect(
      tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration,
      Duration.zero,
    );
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration,
      Duration.zero,
    );
  });
}
