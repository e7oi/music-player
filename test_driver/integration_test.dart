import 'package:integration_test/integration_test_driver.dart';

/// Host side of `flutter drive`, which can build in profile mode (AOT, like
/// release) where `flutter test integration_test` only builds in debug.
/// `flutter drive` refuses release mode.
Future<void> main() => integrationDriver();
