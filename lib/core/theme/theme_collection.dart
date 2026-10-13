import 'package:flutter/material.dart';

/// Available curated theme collections in FinTrack 2.0.
enum ThemeCollection {
  graphiteChampagne(
    displayName: 'Graphite & Champagne',
    storageKey: 'graphite_champagne',
    description: 'Warm graphite, champagne accents & soft gold highlights',
    logoAssetPath: 'assets/branding/logo_graphite_champagne.png',
  ),
  obsidianJade(
    displayName: 'Obsidian & Jade',
    storageKey: 'obsidian_jade',
    description: 'Deep obsidian backdrop with vibrant jade & teal accents',
    logoAssetPath: 'assets/branding/logo_obsidian_jade.png',
  ),
  arcticBlue(
    displayName: 'Arctic Blue',
    storageKey: 'arctic_blue',
    description: 'Cool navy canvas with vivid arctic blue & cyan accents',
    logoAssetPath: 'assets/branding/logo_arctic_blue.png',
  );

  const ThemeCollection({
    required this.displayName,
    required this.storageKey,
    required this.description,
    required this.logoAssetPath,
  });

  final String displayName;
  final String storageKey;
  final String description;
  final String logoAssetPath;

  /// Stable key shared with the Android launcher activity aliases.
  String get launcherIconKey => storageKey;

  static ThemeCollection fromKey(String? key) {
    if (key == null) return ThemeCollection.graphiteChampagne;
    return ThemeCollection.values.firstWhere(
      (e) => e.storageKey == key,
      orElse: () => ThemeCollection.graphiteChampagne,
    );
  }
}

/// Display mode preferences (System, Light, Dark).
enum AppDisplayMode {
  system(
    displayName: 'System default',
    storageKey: 'system',
    themeMode: ThemeMode.system,
    description: 'Matches your device system light or dark settings',
  ),
  dark(
    displayName: 'Dark mode',
    storageKey: 'dark',
    themeMode: ThemeMode.dark,
    description: 'Rich graphite or dark tones optimized for OLED/night',
  ),
  light(
    displayName: 'Light mode',
    storageKey: 'light',
    themeMode: ThemeMode.light,
    description: 'Warm ivory and crisp surfaces with high contrast',
  );

  const AppDisplayMode({
    required this.displayName,
    required this.storageKey,
    required this.themeMode,
    required this.description,
  });

  final String displayName;
  final String storageKey;
  final ThemeMode themeMode;
  final String description;

  static AppDisplayMode fromKey(String? key) {
    if (key == null) return AppDisplayMode.system;
    return AppDisplayMode.values.firstWhere(
      (e) => e.storageKey == key,
      orElse: () => AppDisplayMode.system,
    );
  }
}
