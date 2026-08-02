import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    String url = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000/api/';
    
    // Automatically swap 10.0.2.2 to localhost on non-Android platforms (like Web, iOS, Desktop)
    if (url.contains('10.0.2.2')) {
      final isAndroid = !kIsWeb && Platform.isAndroid;
      if (!isAndroid) {
        url = url.replaceAll('10.0.2.2', 'localhost');
      }
    }
    return url;
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}