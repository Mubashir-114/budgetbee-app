import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/core/theme/fin_track_theme_tokens.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/screens/profile/appearance_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Graphite & Champagne Default Design Tokens', () {
    test('Default dark tokens match exact Phase 4 specification', () {
      final tokens = FinTrackThemeTokens.graphiteChampagneDark;
      expect(tokens.background, const Color(0xFF171B24));
      expect(tokens.surface, const Color(0xFF252934));
      expect(tokens.elevated, const Color(0xFF30343F));
      expect(tokens.primary, const Color(0xFFD6A668));
      expect(tokens.secondary, const Color(0xFFE6BE85));
      expect(tokens.textPrimary, const Color(0xFFF4EFE7));
      expect(tokens.textSecondary, const Color(0xFFB5AFAB));
      expect(tokens.divider, const Color(0xFF393D48));

      // Check AppColors static default alignment
      expect(AppColors.darkScaffold, const Color(0xFF171B24));
      expect(AppColors.surfaceDark, const Color(0xFF252934));
      expect(AppColors.primary, const Color(0xFFD6A668));
      expect(AppColors.secondary, const Color(0xFFE6BE85));
      expect(AppColors.textLight, const Color(0xFFF4EFE7));
      expect(AppColors.textSecondaryDark, const Color(0xFFB5AFAB));
      expect(AppColors.dividerDark, const Color(0xFF393D48));
    });

    test('Default light tokens use warm ivory and soft graphite', () {
      final tokens = FinTrackThemeTokens.graphiteChampagneLight;
      expect(tokens.background, const Color(0xFFF8F6F1));
      expect(tokens.surface, const Color(0xFFFFFFFF));
      expect(tokens.textPrimary, const Color(0xFF1C1E24));
      expect(tokens.textSecondary, const Color(0xFF6B6760));
      expect(tokens.divider, const Color(0xFFE3DDD2));
    });

    test('Semantic colors are preserved across all themes', () {
      for (final collection in ThemeCollection.values) {
        final dark = FinTrackThemeTokens.resolve(collection, Brightness.dark);
        final light = FinTrackThemeTokens.resolve(collection, Brightness.light);

        expect(dark.danger, isNotNull);
        expect(dark.success, isNotNull);
        expect(dark.warning, isNotNull);
        expect(light.danger, isNotNull);
        expect(light.success, isNotNull);
        expect(light.warning, isNotNull);
      }
    });

    test('Preserves original FinTrack brand logo aurora gradient', () {
      expect(
        AppColors.auroraGradient.colors,
        containsAllInOrder([
          const Color(0xFF38D5B0),
          const Color(0xFF2DD4BF),
          const Color(0xFF159B82),
        ]),
      );
    });
  });

  group('Alternative Theme Collections', () {
    test('Obsidian & Jade tokens are correctly configured', () {
      final dark = FinTrackThemeTokens.obsidianJadeDark;
      expect(dark.background, const Color(0xFF0B111A));
      expect(dark.surface, const Color(0xFF151F2B));
      expect(dark.primary, const Color(0xFF38D5B0));
      expect(dark.secondary, const Color(0xFF2DD4BF));
    });

    test('Arctic Blue tokens are correctly configured', () {
      final dark = FinTrackThemeTokens.arcticBlueDark;
      expect(dark.background, const Color(0xFF0E1726));
      expect(dark.surface, const Color(0xFF162338));
      expect(dark.primary, const Color(0xFF4FA3F7));
      expect(dark.secondary, const Color(0xFF7DD3FC));
    });
  });

  group('ThemeProvider State & Immediate Switching', () {
    test('Initializes with Graphite & Champagne by default', () {
      final provider = ThemeProvider();
      expect(provider.collection, ThemeCollection.graphiteChampagne);
      expect(provider.displayMode, AppDisplayMode.system);
      expect(provider.themeMode, ThemeMode.system);
    });

    test('Switches theme collection immediately without restart', () async {
      final provider = ThemeProvider();
      await provider.initialize();

      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await provider.setCollection(ThemeCollection.arcticBlue);
      expect(provider.collection, ThemeCollection.arcticBlue);
      expect(notifyCount, greaterThanOrEqualTo(1));

      // ThemeData updates immediately
      expect(
        provider.darkTheme.scaffoldBackgroundColor,
        const Color(0xFF0E1726),
      );
      expect(
        provider.darkTheme.colorScheme.primary,
        const Color(0xFF4FA3F7),
      );

      // Check persistence
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'arctic_blue',
      );
    });

    test('Switches display mode immediately and persists', () async {
      final provider = ThemeProvider();
      await provider.setDisplayMode(AppDisplayMode.dark);

      expect(provider.displayMode, AppDisplayMode.dark);
      expect(provider.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefDisplayModeKey),
        'dark',
      );
    });
  });

  group('AppearanceScreen Widget Integration', () {
    testWidgets('renders all 3 theme collections, preview, and switches theme', (
      tester,
    ) async {
      final themeProvider = ThemeProvider();
      final currencyProvider = CurrencyProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
          ],
          child: MaterialApp(
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            home: const AppearanceScreen(),
          ),
        ),
      );

      // Verify title & sections
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('FinTrack Theme Preview'), findsOneWidget);
      expect(find.text('THEME COLLECTION'), findsOneWidget);
      expect(find.text('DISPLAY MODE'), findsOneWidget);

      // Verify 3 themes are present
      expect(find.text('Graphite & Champagne'), findsWidgets);
      expect(find.text('DEFAULT'), findsOneWidget);
      expect(find.text('Obsidian & Jade'), findsOneWidget);
      expect(find.text('Arctic Blue'), findsOneWidget);

      // Verify display modes
      expect(find.text('System default'), findsWidgets);
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.text('Light mode'), findsOneWidget);

      // Tap to switch to Arctic Blue
      await tester.tap(find.text('Arctic Blue'));
      await tester.pumpAndSettle();

      expect(themeProvider.collection, ThemeCollection.arcticBlue);

      // Tap to switch display mode to Dark
      await tester.ensureVisible(find.text('Dark mode'));
      await tester.tap(find.text('Dark mode'));
      await tester.pumpAndSettle();

      expect(themeProvider.displayMode, AppDisplayMode.dark);
    });
  });
}
