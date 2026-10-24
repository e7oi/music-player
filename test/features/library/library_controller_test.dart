import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/app/providers/library_providers.dart';
import 'package:tuneshell/app/providers/player_providers.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/features/library/library_controller.dart';

import '../../fakes/fake_library.dart';
import '../../fakes/fake_storage.dart';

void main() {
  late FakeLibraryRepository repository;
  late FakeInternalAudioSource source;
  late FakeAudioPermission permission;
  late FakeRemovableAudioSource removable;
  late ProviderContainer container;

  ProviderContainer create([InternalAudioSource? audio]) => ProviderContainer(
    overrides: [
      libraryRepositoryProvider.overrideWithValue(repository),
      internalAudioSourceProvider.overrideWithValue(audio ?? source),
      audioPermissionProvider.overrideWithValue(permission),
      removableAudioSourceProvider.overrideWithValue(removable),
      tagReaderProvider.overrideWithValue(FakeTagReader()),
      volumeEventsProvider.overrideWithValue(FakeVolumeEvents({internalDisk})),
    ],
  );

  LibraryViewState state() => container.read(libraryControllerProvider);

  LibraryController controller() =>
      container.read(libraryControllerProvider.notifier);

  bool cancelable() => switch (state()) {
    LibraryFolderChoice(:final cancelable) => cancelable,
    LibraryLoadFailed(:final cancelable) => cancelable,
    _ => false,
  };

  setUp(() {
    repository = FakeLibraryRepository();
    source = FakeInternalAudioSource()
      ..files = [
        info('Music/a.mp3'),
        info('Music/b.mp3'),
        info('Ringtones/r.ogg'),
      ];
    permission = FakeAudioPermission(AudioPermissionStatus.notRequested);
    removable = FakeRemovableAudioSource();
    container = create();
  });

  tearDown(() => container.dispose());

  group('FR-004 permission', () {
    /// @verifies FR-014.1
    test('first launch shows the welcome and does not ask yet', () async {
      await controller().start();

      expect(permission.requests, 0);
      expect(
        state(),
        isA<LibraryWelcome>().having((s) => s.explaining, 'explaining', false),
      );
    });

    /// @verifies FR-014.2
    test('the explanation comes before the Android dialog', () async {
      await controller().start();

      controller().showExplanation();

      expect(permission.requests, 0);
      expect(
        state(),
        isA<LibraryWelcome>().having((s) => s.explaining, 'explaining', true),
      );
    });

    /// @verifies FR-004
    /// @verifies FR-014.2
    test('the button asks once, then offers the folders', () async {
      await controller().start();

      await controller().requestPermission();

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
      await controller().requestPermission();

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
      await controller().requestPermission();
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

    /// @verifies FR-004
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

    /// @verifies FR-014.6
    group('not now', () {
      setUp(() async {
        await controller().start();
        controller().declineAccess();
      });

      test('shows the library without access and indexes nothing', () {
        expect(state(), isA<LibraryAccessDeclined>());
        expect(permission.requests, 0);
        expect(repository.tracks, isEmpty);
      });

      test('returning to the app keeps it, nothing was refused', () async {
        await controller().onResumed();

        expect(state(), isA<LibraryAccessDeclined>());
      });

      test('the offer leads back to the explanation', () {
        controller().showExplanation();

        expect(
          state(),
          isA<LibraryWelcome>().having((s) => s.explaining, 'explaining', true),
        );
      });

      test('access granted in the settings is picked up', () async {
        permission.current = AudioPermissionStatus.granted;

        await controller().onResumed();

        expect(state(), isA<LibraryFolderChoice>());
      });
    });

    /// @verifies FR-014.4
    test('the welcome stays when the app returns before any request', () async {
      await controller().start();
      final before = state();

      await controller().onResumed();

      expect(state(), same(before));
    });

    /// @verifies FR-015.3
    test('the folder list is first shown as loading', () async {
      permission.current = AudioPermissionStatus.granted;
      final states = <LibraryViewState>[];
      container.listen(
        libraryControllerProvider,
        (_, next) => states.add(next),
      );

      await controller().start();

      final choices = states.whereType<LibraryFolderChoice>().toList();
      expect(choices.first.loading, isTrue);
      expect(choices.last.loading, isFalse);
      expect(choices.last.folders, isNotEmpty);
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

    /// @verifies FR-003.4 the choice opened by the user can be left unchanged.
    test('cancelling the folder choice goes back to the library', () async {
      await controller().start();
      await controller().confirmFolders({'Music'});
      await controller().openFolderChoice();
      expect(cancelable(), isTrue);

      controller().cancelFolderChoice();

      expect(state(), isA<LibraryReady>());
      expect((state() as LibraryReady).hasFolders, isTrue);
      expect(cancelable(), isFalse);
      expect(repository.tracks, hasLength(2));
    });

    /// @verifies FR-003.3 the first choice is not optional.
    test('the first folder choice cannot be cancelled', () async {
      await controller().start();

      expect(state(), isA<LibraryFolderChoice>());
      expect(cancelable(), isFalse);
      controller().cancelFolderChoice();
      expect(state(), isA<LibraryFolderChoice>());
    });

    test('confirming after reopening ends the choice for good', () async {
      await controller().start();
      await controller().confirmFolders({'Music'});
      await controller().openFolderChoice();

      await controller().confirmFolders({'Music', 'Ringtones'});

      expect(state(), isA<LibraryReady>());
      expect(cancelable(), isFalse);
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

    /// @verifies FR-003
    /// @verifies FR-003.4
    test(
      'leaving the folder choice while it loads keeps the library',
      () async {
        await controller().start();
        await controller().confirmFolders({'Music'});

        final opening = controller().openFolderChoice();
        controller().cancelFolderChoice();
        await opening;

        expect(state(), isA<LibraryReady>());
      },
    );

    test('the folder choice does not open while indexing', () async {
      await controller().start();
      final confirming = controller().confirmFolders({'Music'});

      await controller().openFolderChoice();
      await confirming;

      expect(state(), isA<LibraryReady>());
    });

    /// @verifies UC-001
    test(
      'retry after a failed folder list reopens the folder choice',
      () async {
        await controller().start();
        await controller().confirmFolders({'Music'});
        container.dispose();
        container = ProviderContainer(
          overrides: [
            libraryRepositoryProvider.overrideWithValue(repository),
            internalAudioSourceProvider.overrideWithValue(FailingAudioSource()),
            audioPermissionProvider.overrideWithValue(permission),
          ],
        );
        await controller().openFolderChoice();
        expect(
          state(),
          isA<LibraryLoadFailed>().having(
            (s) => s.whileChoosingFolders,
            'folders',
            true,
          ),
        );
      },
    );

    test('resume and request continuing together run once', () async {
      permission.current = AudioPermissionStatus.denied;
      await controller().start();
      permission
        ..answer = AudioPermissionStatus.granted
        ..current = AudioPermissionStatus.granted;
      final states = <LibraryViewState>[];
      container.listen(
        libraryControllerProvider,
        (_, next) => states.add(next),
      );

      await Future.wait([
        controller().requestPermission(),
        controller().onResumed(),
      ]);

      expect(
        states.whereType<LibraryFolderChoice>().where((s) => !s.loading),
        hasLength(1),
      );
    });

    test('a failing index leaves the library usable', () async {
      await controller().start();
      await controller().confirmFolders({'Music'});
      source.files = [];
      final failing = FailingAudioSource();
      container.dispose();
      container = create(failing);

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
