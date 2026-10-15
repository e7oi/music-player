/// What the audio engine reads for one track.
///
/// @decision D25: internal storage is read by file path; removable storage is
/// read through a detached SAF descriptor (`fd://N`), never a `content://` URI.
sealed class MediaSource {
  const new();
}

/// A file the engine opens by path.
final class FileMediaSource extends MediaSource {
  const new(this.path);

  final String path;
}

/// A file descriptor already opened for the engine.
///
/// The engine owns the descriptor once [MediaSource] is passed to
/// `AudioEngine.open`: it calls [release] exactly once, after it has stopped
/// reading. Nobody else closes the descriptor, because closing it under the
/// engine is what lets Android kill the app on ejection (BR-002).
final class DescriptorMediaSource extends MediaSource {
  const new({required this.fd, required this.release});

  final int fd;
  final Future<void> Function() release;
}
