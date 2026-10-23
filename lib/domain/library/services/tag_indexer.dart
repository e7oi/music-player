import 'dart:async';

import 'package:meta/meta.dart';
import 'package:tuneshell/domain/library/model/library_track.dart';
import 'package:tuneshell/domain/library/ports/library_repository.dart';
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

  /// Files read at once. Measured on the Pixel (BR-006.4, ADR-009).
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

  TagProgress get progress => _last;
  Stream<TagProgress> get progressStream => _progress.stream;

  /// Reads every pending track of the available disks. A call while a run
  /// is going joins it.
  Future<void> run() => _running ??= _run().whenComplete(() => _running = null);

  /// Stops after the files being read; the others stay pending (BR-006.5,
  /// .6).
  void cancel() => _cancelled = true;

  Future<void> _run() async {
    _cancelled = false;
    var done = 0;
    final disks = await _volumes.availableDisks();
    final total = await _repository.countPending(disks);
    _emit(TagProgress(done: 0, total: total));
    while (!_cancelled) {
      final batch = await _repository.pendingTracks(disks, batchSize);
      if (batch.isEmpty) break;
      final updates = await _readBatch(batch);
      // Whatever was read is stored, even if a cancel came in between.
      await _repository.applyFileTags(updates);
      done += updates.length;
      _emit(TagProgress(done: done, total: total));
    }
    _emit(TagProgress.idle);
    if (!_cancelled) {
      await _reader.retainArtwork(await _repository.artworkInUse());
    }
  }

  /// Reads [batch] with at most [parallelism] files open at once. Tracks not
  /// started when a cancel arrives are left out, hence still pending.
  Future<List<TagUpdate>> _readBatch(List<PendingTrack> batch) async {
    final updates = <TagUpdate>[];
    var next = 0;
    Future<void> worker() async {
      while (!_cancelled && next < batch.length) {
        final item = batch[next++];
        updates.add(await _readOne(item));
      }
    }

    await Future.wait([for (var i = 0; i < parallelism; i++) worker()]);
    return updates;
  }

  Future<TagUpdate> _readOne(PendingTrack item) async {
    try {
      final tags = await _reader.read(item.track);
      if (tags == null) return TagUpdate.failed(item.id);
      return TagUpdate.read(
        item.id,
        tags,
        writeTags: item.track.disk != internalDisk,
      );
    } on Exception {
      return TagUpdate.failed(item.id);
    }
  }

  void _emit(TagProgress value) {
    _last = value;
    _progress.add(value);
  }
}
