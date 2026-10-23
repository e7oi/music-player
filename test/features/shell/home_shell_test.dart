import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/features/shell/home_shell.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// Counts its own builds of state, to show that a tab keeps its state.
class _Probe extends StatefulWidget {
  const new();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => taps++),
    child: Text('taps $taps'),
  );
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Size size,
    String locale = 'en',
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: TsTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale(locale),
          home: const HomeShell(
            tracks: _Probe(),
            playerBar: SizedBox(key: Key('player'), height: 10),
          ),
        ),
      ),
    );
  }

  /// @verifies FR-009.3
  group('width', () {
    testWidgets('under 600 dp: navigation bar at the bottom', (tester) async {
      await pump(tester, size: const Size(412, 915));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('600 dp and more: navigation rail', (tester) async {
      for (final width in [TsSize.compactMax, 700.0, 915.0, 1200.0]) {
        await pump(tester, size: Size(width, 412));

        expect(find.byType(NavigationRail), findsOneWidget, reason: '$width');
        expect(find.byType(NavigationBar), findsNothing, reason: '$width');
      }
    });
  });

  /// @verifies FR-009.1
  testWidgets('four tabs in order, starting on Tracks', (tester) async {
    await pump(tester, size: const Size(412, 915));

    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => d.label);
    expect(labels, ['Tracks', 'Albums', 'Artists', 'Settings']);
    expect(find.text('taps 0'), findsOneWidget);
  });

  /// @verifies FR-009.9
  testWidgets('the labels are those of the mock-ups in French', (tester) async {
    await pump(tester, size: const Size(412, 915), locale: 'fr');

    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => d.label);
    expect(labels, ['Pistes', 'Albums', 'Artistes', 'Réglages']);
    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();
    expect(find.text('Cette vue arrive bientôt.'), findsOneWidget);
  });

  /// @verifies FR-009.2
  testWidgets('the other tabs say they are coming soon', (tester) async {
    await pump(tester, size: const Size(412, 915));

    for (final tab in ['Albums', 'Artists']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();

      expect(find.text('This view is coming soon.'), findsOneWidget);
    }
  });

  /// @verifies FR-009.4
  group('state', () {
    testWidgets('a tab keeps its state when another is shown', (tester) async {
      await pump(tester, size: const Size(412, 915));
      await tester.tap(find.text('taps 0'));
      await tester.pump();
      expect(find.text('taps 1'), findsOneWidget);

      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tracks'));
      await tester.pumpAndSettle();

      expect(find.text('taps 1'), findsOneWidget);
    });

    testWidgets('rotating keeps the current tab and its state', (tester) async {
      await pump(tester, size: const Size(412, 915));
      await tester.tap(find.text('taps 0'));
      await tester.pump();
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();

      tester.view.physicalSize = const Size(915, 412);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('This view is coming soon.'), findsOneWidget);
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );

      await tester.tap(find.text('Tracks'));
      await tester.pumpAndSettle();
      expect(find.text('taps 1'), findsOneWidget);
    });
  });

  /// @verifies FR-009.5
  testWidgets('the player bar sits in the shell, in every tab', (tester) async {
    await pump(tester, size: const Size(412, 915));
    expect(find.byKey(const Key('player')), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('player')), findsOneWidget);
    final bar = tester.getRect(find.byKey(const Key('player')));
    final nav = tester.getRect(find.byType(NavigationBar));
    expect(bar.bottom, lessThanOrEqualTo(nav.top));
  });

  /// @verifies FR-009.7
  group('system back', () {
    testWidgets('from another tab goes to Tracks, then leaves', (tester) async {
      await pump(tester, size: const Size(412, 915));
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(find.text('taps 0'), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
    });
  });

  /// @verifies FR-009.3 the rail takes the inset of a camera cut-out, once.
  group('landscape with a cut-out on the left', () {
    Future<void> pumpCutout(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(915, 412)
        ..devicePixelRatio = 1
        ..padding = const FakeViewPadding(left: 60, top: 24, bottom: 20)
        ..viewPadding = const FakeViewPadding(left: 60, top: 24, bottom: 20);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: TsTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: HomeShell(
              tracks: Builder(
                builder: (context) =>
                    Text('left ${MediaQuery.paddingOf(context).left}'),
              ),
              playerBar: const SizedBox.shrink(),
            ),
          ),
        ),
      );
    }

    testWidgets('the rail background reaches the screen edges', (tester) async {
      await pumpCutout(tester);

      final rect = tester.getRect(find.byKey(HomeShell.railBackgroundKey));
      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.bottom, 412);
    });

    testWidgets('the views do not take the inset a second time', (
      tester,
    ) async {
      await pumpCutout(tester);

      expect(find.text('left 0.0'), findsOneWidget);
    });

    testWidgets('the rail items stay clear of the cut-out', (tester) async {
      await pumpCutout(tester);

      expect(
        tester.getRect(find.text('Tracks')).left,
        greaterThanOrEqualTo(60),
      );
    });
  });
}
