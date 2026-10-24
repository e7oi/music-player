import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/platform/gesture_exclusion_channel.dart';

final gestureExclusionProvider = Provider<GestureExclusionChannel>(
  (ref) => GestureExclusionChannel(),
);

/// The rectangles kept out of the Back gesture, by owner. The channel keeps
/// only the last report, and several views of the shell carry an index: each
/// reports under its own key and the union goes to the channel (ADR-016).
///
/// @decision ADR-016
class GestureRegions {
  new(this._send);

  final Future<void> Function(List<Rect> rects) _send;
  final Map<Object, List<Rect>> _owners = {};

  /// Replaces the rectangles of [owner], in physical pixels; an empty list
  /// removes the owner.
  Future<void> set(Object owner, List<Rect> rects) {
    if (rects.isEmpty) {
      _owners.remove(owner);
    } else {
      _owners[owner] = List.of(rects);
    }
    return _send([for (final list in _owners.values) ...list]);
  }
}

final gestureRegionsProvider = Provider<GestureRegions>(
  (ref) => GestureRegions(ref.watch(gestureExclusionProvider).setRects),
);
