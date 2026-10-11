import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  static const String _defaultBaseUrl =
      'https://expense-manager-api-qn07.onrender.com/api/';

  static const String _localLoopbackUrl = 'http://127.0.0.1:5000/api/';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:5000/api/';

  static String get baseUrl {
    // 1. Explicit override via --dart-define=BASE_URL=... takes top priority
    const overrideUrl = String.fromEnvironment('BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl.endsWith('/') ? overrideUrl : '$overrideUrl/';
    }

    // 2. In debug mode, automatically connect to local development backend
    if (kDebugMode) {
      if (kIsWeb) {
        return _localLoopbackUrl;
      }
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return _androidEmulatorUrl;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.iOS:
        default:
          return _localLoopbackUrl;
      }
    }

    // 3. Fallback to production/release url
    return _defaultBaseUrl;
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}