import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/cache_service.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_collection.dart';
import '../core/theme/fin_track_theme_tokens.dart';

/// Provider for active theme collection and display mode preferences.
/// Supports immediate switching without restart and persists across launches.
class ThemeProvider extends ChangeNotifier {
  static const String prefThemeCollectionKey = 'fintrack_theme_collection';
  static const String prefDisplayModeKey = 'fintrack_display_mode';

  ThemeCollection _collection = ThemeCollection.graphiteChampagne;
  AppDisplayMode _displayMode = AppDisplayMode.system;
  bool _isInitialized = false;

  ThemeProvider() {
    _loadPreferences();
  }

  ThemeCollection get collection => _collection;
  AppDisplayMode get displayMode => _displayMode;
  ThemeMode get themeMode => _displayMode.themeMode;
  bool get isInitialized => _isInitialized;

  ThemeData get lightTheme =>
      AppTheme.buildTheme(_collection, Brightness.light);

  ThemeData get darkTheme =>
      AppTheme.buildTheme(_collection, Brightness.dark);

  FinTrackThemeTokens tokensFor(Brightness brightness) =>
      FinTrackThemeTokens.resolve(_collection, brightness);

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Theme collection (Default is Graphite & Champagne for new installs)
      final savedCollection = prefs.getString(prefThemeCollectionKey);
      if (savedCollection != null) {
        _collection = ThemeCollection.fromKey(savedCollection);
      } else {
        final cached = await CacheService.get('theme_collection');
        if (cached is String) {
          _collection = ThemeCollection.fromKey(cached);
        }
      }

      // 2. Display mode (Default is System)
      final savedMode = prefs.getString(prefDisplayModeKey);
      if (savedMode != null) {
        _displayMode = AppDisplayMode.fromKey(savedMode);
      } else {
        final cached = await CacheService.get('display_mode');
        if (cached is String) {
          _displayMode = AppDisplayMode.fromKey(cached);
        }
      }

      _isInitialized = true;
      notifyListeners();
    } catch (_) {
      _isInitialized = true;
    }
  }

  Future<void> setCollection(ThemeCollection collection) async {
    if (_collection == collection) return;
    _collection = collection;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefThemeCollectionKey, collection.storageKey);
      await CacheService.save('theme_collection', collection.storageKey);
    } catch (_) {}
  }

  Future<void> setDisplayMode(AppDisplayMode mode) async {
    if (_displayMode == mode) return;
    _displayMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefDisplayModeKey, mode.storageKey);
      await CacheService.save('display_mode', mode.storageKey);
    } catch (_) {}
  }
}
