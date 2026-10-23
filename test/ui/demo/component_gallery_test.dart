import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/demo/component_gallery.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';
import 'package:tuneshell/ui/widgets/disk_card.dart';
import 'package:tuneshell/ui/widgets/jump_to_current_fab.dart';
import 'package:tuneshell/ui/widgets/progress_banner.dart';
import 'package:tuneshell/ui/widgets/source_mark.dart';
import 'package:tuneshell/ui/widgets/status_banner.dart';
import 'package:tuneshell/ui/widgets/track_tile.dart';

void main() {
  Future<void> pumpGallery(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(412, 6000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: TsTheme.light(), home: const ComponentGallery()),
    );
  }

  /// @verifies FR-010.7
  testWidgets('shows every component in every state', (tester) async {
    await pumpGallery(tester);

    final states = tester
        .widgetList<TrackTile>(find.byType(TrackTile))
        .map((t) => t.state)
        .toSet();
    expect(states, TrackTileState.values.toSet());
    expect(
      tester
          .widgetList<DiskCard>(find.byType(DiskCard))
          .map((d) => d.status)
          .toSet(),
      DiskStatus.values.toSet(),
    );
    expect(
      tester
          .widgetList<StatusBanner>(find.byType(StatusBanner))
          .map((b) => b.kind)
          .toSet(),
      BannerKind.values.toSet(),
    );
    expect(find.byType(ProgressBanner), findsNWidgets(2));
    expect(find.byType(JumpToCurrentFab), findsNWidgets(3));
    expect(
      tester
          .widgetList<SourceMark>(find.byType(SourceMark))
          .map((m) => m.shape)
          .toSet(),
      SourceMarkShape.values.toSet(),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switches to the dark theme', (tester) async {
    await pumpGallery(tester);
    Brightness shown() =>
        Theme.of(tester.element(find.byType(TrackTile).first)).brightness;
    expect(shown(), Brightness.light);

    await tester.tap(find.text('Dark'));
    // The indeterminate progress bar never settles: pump a fixed time.
    await tester.pump(const Duration(milliseconds: 400));

    expect(shown(), Brightness.dark);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the list of 5 000 rows with the index', (tester) async {
    await pumpGallery(tester);

    final button = find.widgetWithText(FilledButton, 'Open the 5,000-row list');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('5,000 rows'), findsOneWidget);
    expect(find.bySemanticsLabel('Go to letter'), findsOneWidget);
  });
}
