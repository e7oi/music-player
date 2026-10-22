import 'dart:async';

import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';

TrackInfo info(
  String relativePath, {
  String? title,
  int size = 1000,
  int modified = 1,
}) => TrackInfo(
  relativePath: relativePath,
  size: size,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(modified * 1000),
  title: title,
);

/// In-memory [LibraryRepository] with the semantics of the Drift one.
class FakeLibraryRepository implements LibraryRepository {
  final Map<DiskId, Disk> _disks = {};
  final Map<DiskId, Set<String>> _folders = {};
  final List<LibraryTrack> _tracks = [];
  final _changes = StreamController<List<LibraryTrack>>.broadcast();
  int _nextId = 1;

  List<LibraryTrack> get tracks => List.unmodifiable(_tracks);

  @override
  Future<Disk?> disk(DiskId id) async => _disks[id];

  @override
  Future<void> ensureDisk(Disk disk) async =>
      _disks.putIfAbsent(disk.id, () => disk);

  @override
  Future<Set<String>> chosenFolders(DiskId disk) async => {...?_folders[disk]};

  @override
  Future<void> setChosenFolders(Disk disk, Set<String> folders) async {
    _disks.putIfAbsent(disk.id, () => disk);
    _folders[disk.id] = {...folders};
  }

  @override
  Stream<List<LibraryTrack>> watchTracks() async* {
    yield _sorted();
    yield* _changes.stream;
  }

  @override
  Future<IndexResult> applyIndex(DiskId disk, List<TrackInfo> found) async {
    var added = 0;
    var updated = 0;
    final byPath = {for (final i in found) i.relativePath: i};
    final before = _tracks.where((t) => t.disk == disk).toList();
    final removed = before.where(
      (t) => !byPath.containsKey(t.info.relativePath),
    );
    final removedCount = removed.length;
    _tracks.removeWhere(removed.toList().contains);
    for (final entry in byPath.values) {
      final index = _tracks.indexWhere(
        (t) => t.disk == disk && t.info.relativePath == entry.relativePath,
      );
      if (index < 0) {
        _tracks.add(LibraryTrack(id: _nextId++, disk: disk, info: entry));
        added++;
      } else if (_tracks[index].info != entry) {
        _tracks[index] = LibraryTrack(
          id: _tracks[index].id,
          disk: disk,
          info: entry,
        );
        updated++;
      }
    }
    _changes.add(_sorted());
    return IndexResult(added: added, updated: updated, removed: removedCount);
  }

  List<LibraryTrack> _sorted() =>
      [..._tracks]..sort((a, b) => a.displayTitle.compareTo(b.displayTitle));
}

class FakeInternalAudioSource implements InternalAudioSource {
  List<TrackInfo> files = [];
  int queries = 0;

  @override
  Future<List<TrackInfo>> queryAudio() async {
    queries++;
    return [...files];
  }
}

class FakeAudioPermission implements AudioPermission {
  new(this.current);

  AudioPermissionStatus current;

  /// What the Android dialog answers to the next [request].
  AudioPermissionStatus answer = AudioPermissionStatus.granted;

  /// The next [request] fails, as when a request is already running.
  bool failNextRequest = false;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<AudioPermissionStatus> status() async => current;

  @override
  Future<AudioPermissionStatus> request() async {
    if (failNextRequest) {
      failNextRequest = false;
      throw Exception('request_pending');
    }
    requests++;
    return current = answer;
  }

  @override
  Future<void> openAppSettings() async => settingsOpened++;
}
