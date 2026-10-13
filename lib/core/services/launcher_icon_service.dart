import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../theme/theme_collection.dart';

/// Keeps the Android launcher icon aligned with the selected brand collection.
class LauncherIconService {
  static const MethodChannel _channel = MethodChannel(
    'com.mkl.financemanager/launcher_icon',
  );

  static Future<void> _pendingSync = Future<void>.value();

  static String iconKeyFor(ThemeCollection collection) =>
      collection.launcherIconKey;

  /// Serializes reconciliation so rapid theme changes cannot finish out of order.
  static Future<bool> synchronize(ThemeCollection collection) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return Future<bool>.value(false);
    }

    final completer = Completer<bool>();
    _pendingSync = _pendingSync.then((_) async {
      final targetKey = iconKeyFor(collection);
      try {
        final currentKey = await _channel.invokeMethod<String>(
          'getCurrentLauncherIcon',
        );
        if (currentKey == targetKey) {
          completer.complete(true);
          return;
        }

        final success = await _channel.invokeMethod<bool>('setLauncherIcon', {
          'iconKey': targetKey,
        });
        completer.complete(success ?? false);
      } on PlatformException catch (error) {
        debugPrint('Launcher icon synchronization failed: ${error.code}');
        completer.complete(false);
      } on MissingPluginException {
        // Expected on unsupported embedders and during some test/bootstrap flows.
        completer.complete(false);
      } catch (error) {
        debugPrint('Launcher icon synchronization failed: $error');
        completer.complete(false);
      }
    });
    return completer.future;
  }
}
