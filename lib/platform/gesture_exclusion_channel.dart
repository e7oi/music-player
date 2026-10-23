import 'package:flutter/services.dart';

/// Dart side of `GestureExclusionChannel.kt` (ADR-010): tells Android which
/// parts of the window must not start the system Back gesture. Used for the
/// handle of the alphabet index, which sits against the screen edge.
class GestureExclusionChannel {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'net.trtl3.tuneshell/gesture_exclusion';

  final MethodChannel _channel;

  /// Replaces the excluded rectangles, in physical pixels. An empty list
  /// gives the whole edge back to the system.
  Future<void> setRects(List<Rect> rects) =>
      _channel.invokeMethod<void>('setRects', [
        for (final rect in rects)
          {
            'left': rect.left.round(),
            'top': rect.top.round(),
            'right': rect.right.round(),
            'bottom': rect.bottom.round(),
          },
      ]);
}
