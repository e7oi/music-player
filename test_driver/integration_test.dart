import 'package:integration_test/integration_test_driver.dart';

/// Host side of `flutter drive`, which can build in release mode (D14) where
/// `flutter test integration_test` cannot.
Future<void> main() => integrationDriver();
