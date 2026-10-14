import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/repositories/analytics_repository.dart';
import 'package:frontend/screens/analytics/analytics_screen.dart';
import 'package:frontend/screens/analytics/widgets/companion_preferences_sheet.dart';
import 'package:frontend/screens/analytics/widgets/fin_character.dart';
import 'package:frontend/screens/analytics/widgets/fin_visual_controller.dart';

class MockPhase5FRepository extends AnalyticsRepository {
  ApiResponse<AnalyticsCapability>? mockCapabilities;
  ApiResponse<AnalyticsQueryResult>? mockQueryResult;
  ApiResponse<CompanionPreferences>? mockPreferences;
  bool updatePreferencesCalled = false;
  CompanionPreferences? lastUpdatedPrefs;
  bool resetPreferencesCalled = false;

  @override
  Future<ApiResponse<AnalyticsCapability>> getCapabilities() async {
    return const ApiResponse(
      success: true,
      message: 'Capabilities',
      data: AnalyticsCapability(
        supportedIntents: ['total_spending', 'fin_greeting'],
        suggestedQuestions: [
          SuggestedQuestion(
            intent: 'total_spending',
            question: 'How much did I spend this month?',
            label: 'Total Spending',
          ),
          SuggestedQuestion(
            intent: 'category_spending',
            question: 'What is my grocery budget?',
            label: 'Grocery Budget',
          ),
        ],
        maxDateRangeDays: 365,
        maxQuestionLength: 200,
        readOnly: false,
        privacyNotice: 'All data stays on your device.',
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
    if (mockQueryResult != null) return mockQueryResult!;

    return const ApiResponse(
      success: true,
      message: 'OK',
      data: AnalyticsQueryResult(
        intent: 'total_spending',
        isRefusal: false,
        answer: 'You have spent \$340.50 this month based on your recorded transactions.',
        privacyNotice: 'Private data on device.',
        characterState: 'explaining',
        suggestions: [
          SuggestedQuestion(
            intent: 'category_spending',
            question: 'Show food breakdown',
            label: 'Food Breakdown',
          ),
        ],
      ),
    );
  }

  @override
  Future<ApiResponse<CompanionPreferences>> getCompanionPreferences() async {
    return mockPreferences ??
        const ApiResponse(
          success: true,
          message: 'OK',
          data: CompanionPreferences(
            preferredName: 'Jordan',
            responseStyle: 'friendly',
            enableCharacterAnimations: true,
            enablePersonalizedGreetings: true,
          ),
        );
  }

  @override
  Future<ApiResponse<CompanionPreferences>> updateCompanionPreferences(
    CompanionPreferences preferences,
  ) async {
    updatePreferencesCalled = true;
    lastUpdatedPrefs = preferences;
    return ApiResponse(
      success: true,
      message: 'Preferences updated',
      data: preferences,
    );
  }

  @override
  Future<ApiResponse<CompanionPreferences>> resetCompanionPreferences() async {
    resetPreferencesCalled = true;
    return const ApiResponse(
      success: true,
      message: 'Preferences reset',
      data: CompanionPreferences(
        preferredName: '',
        responseStyle: 'friendly',
        enableCharacterAnimations: true,
        enablePersonalizedGreetings: true,
      ),
    );
  }

  @override
  Future<ApiResponse<List<SmartAlertItem>>> getProactiveAlerts({
    String? period,
    String? month,
    String? startDate,
    String? endDate,
    AlertPreferences? preferences,
  }) async {
    return const ApiResponse(success: true, message: 'Alerts', data: []);
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> getInsights({
    String? period,
    String? month,
    String? startDate,
    String? endDate,
  }) async {
    return const ApiResponse(
      success: true,
      message: 'Insights',
      data: {'insights': []},
    );
  }
}

Widget createPhase5FTestApp({
  required MockPhase5FRepository repository,
  Size screenSize = const Size(390, 844),
}) {
  return MaterialApp(
    theme: ThemeData(splashFactory: NoSplash.splashFactory),
    home: MediaQuery(
      data: MediaQueryData(size: screenSize, disableAnimations: true),
      child: ChangeNotifierProvider<AnalyticsProvider>(
        create: (_) => AnalyticsProvider(repository: repository),
        child: const AnalyticsScreen(),
      ),
    ),
  );
}

void main() {
  group('Phase 5F.1 — FinVisualController Unit Tests', () {
    test('Initializes with idle state and manages genuine lifecycle transitions', () {
      final controller = FinVisualController(initialState: FinCharacterState.idle);
      expect(controller.state, FinCharacterState.idle);
      expect(controller.speechBubbleText, isNull);

      int listenerCount = 0;
      controller.addListener(() => listenerCount++);

      // Composer focus brings attentive state
      controller.onComposerFocused();
      expect(controller.state, FinCharacterState.attentive);
      expect(listenerCount, 1);

      // Composer unfocus resets to idle
      controller.onComposerUnfocused();
      expect(controller.state, FinCharacterState.idle);
      expect(listenerCount, 2);

      // Submitting query triggers thinking
      controller.onQuerySubmitted('What did I spend?');
      expect(controller.state, FinCharacterState.thinking);
      expect(listenerCount, 3);

      // Explaining result
      controller.onExplaining('Here are your numbers.');
      expect(controller.state, FinCharacterState.explaining);
      expect(controller.speechBubbleText, 'Here are your numbers.');
      expect(listenerCount, 4);

      // Encouraging result
      controller.onEncouraging('Great job saving!');
      expect(controller.state, FinCharacterState.encouraging);
      expect(controller.speechBubbleText, 'Great job saving!');
      expect(listenerCount, 5);

      // Caution state
      controller.onCaution('Approaching budget limit');
      expect(controller.state, FinCharacterState.caution);
      expect(controller.speechBubbleText, 'Approaching budget limit');
      expect(listenerCount, 6);

      // Empty data state
      controller.onEmptyData();
      expect(controller.state, FinCharacterState.emptyData);
      expect(listenerCount, 7);

      // Error state
      controller.onError('Unable to process query');
      expect(controller.state, FinCharacterState.error);
      expect(controller.speechBubbleText, 'Unable to process query');
      expect(listenerCount, 8);

      // Clear speech bubble
      controller.clearSpeechBubble();
      expect(controller.speechBubbleText, isNull);
      expect(listenerCount, 9);

      // Reset to idle
      controller.onIdle();
      expect(controller.state, FinCharacterState.idle);
      expect(listenerCount, 10);

      controller.dispose();
    });

    test('Maps assistant response states correctly', () {
      final controller = FinVisualController();

      controller.mapAssistantResult(
        isRefusal: false,
        hasError: false,
        hasGoalWin: true,
      );
      expect(controller.state, FinCharacterState.encouraging);

      controller.mapAssistantResult(
        isRefusal: false,
        hasError: false,
        hasBudgetExceeded: true,
      );
      expect(controller.state, FinCharacterState.caution);

      controller.mapAssistantResult(
        isRefusal: true,
        hasError: false,
      );
      expect(controller.state, FinCharacterState.emptyData);

      controller.mapAssistantResult(
        isRefusal: false,
        hasError: true,
      );
      expect(controller.state, FinCharacterState.error);

      controller.dispose();
    });
  });

  group('Phase 5F.2 — Coordinated 2.5D FinCharacter Widget Tests', () {
    testWidgets('Renders FinCharacter with FinVisualController in all 10 states', (tester) async {
      for (final state in FinCharacterState.values) {
        final controller = FinVisualController(initialState: state);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: FinCharacter(
                  controller: controller,
                  size: 100,
                  animationsEnabled: false,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(FinCharacter), findsOneWidget);
        controller.dispose();
      }
    });

    testWidgets('Honors reduced-motion settings gracefully without animation hitch', (tester) async {
      final controller = FinVisualController(initialState: FinCharacterState.idle);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: FinCharacter(
                  controller: controller,
                  size: 100,
                  animationsEnabled: true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FinCharacter), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);

      controller.dispose();
    });
  });

  group('Phase 5F.3 — Companion Home vs Collapsed Active Presence', () {
    testWidgets('Starts with prominent Companion Home and collapses on conversation start', (tester) async {
      final repo = MockPhase5FRepository();
      await tester.pumpWidget(createPhase5FTestApp(repository: repo));
      await tester.pumpAndSettle();

      // Companion Home elements are visible
      expect(find.text('Living Companion'), findsOneWidget);
      expect(find.text('FIN'), findsWidgets);
      expect(find.text('Total Spending'), findsOneWidget);
      expect(find.byKey(const ValueKey('fin_hero_card')), findsOneWidget);

      // Initially, collapsed companion bar is NOT visible
      expect(find.byKey(const ValueKey('collapsed_companion_bar')), findsNothing);

      // Tap suggestion chip to start active conversation
      await tester.ensureVisible(find.text('Total Spending'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Total Spending'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Large hero collapses
      expect(find.byKey(const ValueKey('fin_hero_card')), findsNothing);

      // Collapsed companion bar appears at the top
      expect(find.byKey(const ValueKey('collapsed_companion_bar')), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      // Resetting conversation returns back to prominent hero Companion Home
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('fin_hero_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('collapsed_companion_bar')), findsNothing);
    });
  });

  group('Phase 5F.4 — Companion vs Insights & Alerts View Switcher', () {
    testWidgets('Toggling between Companion and Insights switches mode', (tester) async {
      final repo = MockPhase5FRepository();
      await tester.pumpWidget(createPhase5FTestApp(repository: repo));
      await tester.pumpAndSettle();

      // View switcher buttons exist
      expect(find.text('Companion'), findsOneWidget);
      expect(find.text('Insights & Alerts'), findsOneWidget);

      // In Companion mode, composer is visible
      expect(find.byKey(const ValueKey('assistant_query_field')), findsOneWidget);

      // Tap Insights & Alerts
      await tester.tap(find.text('Insights & Alerts'));
      await tester.pumpAndSettle();

      // In Insights mode, chat composer is hidden
      expect(find.byKey(const ValueKey('assistant_query_field')), findsNothing);

      // Tap back to Companion
      await tester.tap(find.text('Companion'));
      await tester.pumpAndSettle();

      // Chat composer is visible again
      expect(find.byKey(const ValueKey('assistant_query_field')), findsOneWidget);
    });
  });

  group('Phase 5F.5 — Preferences Sheet: Live Preview, Styles, and Safe Reset', () {
    testWidgets('Live greeting preview updates with name input', (tester) async {
      final repo = MockPhase5FRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ChangeNotifierProvider<AnalyticsProvider>.value(
                value: provider,
                child: const CompanionPreferencesSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial live preview shows Jordan
      expect(find.text('Greeting Preview: "Hey Jordan! Ready to inspect your finances?"'), findsOneWidget);

      // Enter new name "Taylor"
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Taylor');
      await tester.pumpAndSettle();

      // Preview immediately updates
      expect(find.text('Greeting Preview: "Hey Taylor! Ready to inspect your finances?"'), findsOneWidget);

      // Style options exist
      expect(find.text('Friendly'), findsOneWidget);
      expect(find.text('Concise'), findsOneWidget);
      expect(find.text('Detailed'), findsOneWidget);
    });

    testWidgets('Reset preferences triggers safe confirmation modal before clearing', (tester) async {
      final repo = MockPhase5FRepository();
      final provider = AnalyticsProvider(repository: repo);
      await provider.loadCompanionPreferences();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: ChangeNotifierProvider<AnalyticsProvider>.value(
                value: provider,
                child: const CompanionPreferencesSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal Clear Memory button if needed
      await tester.ensureVisible(find.text('Clear Memory'));
      await tester.pumpAndSettle();

      // Tap Clear Memory button
      await tester.tap(find.text('Clear Memory'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be displayed
      expect(find.text('Reset FIN Memory?'), findsOneWidget);
      expect(find.text('This will clear your saved preferred name and reset FIN\'s style settings to default. Your financial records, accounts, and transactions are not affected.'), findsOneWidget);

      // Tap Cancel — no reset performed
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.resetPreferencesCalled, isFalse);

      // Tap Clear Memory again and confirm Reset
      await tester.tap(find.text('Clear Memory'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(repo.resetPreferencesCalled, isTrue);
    });
  });

  group('Phase 5F.6 — Small Screen Resilience (320x568)', () {
    testWidgets('Renders on compact Android viewport without RenderFlex overflow', (tester) async {
      final repo = MockPhase5FRepository();
      await tester.pumpWidget(createPhase5FTestApp(
        repository: repo,
        screenSize: const Size(320, 568),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Test active conversation state on 320x568
      await tester.ensureVisible(find.text('Total Spending'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Total Spending'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
