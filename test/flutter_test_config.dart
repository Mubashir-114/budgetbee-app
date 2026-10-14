import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Mock SharedPreferences so all tests with preferences complete without platform channel stalls
  SharedPreferences.setMockInitialValues({});

  // In Flutter headless widget testing with Material 3 (TargetPlatform.android),
  // interactive widgets use InkSparkle.splashFactory, which requires 'shaders/ink_sparkle.frag'
  // to be present in the unit test asset directory (build/unit_test_assets/shaders/ink_sparkle.frag).
  final target = File('build/unit_test_assets/shaders/ink_sparkle.frag');
  if (!target.existsSync()) {
    target.parent.createSync(recursive: true);
    final source = File('test/assets/shaders/ink_sparkle.frag');
    if (source.existsSync()) {
      source.copySync(target.path);
    }
  }
  await testMain();
}
