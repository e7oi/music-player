import 'dart:async';

import 'package:tuneshell/domain/library/model/file_tags.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/model/track.dart';
import 'package:tuneshell/domain/library/ports/internal_audio_source.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/library/ports/tag_reader.dart';

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
    _disks[disk.id] = disk;
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

  @override
  Future<List<Disk>> disks() async => _disks.values.toList();

  @override
  Future<IndexResult> applyScan(DiskId disk, List<TrackInfo> found) async {
    var added = 0;
    var updated = 0;
    final byPath = {for (final i in found) i.relativePath: i};
    final removed = _tracks
        .where(
          (t) => t.disk == disk && !byPath.containsKey(t.info.relativePath),
        )
        .toList();
    _tracks.removeWhere(removed.contains);
    for (final entry in byPath.values) {
      final index = _tracks.indexWhere(
        (t) => t.disk == disk && t.info.relativePath == entry.relativePath,
      );
      if (index < 0) {
        _tracks.add(LibraryTrack(id: _nextId++, disk: disk, info: entry));
        added++;
      } else if (!_tracks[index].info.sameFileAs(entry)) {
        _tracks[index] = LibraryTrack(
          id: _tracks[index].id,
          disk: disk,
          info: entry,
          artwork: _tracks[index].artwork,
        );
        updated++;
      }
    }
    _changes.add(_sorted());
    return IndexResult(added: added, updated: updated, removed: removed.length);
  }

  @override
  Future<List<PendingTrack>> pendingTracks(
    Set<DiskId> disks,
    int limit,
  ) async => [
    for (final t in _tracks)
      if (disks.contains(t.disk) && t.tagsState == TagsState.pending)
        PendingTrack(id: t.id, track: t.track),
  ].take(limit).toList();

  @override
  Future<int> countPending(Set<DiskId> disks) async => _tracks
      .where((t) => disks.contains(t.disk) && t.tagsState == TagsState.pending)
      .length;

  @override
  Future<void> resetFailedTags(Set<DiskId> disks) async {
    for (var i = 0; i < _tracks.length; i++) {
      final t = _tracks[i];
      if (disks.contains(t.disk) && t.tagsState == TagsState.failed) {
        _tracks[i] = LibraryTrack(
          id: t.id,
          disk: t.disk,
          info: t.info,
          artwork: t.artwork,
        );
      }
    }
  }

  @override
  Future<int> trackCount(DiskId disk) async =>
      _tracks.where((t) => t.disk == disk).length;

  @override
  Future<void> applyFileTags(List<TagUpdate> updates) async {
    for (final update in updates) {
      final index = _tracks.indexWhere((t) => t.id == update.trackId);
      if (index < 0) continue;
      final track = _tracks[index];
      final tags = update.tags;
      _tracks[index] = LibraryTrack(
        id: track.id,
        disk: track.disk,
        info: tags != null && update.writeTags
            ? TrackInfo(
                relativePath: track.info.relativePath,
                size: track.info.size,
                modifiedAt: track.info.modifiedAt,
                title: tags.title,
                artist: tags.artist,
                album: tags.album,
                duration: tags.duration,
              )
            : track.info,
        artwork: tags?.artwork ?? track.artwork,
        tagsState: tags == null ? TagsState.failed : TagsState.done,
      );
    }
    _changes.add(_sorted());
  }

  @override
  Future<Set<String>> artworkInUse() async => {
    for (final t in _tracks)
      if (t.artwork != null) t.artwork!,
  };

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

class FakeRemovableAudioSource implements RemovableAudioSource {
  /// What the picker returns next; null is a cancel.
  RemovableFolder? picked;

  List<MountedVolume> mounted = [];
  Set<RemovableFolder> granted = {};

  /// Files of each (disk, folder).
  final Map<(DiskId, String), List<TrackInfo>> files = {};

  /// Scans of these folders throw this.
  final Map<(DiskId, String), Exception> failing = {};
  final List<(DiskId, String)> released = [];
  final List<(DiskId, String)> scanned = [];
  int cancels = 0;

  /// The next [pickFolder] throws this, as for a folder of the phone.
  Exception? pickError;

  @override
  Future<RemovableFolder?> pickFolder() async {
    final error = pickError;
    if (error != null) throw error;
    return picked;
  }

  @override
  Future<Set<RemovableFolder>> grantedFolders() async => {...granted};

  @override
  Future<List<MountedVolume>> mountedVolumes() async => [...mounted];

  @override
  Future<void> releaseFolder(DiskId disk, String path) async =>
      released.add((disk, path));

  @override
  Future<List<TrackInfo>> scan(DiskId disk, String folder) async {
    scanned.add((disk, folder));
    final error = failing[(disk, folder)];
    if (error != null) throw error;
    return [...?files[(disk, folder)]];
  }

  @override
  Future<void> cancelScan() async => cancels++;
}

class FakeTagReader implements TagReader {
  /// Tags per track; a missing entry reads as nothing.
  final Map<Track, FileTags> tags = {};
  final Set<Track> throwing = {};

  /// Reads of these tracks throw [RemovableAccessException].
  final Set<Track> accessLost = {};
  final List<Track> reads = [];
  Set<String>? retained;

  /// Called at each read, to observe or cancel in the middle of a run.
  void Function(Track track)? onRead;

  int active = 0;
  int maxActive = 0;

  @override
  Future<FileTags?> read(Track track) async {
    active++;
    if (active > maxActive) maxActive = active;
    reads.add(track);
    onRead?.call(track);
    await Future<void>.delayed(Duration.zero);
    active--;
    if (accessLost.contains(track)) throw const RemovableAccessException();
    if (throwing.contains(track)) throw Exception('unreadable');
    return tags[track];
  }

  @override
  Future<void> retainArtwork(Set<String> keep) async => retained = keep;
}
