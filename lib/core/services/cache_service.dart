import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._();

  static const String _cachePrefix = 'fintrack_cache_';
  static const String _userPreferencePrefix = 'fintrack_user_';

  static SharedPreferences? _prefs;
  static int? _userId;

  static int? get userId => _userId;

  static void setUserId(int? userId) {
    _userId = userId;
  }

  static String userScopedKey(String key) {
    return '$_userPreferencePrefix${_userId ?? 'anonymous'}_$key';
  }

  static String _cacheKey(String key) {
    return '$_cachePrefix${_userId ?? 'anonymous'}_$key';
  }

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> save(String key, dynamic data) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.setString(_cacheKey(key), json.encode(data));
    } catch (_) {
      // Fail silently for cache operations
    }
  }

  static Future<dynamic> get(String key) async {
    final storageKey = _cacheKey(key);
    try {
      if (_prefs == null) await initialize();
      final value = _prefs?.getString(storageKey);
      if (value == null) return null;
      return json.decode(value);
    } on FormatException {
      await _prefs?.remove(storageKey);
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    try {
      if (_prefs == null) await initialize();
      await _prefs?.remove(_cacheKey(key));
    } catch (_) {
      // Fail silently
    }
  }

  static Future<void> clearAll() async {
    try {
      if (_prefs == null) await initialize();
      final keys = _prefs!.getKeys().where((key) {
        return key.startsWith(_cachePrefix) ||
            key.startsWith(_userPreferencePrefix) ||
            key == 'dashboard_cache' ||
            key.startsWith('transactions_') ||
            key.startsWith('budget_status_') ||
            key == 'last_sms_import_time';
      }).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    } catch (_) {
      // Fail silently
    }
  }
}
