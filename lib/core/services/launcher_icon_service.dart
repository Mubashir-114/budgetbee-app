import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../theme/theme_collection.dart';

/// Service managing native Android launcher icons synchronized with FinTrack themes.
class LauncherIconService {
  static const MethodChannel _channel =
      MethodChannel('com.mkl.financemanager/launcher_icon');

  /// Maps [ThemeCollection] to native icon keys.
  static String iconKeyFor(ThemeCollection collection) => collection.storageKey;

  /// Changes the Android launcher icon to correspond to the given [collection].
  /// Returns `true` if updated successfully, `false` otherwise.
  /// Gracefully no-ops on non-Android platforms or if native calls fail.
  static Future<bool> setLauncherIcon(ThemeCollection collection) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final success = await _channel.invokeMethod<bool>('setLauncherIcon', {
        'iconKey': iconKeyFor(collection),
      });
      return success ?? false;
    } catch (e) {
      debugPrint('LauncherIconService.setLauncherIcon error: $e');
      return false;
    }
  }

  /// Queries the currently active launcher icon alias key on Android.
  static Future<String?> getCurrentLauncherIcon() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('getCurrentLauncherIcon');
    } catch (e) {
      debugPrint('LauncherIconService.getCurrentLauncherIcon error: $e');
      return null;
    }
  }

  /// Reconciles launcher icon at app startup with the persisted [collection].
  /// Safely no-ops if the active alias already matches the collection.
  static Future<void> reconcile(ThemeCollection collection) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      final currentKey = await getCurrentLauncherIcon();
      final targetKey = iconKeyFor(collection);
      if (currentKey != targetKey) {
        await setLauncherIcon(collection);
      }
    } catch (e) {
      debugPrint('LauncherIconService.reconcile error: $e');
    }
  }
}
