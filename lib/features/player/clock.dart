/// A playback time as `m:ss`, or `h:mm:ss` from one hour.
String formatClock(Duration time) {
  final seconds = time.isNegative ? 0 : time.inSeconds;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
