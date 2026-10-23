import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tuneshell/platform/gesture_exclusion_channel.dart';

final gestureExclusionProvider = Provider<GestureExclusionChannel>(
  (ref) => GestureExclusionChannel(),
);
