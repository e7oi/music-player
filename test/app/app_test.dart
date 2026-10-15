import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/app/app.dart';

void main() {
  testWidgets('shows the localized placeholder in French', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MusicPlayerApp());

    expect(find.text('La bibliothèque apparaîtra ici.'), findsOneWidget);
  });

  testWidgets('falls back to English for other locales', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(const MusicPlayerApp());

    expect(find.text('The library will appear here.'), findsOneWidget);
  });
}
