import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/app/providers/tag_providers.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/features/library/library_page.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';
import 'package:tuneshell/platform/internal_storage.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

import '../../fakes/fake_audio_engine.dart';
import '../../fakes/fake_library.dart';
import '../../fakes/fake_storage.dart';

class _FailingAudioSource implements InternalAudioSource {
  @override
  Future<List<Never>> queryAudio() async => throw Exception('MediaStore down');
}

void main() {
  late FakeInternalAudioSource source;
  late FakeAudioPermission permission;

  setUp(() {
    source = FakeInternalAudioSource()
      ..files = [
        info('Music/a.mp3'),
        info('Music/b.mp3'),
        info('Music/c.mp3'),
        info('Ringtones/r.ogg'),
      ];
    permission = FakeAudioPermission(AudioPermissionStatus.notRequested);
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    InternalAudioSource? audio,
    Size? size,
    double textScale = 1,
  }) async {
    if (size != null) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(FakeLibraryRepository()),
          internalAudioSourceProvider.overrideWithValue(audio ?? source),
          audioPermissionProvider.overrideWithValue(permission),
          audioEngineProvider.overrideWithValue(FakeAudioEngine()),
          trackSourceOpenerProvider.overrideWithValue(FakeTrackSourceOpener()),
          volumeEventsProvider.overrideWithValue(InternalVolumeEvents()),
          removableAudioSourceProvider.overrideWithValue(
            FakeRemovableAudioSource(),
          ),
          tagReaderProvider.overrideWithValue(FakeTagReader()),
          artworkDirectoryProvider.overrideWith((ref) => '/artwork'),
        ],
        child: MaterialApp(
          theme: TsTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const LibraryPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// @verifies FR-014.1
  /// @verifies FR-014.2
  testWidgets('welcome, then the explanation, then the Android dialog', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Your music, at home.'), findsOneWidget);
    expect(permission.requests, 0);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Allow access to your music'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(permission.requests, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Allow access'));
    await tester.pumpAndSettle();

    expect(permission.requests, 1);
    expect(find.text('Music folders'), findsOneWidget);
  });

  /// @verifies FR-014.2
  testWidgets('Back from the explanation returns to the welcome', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to'), findsOneWidget);
  });

  /// @verifies FR-014.3
  testWidgets('a simple refusal shows the banner and Try again', (
    tester,
  ) async {
    permission.answer = AudioPermissionStatus.denied;
    await pumpPage(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Allow access'));
    await tester.pumpAndSettle();

    expect(
      find.text('Access denied. Without it, TuneShell cannot find your music.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
  });

  /// @verifies FR-014.5
  testWidgets('a permanent refusal says how to unblock, and opens settings', (
    tester,
  ) async {
    permission
      ..current = AudioPermissionStatus.permanentlyDenied
      ..answer = AudioPermissionStatus.permanentlyDenied;
    await pumpPage(tester);

    expect(find.text('Access is blocked'), findsOneWidget);
    expect(find.text('Choose a folder instead'), findsOneWidget);
    expect(find.textContaining('Music and audio'), findsOneWidget);

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();

    expect(permission.settingsOpened, 1);
  });

  /// @verifies FR-014.6
  testWidgets('not now shows the library without access, with a way back', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('Access to your music not granted'), findsOneWidget);
    expect(permission.requests, 0);

    await tester.tap(find.widgetWithText(FilledButton, 'Allow access'));
    await tester.pumpAndSettle();

    expect(find.text('Allow access to your music'), findsOneWidget);
  });

  group('the folder choice', () {
    setUp(() => permission.current = AudioPermissionStatus.granted);

    /// @verifies FR-015.1
    testWidgets('the summary follows the checked folders', (tester) async {
      await pumpPage(tester);

      expect(find.text('Internal storage'), findsOneWidget);
      expect(find.text('1 folder · 3 files'), findsOneWidget);

      await tester.tap(find.text('Ringtones'));
      await tester.pump();

      expect(find.text('2 folders · 4 files'), findsOneWidget);
    });

    /// @verifies FR-015.2
    testWidgets('a whole row is the touch area, labelled with its count', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(tester);

      final row = find.widgetWithText(CheckboxListTile, 'Music');
      expect(
        tester.getSize(row).height,
        greaterThanOrEqualTo(TsSize.touchTarget),
      );
      expect(tester.getSemantics(row).label, 'Music\n3 audio files');
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(of: row, matching: find.byType(Checkbox)),
            )
            .value,
        isTrue,
      );
      semantics.dispose();
    });

    /// @verifies FR-015.5
    testWidgets('no audio file: the empty state offers two ways out', (
      tester,
    ) async {
      source.files = [];
      await pumpPage(tester);

      expect(find.text('No audio file found'), findsOneWidget);
      expect(find.text('Add a folder'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Refresh'), findsOneWidget);
      expect(find.text('No folder to add.'), findsOneWidget);
    });

    /// @verifies FR-015.6
    testWidgets('a failing read keeps the error in the flow', (tester) async {
      await pumpPage(tester, audio: _FailingAudioSource());

      expect(find.text('The folders could not be read.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  /// @verifies FR-014.7
  /// @verifies FR-015.9
  group('large text and landscape', () {
    for (final (name, size, scale) in [
      ('200 % text', const Size(412, 915), 2.0),
      ('landscape', const Size(915, 412), 1.0),
    ]) {
      testWidgets('welcome and explanation keep their button ($name)', (
        tester,
      ) async {
        await pumpPage(tester, size: size, textScale: scale);

        expect(find.text('Get started'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final start = tester.getRect(
          find.widgetWithText(FilledButton, 'Get started'),
        );
        expect(start.bottom, lessThanOrEqualTo(size.height));

        await tester.tap(find.text('Get started'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        final allow = tester.getRect(
          find.widgetWithText(FilledButton, 'Allow access'),
        );
        expect(allow.bottom, lessThanOrEqualTo(size.height));
      });

      testWidgets('the blocked screen fits ($name)', (tester) async {
        permission.current = AudioPermissionStatus.permanentlyDenied;
        await pumpPage(tester, size: size, textScale: scale);

        expect(tester.takeException(), isNull);
        expect(find.text('Open settings'), findsOneWidget);
        final open = tester.getRect(
          find.widgetWithText(FilledButton, 'Open settings'),
        );
        expect(open.bottom, lessThanOrEqualTo(size.height));
      });

      testWidgets('the folder choice fits ($name)', (tester) async {
        permission.current = AudioPermissionStatus.granted;
        await pumpPage(tester, size: size, textScale: scale);

        expect(tester.takeException(), isNull);
        final next = tester.getRect(
          find.widgetWithText(FilledButton, 'Continue'),
        );
        expect(next.bottom, lessThanOrEqualTo(size.height));
      });
    }
  });
}
