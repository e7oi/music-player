import 'dart:async';

import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';
import 'package:tuneshell/domain/library/ports/removable_audio_source.dart';
import 'package:tuneshell/domain/library/ports/tag_reader.dart';
import 'package:tuneshell/domain/storage/ports/volume_events.dart';

@immutable
final class TagProgress {
  const new({required this.done, required this.total});

  static const idle = TagProgress(done: 0, total: 0);

  final int done;
  final int total;

  bool get running => done < total;
}

/// Reads the tags and artwork of the files in the background.
///
/// @implements FR-007
/// @implements BR-006
class TagIndexer {
  new({
    required this._repository,
    required this._reader,
    required this._volumes,
    this.parallelism = 2,
    this.batchSize = 50,
  });

  /// Files read at once. Not measured on the Pixel yet (BR-006.4, ADR-009,
  /// HOWTO section 13).
  final int parallelism;

  /// Files stored per transaction: the library list is redrawn once per
  /// batch (FR-007.9).
  final int batchSize;

  final LibraryRepository _repository;
  final TagReader _reader;
  final VolumeEvents _volumes;
  final _progress = StreamController<TagProgress>.broadcast();
  TagProgress _last = TagProgress.idle;
  Future<void>? _running;
  bool _cancelled = false;

  /// A read found the disk or its access gone: the pass ends, nothing else
  /// is marked failed (FR-007.3).
  bool _diskGone = false;

  TagProgress get progress => _last;
  Stream<TagProgress> get progressStream => _progress.stream;

  /// Reads every pending track of the available disks. A call while a run
  /// is going joins it. [retryFailed] gives the unreadable files another
  /// chance: only an explicit refresh asks for it (FR-007.3).
  Future<void> run({bool retryFailed = false}) =>
      _running ??= _run(retryFailed: retryFailed)
          .whenComplete(() => _running = null);

  /// Stops after the files being read; the others stay pending (BR-006.5,
  /// .6).
  void cancel() => _cancelled = true;

  Future<void> _run({required bool retryFailed}) async {
    _cancelled = false;
    _diskGone = false;
    var done = 0;
    final disks = await _volumes.availableDisks();
    if (retryFailed) await _repository.resetFailedTags(disks);
    final total = await _repository.countPending(disks);
    _emit(TagProgress(done: 0, total: total));
    try {
      while (!_cancelled && !_diskGone) {
        final batch = await _repository.pendingTracks(disks, batchSize);
        if (batch.isEmpty) break;
        final updates = await _readBatch(batch);
        // Whatever was read is stored, even if a cancel came in between.
        await _repository.applyFileTags(updates);
        done += updates.length;
        _emit(TagProgress(done: done, total: total));
      }
    } finally {
      _emit(TagProgress.idle);
    }
    if (!_cancelled && !_diskGone) {
      await _reader.retainArtwork(await _repository.artworkInUse());
    }
  }

  /// Reads [batch] with at most [parallelism] files open at once. Tracks not
  /// started when a cancel arrives are left out, hence still pending.
  Future<List<TagUpdate>> _readBatch(List<PendingTrack> batch) async {
    final updates = <TagUpdate>[];
    var next = 0;
    Future<void> worker() async {
      while (!_cancelled && !_diskGone && next < batch.length) {
        final item = batch[next++];
        final update = await _readOne(item);
        if (update != null) updates.add(update);
      }
    }

    await Future.wait([for (var i = 0; i < parallelism; i++) worker()]);
    return updates;
  }

  /// Null leaves the track pending: its disk went away, which says nothing
  /// about the file.
  Future<TagUpdate?> _readOne(PendingTrack item) async {
    try {
      final tags = await _reader.read(item.track);
      if (tags == null) return TagUpdate.failed(item.id);
      return TagUpdate.read(
        item.id,
        tags,
        writeTags: item.track.disk != internalDisk,
      );
    } on RemovableAccessException {
      _diskGone = true;
      return null;
    } on Exception {
      // An unreadable file, or a disk that went away during the read.
      final disks = await _volumes.availableDisks();
      if (!disks.contains(item.track.disk)) {
        _diskGone = true;
        return null;
      }
      return TagUpdate.failed(item.id);
    }
  }

  void _emit(TagProgress value) {
    _last = value;
    _progress.add(value);
  }
}
