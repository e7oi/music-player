import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/app.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/platform/internal_storage.dart';

import '../fakes/fake_audio_engine.dart';
import '../fakes/fake_library.dart';
import '../fakes/fake_storage.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final permission = FakeAudioPermission(AudioPermissionStatus.denied)
      ..answer = AudioPermissionStatus.denied;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository()),
          internalAudioSourceProvider.overrideWithValue(
            FakeInternalAudioSource(),
          ),
          audioPermissionProvider.overrideWithValue(permission),
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          trackSourceOpenerProvider.overrideWithValue(FakeTrackSourceOpener()),
          volumeEventsProvider.overrideWithValue(InternalVolumeEvents()),
        ],
        child: const TuneShellApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('speaks French', (tester) async {
    await pumpApp(tester, const Locale('fr'));

    expect(find.text("Autoriser l'accès à ta musique"), findsOneWidget);
  });

  testWidgets('falls back to English for other locales', (tester) async {
    await pumpApp(tester, const Locale('de'));

    expect(find.text('Allow access to your music'), findsOneWidget);
  });

  /// @verifies FR-008.2
  testWidgets('follows the system theme', (tester) async {
    await pumpApp(tester, const Locale('en'));

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  /// @verifies FR-008.2
  testWidgets('turns dark with the system, without restarting', (tester) async {
    await pumpApp(tester, const Locale('en'));
    Brightness shown() =>
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness;
    expect(shown(), Brightness.light);

    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();

    expect(shown(), Brightness.dark);
  });

  /// @verifies FR-014.7
  testWidgets('the first-launch screens are full screen, the library is not', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(tester, const Locale('en'));

    expect(find.text('Allow access to your music'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Access to your music not granted'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
