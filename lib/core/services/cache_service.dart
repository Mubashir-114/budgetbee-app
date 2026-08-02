import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._();

  static SharedPreferences? _prefs;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> save(String key, dynamic data) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.setString(key, json.encode(data));
    } catch (_) {
      // Fail silently for cache operations
    }
  }

  static Future<dynamic> get(String key) async {
    try {
      if (_prefs == null) await initialize();
      final value = _prefs?.getString(key);
      if (value == null) return null;
      return json.decode(value);
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.remove(key);
    } catch (_) {
      // Fail silently
    }
  }

  static Future<void> clearAll() async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.clear();
    } catch (_) {
      // Fail silently
    }
  }
}
