import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuneshell/platform/gesture_exclusion_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(GestureExclusionChannel.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  /// @verifies FR-010.5
  test('sends the rectangles in whole physical pixels', () async {
    await GestureExclusionChannel().setRects([
      const Rect.fromLTRB(1050.4, 600.5, 1080, 792.6),
    ]);

    expect(calls.single.method, 'setRects');
    expect(calls.single.arguments, [
      {'left': 1050, 'top': 601, 'right': 1080, 'bottom': 793},
    ]);
  });

  test('an empty list gives the edge back to the system', () async {
    await GestureExclusionChannel().setRects(const []);

    expect(calls.single.arguments, isEmpty);
  });
}
