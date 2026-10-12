import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/widgets/app_logo.dart';
import 'package:frontend/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Theme-to-Logo Mapping & Asset Integrity', () {
    test('Each ThemeCollection defines corresponding in-app logo asset', () {
      expect(
        ThemeCollection.graphiteChampagne.logoAssetPath,
        'assets/branding/logo_graphite_champagne.png',
      );
      expect(
        ThemeCollection.obsidianJade.logoAssetPath,
        'assets/branding/logo_obsidian_jade.png',
      );
      expect(
        ThemeCollection.arcticBlue.logoAssetPath,
        'assets/branding/logo_arctic_blue.png',
      );
    });
  });

  group('2. ThemeProvider Synchronization & Persistence', () {
    test('Default install initializes with Graphite & Champagne', () {
      final provider = ThemeProvider();
      expect(provider.collection, ThemeCollection.graphiteChampagne);
    });

    test('Selecting Jade updates collection and persists in SharedPreferences', () async {
      final provider = ThemeProvider();
      await provider.initialize();

      await provider.setCollection(ThemeCollection.obsidianJade);

      expect(provider.collection, ThemeCollection.obsidianJade);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'obsidian_jade',
      );
    });

    test('Selecting Arctic updates collection and persists in SharedPreferences', () async {
      final provider = ThemeProvider();
      await provider.initialize();

      await provider.setCollection(ThemeCollection.arcticBlue);

      expect(provider.collection, ThemeCollection.arcticBlue);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'arctic_blue',
      );
    });

    test('Selecting Graphite restores Graphite theme', () async {
      final provider = ThemeProvider();
      await provider.initialize();

      await provider.setCollection(ThemeCollection.obsidianJade);
      await provider.setCollection(ThemeCollection.graphiteChampagne);

      expect(provider.collection, ThemeCollection.graphiteChampagne);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'graphite_champagne',
      );
    });

    test('App restart preserves saved theme collection', () async {
      // Seed SharedPreferences as if previously saved
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        ThemeProvider.prefThemeCollectionKey,
        'obsidian_jade',
      );

      final provider = ThemeProvider();
      await provider.initialize();

      expect(provider.collection, ThemeCollection.obsidianJade);
    });
  });

  group('3. In-App Branding Widgets', () {
    testWidgets('FinTrackLogo renders with active theme', (tester) async {
      final provider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: FinTrackLogo(size: 60),
            ),
          ),
        ),
      );

      expect(find.byType(FinTrackLogo), findsOneWidget);
    });

    testWidgets('FinTrackLogo accepts explicit theme collection override', (
      tester,
    ) async {
      final provider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  FinTrackLogo(
                    size: 40,
                    collection: ThemeCollection.graphiteChampagne,
                  ),
                  FinTrackLogo(
                    size: 40,
                    collection: ThemeCollection.obsidianJade,
                  ),
                  FinTrackLogo(
                    size: 40,
                    collection: ThemeCollection.arcticBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FinTrackLogo), findsNWidgets(3));
    });

    testWidgets('AppLogo displays wordmark and 2.0 version badge', (tester) async {
      final provider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: AppLogo(size: 70),
            ),
          ),
        ),
      );

      expect(find.text('FinTrack'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.text('Manage your money smarter'), findsOneWidget);
    });
  });
}
