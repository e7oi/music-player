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

    expect(find.text("Autoriser l'accès"), findsOneWidget);
  });

  testWidgets('falls back to English for other locales', (tester) async {
    await pumpApp(tester, const Locale('de'));

    expect(find.text('Allow access'), findsOneWidget);
  });
}
