import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/services/launcher_icon_service.dart';
import 'package:frontend/core/widgets/app_logo.dart';
import 'package:frontend/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const launcherChannel = MethodChannel('com.mkl.financemanager/launcher_icon');
  final methodCalls = <MethodCall>[];
  var activeIconKey = 'graphite_champagne';
  var failLauncherCalls = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    methodCalls.clear();
    activeIconKey = 'graphite_champagne';
    failLauncherCalls = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, (call) async {
          methodCalls.add(call);
          if (failLauncherCalls) {
            throw PlatformException(code: 'SWITCH_FAILED');
          }
          if (call.method == 'getCurrentLauncherIcon') {
            return activeIconKey;
          }
          if (call.method == 'setLauncherIcon') {
            activeIconKey = (call.arguments as Map)['iconKey'] as String;
            return true;
          }
          throw MissingPluginException();
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(launcherChannel, null);
  });

  group('1. Theme-to-Logo Mapping & Asset Integrity', () {
    test('Each ThemeCollection defines corresponding in-app logo asset', () {
      expect(
        ThemeCollection.graphiteChampagne.logoAssetPath,
        'assets/branding/logo_graphite_champagne.png',
      );
      expect(
        ThemeCollection.graphiteChampagne.launcherIconKey,
        'graphite_champagne',
      );
      expect(
        ThemeCollection.obsidianJade.logoAssetPath,
        'assets/branding/logo_obsidian_jade.png',
      );
      expect(ThemeCollection.obsidianJade.launcherIconKey, 'obsidian_jade');
      expect(
        ThemeCollection.arcticBlue.logoAssetPath,
        'assets/branding/logo_arctic_blue.png',
      );
      expect(ThemeCollection.arcticBlue.launcherIconKey, 'arctic_blue');
    });
  });

  group('2. Launcher platform synchronization', () {
    test(
      'skips the native update when the launcher icon already matches',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;

        expect(
          await LauncherIconService.synchronize(
            ThemeCollection.graphiteChampagne,
          ),
          isTrue,
        );
        expect(
          methodCalls.where((call) => call.method == 'setLauncherIcon'),
          isEmpty,
        );
      },
    );

    test('maps a brand collection to its Android launcher alias', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(
        await LauncherIconService.synchronize(ThemeCollection.obsidianJade),
        isTrue,
      );
      expect(activeIconKey, 'obsidian_jade');
      final setCall = methodCalls.singleWhere(
        (call) => call.method == 'setLauncherIcon',
      );
      expect((setCall.arguments as Map)['iconKey'], 'obsidian_jade');
    });

    test(
      'contains platform-channel failures without changing theme state',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        failLauncherCalls = true;

        expect(
          await LauncherIconService.synchronize(ThemeCollection.arcticBlue),
          isFalse,
        );
      },
    );

    test('does not call the Android channel on other platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      expect(
        await LauncherIconService.synchronize(ThemeCollection.arcticBlue),
        isFalse,
      );
      expect(methodCalls, isEmpty);
    });
  });

  group('3. ThemeProvider Synchronization & Persistence', () {
    test('Default install initializes with Graphite & Champagne', () {
      final provider = ThemeProvider();
      expect(provider.collection, ThemeCollection.graphiteChampagne);
    });

    test(
      'Selecting Jade updates collection and persists in SharedPreferences',
      () async {
        final provider = ThemeProvider();
        await provider.initialize();

        await provider.setCollection(ThemeCollection.obsidianJade);

        expect(provider.collection, ThemeCollection.obsidianJade);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(ThemeProvider.prefThemeCollectionKey),
          'obsidian_jade',
        );
      },
    );

    test(
      'Selecting Arctic updates collection and persists in SharedPreferences',
      () async {
        final provider = ThemeProvider();
        await provider.initialize();

        await provider.setCollection(ThemeCollection.arcticBlue);

        expect(provider.collection, ThemeCollection.arcticBlue);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString(ThemeProvider.prefThemeCollectionKey),
          'arctic_blue',
        );
      },
    );

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

    test('startup reconciles the persisted collection exactly once', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      SharedPreferences.setMockInitialValues({
        ThemeProvider.prefThemeCollectionKey: 'arctic_blue',
      });

      final provider = ThemeProvider();
      await provider.initialize();
      await provider.initialize();

      expect(provider.collection, ThemeCollection.arcticBlue);
      expect(activeIconKey, 'arctic_blue');
      expect(
        methodCalls.where((call) => call.method == 'setLauncherIcon').length,
        1,
      );
    });

    test('display mode changes never request a launcher icon update', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final provider = ThemeProvider();
      await provider.initialize();
      methodCalls.clear();

      await provider.setDisplayMode(AppDisplayMode.dark);

      expect(provider.displayMode, AppDisplayMode.dark);
      expect(methodCalls, isEmpty);
    });

    test('launcher failure does not roll back theme persistence', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final provider = ThemeProvider();
      await provider.initialize();
      failLauncherCalls = true;

      await provider.setCollection(ThemeCollection.arcticBlue);

      final prefs = await SharedPreferences.getInstance();
      expect(provider.collection, ThemeCollection.arcticBlue);
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'arctic_blue',
      );
    });
  });

  group('4. In-App Branding Widgets', () {
    testWidgets('FinTrackLogo renders with active theme', (tester) async {
      final provider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(body: FinTrackLogo(size: 60)),
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

    testWidgets('AppLogo displays wordmark and 2.0 version badge', (
      tester,
    ) async {
      final provider = ThemeProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(home: Scaffold(body: AppLogo(size: 70))),
        ),
      );

      expect(find.text('FinTrack'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.text('Manage your money smarter'), findsOneWidget);
    });
  });
}
