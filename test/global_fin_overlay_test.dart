import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/repositories/analytics_repository.dart';
import 'package:frontend/screens/analytics/widgets/global_fin_overlay.dart';

class _MockOverlayRepository extends AnalyticsRepository {
  CompanionPreferences preferences = const CompanionPreferences(
    preferredName: 'Alex',
    responseStyle: 'friendly',
    enableCharacterAnimations: true,
    enablePersonalizedGreetings: true,
    showAcrossApp: true,
    edgePosition: 'right',
    proactiveHints: true,
  );

  @override
  Future<ApiResponse<CompanionPreferences>> getCompanionPreferences() async {
    return ApiResponse(success: true, message: 'OK', data: preferences);
  }

  @override
  Future<ApiResponse<CompanionPreferences>> updateCompanionPreferences(
    CompanionPreferences prefs,
  ) async {
    preferences = prefs;
    return ApiResponse(success: true, message: 'Updated', data: prefs);
  }

  @override
  Future<ApiResponse<AnalyticsCapability>> getCapabilities() async {
    return const ApiResponse(
      success: true,
      message: 'OK',
      data: AnalyticsCapability(
        supportedIntents: ['total_spending', 'budget_status'],
        suggestedQuestions: [],
        maxDateRangeDays: 365,
        maxQuestionLength: 200,
        readOnly: true,
        privacyNotice: 'Private test notice',
      ),
    );
  }

  @override
  Future<ApiResponse<AnalyticsQueryResult>> queryAnalytics({
    String? question,
    String? intent,
    String? period,
    String? startDate,
    String? endDate,
    String? month,
    String? category,
    ConversationContext? conversationContext,
  }) async {
    return const ApiResponse(
      success: true,
      message: 'OK',
      data: AnalyticsQueryResult(
        intent: 'total_spending',
        isRefusal: false,
        answer: 'You spent \$150 this month.',
        privacyNotice: 'Local only',
        characterState: 'explaining',
        suggestions: [],
      ),
    );
  }
}

Widget _createOverlayTestApp({
  required AnalyticsProvider provider,
  String initialLocation = '/dashboard',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Dashboard Screen Content')),
              GlobalFinOverlay(),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const Scaffold(
          body: Stack(
            children: [
              Center(child: Text('FIN Full Conversation Screen')),
              GlobalFinOverlay(),
            ],
          ),
        ),
      ),
    ],
  );

  return ChangeNotifierProvider<AnalyticsProvider>.value(
    value: provider,
    child: MaterialApp.router(
      routerConfig: router,
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
    ),
  );
}

void main() {
  group('GlobalFinOverlay — Persistent 2.5D Peeking Companion', () {
    testWidgets('Renders peeking character on main screens', (tester) async {
      final repo = _MockOverlayRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      await tester.pumpWidget(_createOverlayTestApp(provider: provider));
      await tester.pumpAndSettle();

      expect(find.byType(GlobalFinOverlay), findsOneWidget);
      expect(find.byKey(const ValueKey('global_fin_peeking_character')), findsOneWidget);
      expect(find.text('Dashboard Screen Content'), findsOneWidget);

      // Panel is closed initially
      expect(find.byKey(const ValueKey('global_fin_action_panel')), findsNothing);
    });

    testWidgets('Tapping peeking character triggers emergence and reveals action panel', (
      tester,
    ) async {
      final repo = _MockOverlayRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      await tester.pumpWidget(_createOverlayTestApp(provider: provider));
      await tester.pumpAndSettle();

      // Tap the peeking character
      await tester.tap(find.byKey(const ValueKey('global_fin_peeking_character')));
      await tester.pumpAndSettle();

      // Action panel is now visible
      expect(find.byKey(const ValueKey('global_fin_action_panel')), findsOneWidget);
      expect(find.text('FIN is here'), findsOneWidget);

      // Functional action buttons are displayed
      expect(find.byKey(const ValueKey('global_fin_action_talk')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_fin_action_spending')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_fin_action_budget')), findsOneWidget);
      expect(find.byKey(const ValueKey('global_fin_action_close')), findsOneWidget);
    });

    testWidgets('Tapping Close dismisses the action panel back to peeking edge', (
      tester,
    ) async {
      final repo = _MockOverlayRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      await tester.pumpWidget(_createOverlayTestApp(provider: provider));
      await tester.pumpAndSettle();

      // Open panel
      await tester.tap(find.byKey(const ValueKey('global_fin_peeking_character')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('global_fin_action_panel')), findsOneWidget);

      // Tap Close button
      await tester.tap(find.byKey(const ValueKey('global_fin_action_close')));
      await tester.pumpAndSettle();

      // Panel is smoothly dismissed
      expect(find.byKey(const ValueKey('global_fin_action_panel')), findsNothing);
      expect(find.byKey(const ValueKey('global_fin_peeking_character')), findsOneWidget);
    });

    testWidgets('Edge switcher flips character between right and left edge', (
      tester,
    ) async {
      final repo = _MockOverlayRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      await tester.pumpWidget(_createOverlayTestApp(provider: provider));
      await tester.pumpAndSettle();

      // Open panel
      await tester.tap(find.byKey(const ValueKey('global_fin_peeking_character')));
      await tester.pumpAndSettle();

      // Tap edge switcher
      await tester.tap(find.byKey(const ValueKey('global_fin_edge_switch')));
      await tester.pumpAndSettle();

      // Preference updated to left
      expect(provider.companionPreferences.edgePosition, 'left');
    });

    testWidgets('Suppressed on /analytics route to avoid duplicate character presence', (
      tester,
    ) async {
      final repo = _MockOverlayRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      await tester.pumpWidget(_createOverlayTestApp(
        provider: provider,
        initialLocation: '/analytics',
      ));
      await tester.pumpAndSettle();

      // On /analytics, peeking avatar is suppressed
      expect(find.byKey(const ValueKey('global_fin_peeking_character')), findsNothing);
      expect(find.text('FIN Full Conversation Screen'), findsOneWidget);
    });

    testWidgets('Hides completely when showAcrossApp preference is turned off', (
      tester,
    ) async {
      final repo = _MockOverlayRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      // Turn off showAcrossApp
      await provider.updateCompanionPreferences(
        provider.companionPreferences.copyWith(showAcrossApp: false),
      );

      await tester.pumpWidget(_createOverlayTestApp(provider: provider));
      await tester.pumpAndSettle();

      // Character is completely hidden
      expect(find.byKey(const ValueKey('global_fin_peeking_avatar')), findsNothing);
    });
  });
}
