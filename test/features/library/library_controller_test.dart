import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicplayer/app/providers/library_providers.dart';
import 'package:musicplayer/domain/library/ports/internal_audio_source.dart';
import 'package:musicplayer/features/library/library_controller.dart';

import '../../fakes/fake_library.dart';

void main() {
  late FakeLibraryRepository repository;
  late FakeInternalAudioSource source;
  late FakeAudioPermission permission;
  late ProviderContainer container;

  ProviderContainer create() => ProviderContainer(
    overrides: [
      libraryRepositoryProvider.overrideWithValue(repository),
      internalAudioSourceProvider.overrideWithValue(source),
      audioPermissionProvider.overrideWithValue(permission),
    ],
  );

  LibraryViewState state() => container.read(libraryControllerProvider);

  LibraryController controller() =>
      container.read(libraryControllerProvider.notifier);

  setUp(() {
    repository = FakeLibraryRepository();
    source = FakeInternalAudioSource()
      ..files = [
        info('Music/a.mp3'),
        info('Music/b.mp3'),
        info('Ringtones/r.ogg'),
      ];
    permission = FakeAudioPermission(AudioPermissionStatus.notRequested);
    container = create();
  });

  tearDown(() => container.dispose());

  group('FR-004 permission', () {
    /// @verifies FR-004
    test('asks once at first launch, then offers the folders', () async {
      await controller().start();

      expect(permission.requests, 1);
      expect(state(), isA<LibraryFolderChoice>());
    });

    /// @verifies FR-004
    test('later launches do not ask again after a refusal', () async {
      permission.current = AudioPermissionStatus.denied;

      await controller().start();

      expect(permission.requests, 0);
      expect(state(), isA<LibraryPermissionNeeded>());
    });

    /// @verifies FR-004
    test('a refusal shows the explanation with a retry', () async {
      permission.answer = AudioPermissionStatus.denied;

      await controller().start();

      expect(
        state(),
        isA<LibraryPermissionNeeded>().having(
          (s) => s.permanent,
          'permanent',
          false,
        ),
      );
    });

    /// @verifies FR-004
    test('retry asks again and continues when granted', () async {
      permission.answer = AudioPermissionStatus.denied;
      await controller().start();
      permission.answer = AudioPermissionStatus.granted;

      await controller().requestPermission();

      expect(permission.requests, 2);
      expect(state(), isA<LibraryFolderChoice>());
    });

    /// @verifies FR-004
    test('a permanent refusal opens the app settings instead', () async {
      permission.current = AudioPermissionStatus.permanentlyDenied;
      await controller().start();

      expect(permission.requests, 0);
      expect(
        state(),
        isA<LibraryPermissionNeeded>().having(
          (s) => s.permanent,
          'permanent',
          true,
        ),
      );

      permission.answer = AudioPermissionStatus.permanentlyDenied;
      await controller().requestPermission();

      expect(permission.settingsOpened, 1);
    });

    /// @verifies FR-004
    test(
      'a dismissed dialog that Android still shows needs no settings',
      () async {
        permission.current = AudioPermissionStatus.permanentlyDenied;
        await controller().start();
        permission.answer = AudioPermissionStatus.granted;

        await controller().requestPermission();

        expect(permission.settingsOpened, 0);
        expect(state(), isA<LibraryFolderChoice>());
      },
    );

    test('a request already running is ignored', () async {
      permission.current = AudioPermissionStatus.denied;
      await controller().start();
      permission.failNextRequest = true;

      await controller().requestPermission();

      expect(state(), isA<LibraryPermissionNeeded>());
    });

    /// @verifies FR-004
    test(
      'access revoked while away shows the refusal and keeps the library',
      () async {
        permission.current = AudioPermissionStatus.granted;
        await controller().start();
        await controller().confirmFolders({'Music'});
        permission.current = AudioPermissionStatus.denied;

        await controller().onResumed();

        expect(state(), isA<LibraryPermissionNeeded>());
        expect(repository.tracks, hasLength(2));
      },
    );

    /// @verifies FR-004
    test('access granted in the settings is picked up on return', () async {
      permission.current = AudioPermissionStatus.permanentlyDenied;
      await controller().start();
      permission.current = AudioPermissionStatus.granted;

      await controller().onResumed();

      expect(state(), isA<LibraryFolderChoice>());
    });

    test('returning while granted changes nothing', () async {
      permission.current = AudioPermissionStatus.granted;
      await controller().start();
      final before = state();

      await controller().onResumed();

      expect(state(), same(before));
    });
  });

  group('FR-003 folders and indexing', () {
    setUp(() => permission.current = AudioPermissionStatus.granted);

    /// @verifies FR-003
    test('first launch offers the folders with Music checked', () async {
      await controller().start();

      final choice = state() as LibraryFolderChoice;
      expect(choice.folders.map((f) => f.path), ['Music', 'Ringtones']);
      expect(choice.selected, {'Music'});
      expect(repository.tracks, isEmpty);
    });

    /// @verifies FR-003
    test('confirming indexes the chosen folders', () async {
      await controller().start();

      await controller().confirmFolders({'Music'});

      expect(
        state(),
        isA<LibraryReady>()
            .having((s) => s.indexing, 'indexing', false)
            .having((s) => s.hasFolders, 'hasFolders', true),
      );
      expect(repository.tracks, hasLength(2));
    });

    test(
      'an empty choice leads to an empty library with folders to choose',
      () async {
        await controller().start();

        await controller().confirmFolders({});

        expect(
          state(),
          isA<LibraryReady>().having((s) => s.hasFolders, 'hasFolders', false),
        );
      },
    );

    /// @verifies FR-003
    test('later launches go straight to the library and reindex', () async {
      await controller().start();
      await controller().confirmFolders({'Music'});
      source.files = [...source.files, info('Music/c.mp3')];
      container.dispose();
      container = create();

      await controller().start();

      expect(state(), isA<LibraryReady>());
      expect(repository.tracks, hasLength(3));
    });

    /// @verifies FR-003
    test('refresh reindexes', () async {
      await controller().start();
      await controller().confirmFolders({'Music'});
      source.files = [info('Music/a.mp3')];

      await controller().refresh();

      expect(repository.tracks, hasLength(1));
      expect(
        state(),
        isA<LibraryReady>().having((s) => s.indexing, 'indexing', false),
      );
    });

    /// @verifies FR-003
    test('indexing is visible while it runs', () async {
      await controller().start();
      final states = <LibraryViewState>[];
      container.listen(
        libraryControllerProvider,
        (_, next) => states.add(next),
      );

      await controller().confirmFolders({'Music'});

      expect(states.whereType<LibraryReady>().map((s) => s.indexing), [
        true,
        false,
      ]);
    });

    /// @verifies FR-003
    test('the folder choice can be reopened with the current choice', () async {
      await controller().start();
      await controller().confirmFolders({'Music', 'Ringtones'});

      await controller().openFolderChoice();

      expect((state() as LibraryFolderChoice).selected, {'Music', 'Ringtones'});
    });

    /// @verifies UC-001
    test('a failing folder query on first launch offers a retry', () async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(repository),
          internalAudioSourceProvider.overrideWithValue(FailingAudioSource()),
          audioPermissionProvider.overrideWithValue(permission),
        ],
      );

      await controller().start();

      expect(state(), isA<LibraryLoadFailed>());
    });

    test('the folder choice does not open while indexing', () async {
      await controller().start();
      final confirming = controller().confirmFolders({'Music'});

      await controller().openFolderChoice();
      await confirming;

      expect(state(), isA<LibraryReady>());
    });

    test('a failing index leaves the library usable', () async {
      await controller().start();
      await controller().confirmFolders({'Music'});
      source.files = [];
      final failing = FailingAudioSource();
      container.dispose();
      container = ProviderContainer(
        overrides: [
          libraryRepositoryProvider.overrideWithValue(repository),
          internalAudioSourceProvider.overrideWithValue(failing),
          audioPermissionProvider.overrideWithValue(permission),
        ],
      );

      await controller().start();

      expect(
        state(),
        isA<LibraryReady>()
            .having((s) => s.indexing, 'indexing', false)
            .having((s) => s.indexFailed, 'indexFailed', true),
      );
      expect(repository.tracks, hasLength(2));
    });
  });
}

class FailingAudioSource implements InternalAudioSource {
  @override
  Future<List<Never>> queryAudio() async => throw Exception('MediaStore down');
}
