import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// Pumps [child] in the TuneShell theme, light or dark.
Future<void> pumpUi(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  Size size = const Size(412, 915),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? TsTheme.dark() : TsTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

/// Both themes, for the tests that must hold in each.
const themes = [false, true];

String themeName({required bool dark}) => dark ? 'dark' : 'light';
