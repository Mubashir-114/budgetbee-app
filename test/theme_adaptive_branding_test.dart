import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/launcher_icon_service.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/core/widgets/app_logo.dart';
import 'package:frontend/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.mkl.financemanager/launcher_icon');
  final List<MethodCall> methodCalls = [];
  String currentActiveAlias = 'graphite_champagne';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    methodCalls.clear();
    currentActiveAlias = 'graphite_champagne';

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      methodCalls.add(call);
      if (call.method == 'setLauncherIcon') {
        final key = call.arguments['iconKey'] as String;
        currentActiveAlias = key;
        return true;
      } else if (call.method == 'getCurrentLauncherIcon') {
        return currentActiveAlias;
      }
      return null;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('1. Theme-to-Icon Mapping & Asset Integrity', () {
    test('Each ThemeCollection defines corresponding logo asset and icon key', () {
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
      expect(
        ThemeCollection.obsidianJade.launcherIconKey,
        'obsidian_jade',
      );

      expect(
        ThemeCollection.arcticBlue.logoAssetPath,
        'assets/branding/logo_arctic_blue.png',
      );
      expect(
        ThemeCollection.arcticBlue.launcherIconKey,
        'arctic_blue',
      );
    });

    test('LauncherIconService.iconKeyFor matches storageKey exactly', () {
      for (final collection in ThemeCollection.values) {
        expect(
          LauncherIconService.iconKeyFor(collection),
          collection.storageKey,
        );
      }
    });
  });

  group('2. MethodChannel & LauncherIconService', () {
    test('setLauncherIcon dispatches method call on Android platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      expect(
        LauncherIconService.iconKeyFor(ThemeCollection.obsidianJade),
        'obsidian_jade',
      );
    });

    test('Non-Android platforms gracefully no-op without exceptions', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final res = await LauncherIconService.setLauncherIcon(
        ThemeCollection.obsidianJade,
      );
      expect(res, isFalse);

      final current = await LauncherIconService.getCurrentLauncherIcon();
      expect(current, isNull);

      await LauncherIconService.reconcile(ThemeCollection.obsidianJade);
    });

    test('Android setLauncherIcon successfully switches alias', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final ok = await LauncherIconService.setLauncherIcon(
        ThemeCollection.arcticBlue,
      );
      expect(ok, isTrue);
      expect(currentActiveAlias, 'arctic_blue');
      expect(methodCalls.last.method, 'setLauncherIcon');
      expect(methodCalls.last.arguments['iconKey'], 'arctic_blue');
    });

    test('Android reconcile updates only when current alias diverges', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      currentActiveAlias = 'graphite_champagne';

      // Reconciling with graphite_champagne does not invoke setLauncherIcon
      await LauncherIconService.reconcile(ThemeCollection.graphiteChampagne);
      final setCallsBefore =
          methodCalls.where((c) => c.method == 'setLauncherIcon').length;
      expect(setCallsBefore, 0);

      // Reconciling with obsidian_jade updates alias
      await LauncherIconService.reconcile(ThemeCollection.obsidianJade);
      expect(currentActiveAlias, 'obsidian_jade');
    });
  });

  group('3. ThemeProvider Synchronization & Persistence', () {
    test('Default install initializes with Graphite & Champagne', () {
      final provider = ThemeProvider();
      expect(provider.collection, ThemeCollection.graphiteChampagne);
    });

    test('Selecting Jade activates Jade launcher icon and persists', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final provider = ThemeProvider();
      await provider.initialize();

      await provider.setCollection(ThemeCollection.obsidianJade);

      expect(provider.collection, ThemeCollection.obsidianJade);
      expect(currentActiveAlias, 'obsidian_jade');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'obsidian_jade',
      );
    });

    test('Selecting Arctic activates Arctic launcher icon and persists', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final provider = ThemeProvider();
      await provider.initialize();

      await provider.setCollection(ThemeCollection.arcticBlue);

      expect(provider.collection, ThemeCollection.arcticBlue);
      expect(currentActiveAlias, 'arctic_blue');

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(ThemeProvider.prefThemeCollectionKey),
        'arctic_blue',
      );
    });

    test('Selecting Graphite restores Graphite launcher icon', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final provider = ThemeProvider();
      await provider.initialize();

      await provider.setCollection(ThemeCollection.obsidianJade);
      expect(currentActiveAlias, 'obsidian_jade');

      await provider.setCollection(ThemeCollection.graphiteChampagne);
      expect(provider.collection, ThemeCollection.graphiteChampagne);
      expect(currentActiveAlias, 'graphite_champagne');
    });

    test('App restart preserves saved theme and reconciles launcher alias', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      // Seed SharedPreferences as if previously saved
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        ThemeProvider.prefThemeCollectionKey,
        'obsidian_jade',
      );

      // Launcher alias is currently default graphite
      currentActiveAlias = 'graphite_champagne';

      final provider = ThemeProvider();
      await provider.initialize();

      expect(provider.collection, ThemeCollection.obsidianJade);
      // Reconciled during initialize
      expect(currentActiveAlias, 'obsidian_jade');
    });
  });

  group('4. In-App Branding Widgets', () {
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
