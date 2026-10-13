import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/repositories/analytics_repository.dart';
import 'package:frontend/screens/analytics/analytics_screen.dart';
import 'package:frontend/screens/analytics/widgets/companion_preferences_sheet.dart';
import 'package:frontend/screens/analytics/widgets/fin_action_preview_card.dart';
import 'package:frontend/screens/analytics/widgets/fin_character.dart';

class MockCompanionRepository extends AnalyticsRepository {
  ApiResponse<AnalyticsCapability>? mockCapabilities;
  ApiResponse<AnalyticsQueryResult>? mockQueryResult;
  ApiResponse<CompanionPreferences>? mockPreferences;
  bool confirmActionCalled = false;
  String? lastConfirmedCapability;
  Map<String, dynamic>? lastConfirmedParams;
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
        suggestedQuestions: [],
        maxDateRangeDays: 365,
        maxQuestionLength: 200,
        readOnly: false,
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
    if (mockQueryResult != null) return mockQueryResult!;

    return const ApiResponse(
      success: true,
      message: 'OK',
      data: AnalyticsQueryResult(
        intent: 'total_spending',
        isRefusal: false,
        answer: 'Verified answer from FIN.',
        privacyNotice: 'Saved records only.',
        characterState: 'explaining',
        suggestions: [],
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
            preferredName: 'Alex',
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
      data: CompanionPreferences(),
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> confirmAction(
    String capabilityId,
    Map<String, dynamic> parameters,
  ) async {
    confirmActionCalled = true;
    lastConfirmedCapability = capabilityId;
    lastConfirmedParams = parameters;
    return const ApiResponse(
      success: true,
      message: 'Savings goal "Emergency Fund" created with target ₹50,000.00.',
      data: {'goalId': 101, 'status': 'active'},
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('5E.3 — FIN 2.5D Animated Character Widget', () {
    testWidgets(
      'renders FinCharacter in all 10 character states without throwing',
      (tester) async {
        for (final state in FinCharacterState.values) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: FinCharacter(
                    state: state,
                    size: 100,
                    animationsEnabled: false,
                  ),
                ),
              ),
            ),
          );
          expect(find.byType(FinCharacter), findsOneWidget);
          expect(find.byType(CustomPaint), findsWidgets);
        }
      },
    );

    testWidgets(
      'respects animationsEnabled false without spawning repeating animation timer',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: FinCharacter(
                  state: FinCharacterState.idle,
                  size: 80,
                  animationsEnabled: false,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(FinCharacter), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('cleanly disposes AnimationController when unmounted', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: FinCharacter(
                state: FinCharacterState.idle,
                size: 80,
                animationsEnabled: true,
                allowAnimationInTests: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(FinCharacter), findsOneWidget);

      // Unmount the widget by replacing body with empty Container
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      );
      await tester.pump();
      expect(find.byType(FinCharacter), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('invokes onTap callback when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FinCharacter(
                state: FinCharacterState.greeting,
                size: 80,
                animationsEnabled: false,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FinCharacter));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('renders the requested full character height', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FinCharacter(
              state: FinCharacterState.explaining,
              size: 180,
              animationsEnabled: false,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FinCharacter)).height, 180);
      expect(
        find.bySemanticsLabel('FIN financial companion, currently Explaining'),
        findsOneWidget,
      );
    });
  });

  group('5E.4 — FIN Action Preview Card & Explicit Confirmation', () {
    testWidgets('renders action preview parameters and impact note', (
      tester,
    ) async {
      final mockRepo = MockCompanionRepository();
      final provider = AnalyticsProvider(repository: mockRepo);

      const preview = FinActionPreview(
        capability: 'create_savings_goal',
        title: 'Create Savings Goal',
        description: 'Prepare a goal of ₹50,000 for Laptop by Dec 2026.',
        parameters: {
          'name': 'Laptop Fund',
          'target_amount': '₹50,000.00',
          'monthly_contribution': '₹4,166.67',
        },
        impact:
            'This will save a goal in FinTrack. No actual money will be moved.',
        requiresConfirmation: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AnalyticsProvider>.value(
              value: provider,
              child: const FinActionPreviewCard(actionPreview: preview),
            ),
          ),
        ),
      );

      expect(find.text('Create Savings Goal'), findsOneWidget);
      expect(
        find.text('Prepare a goal of ₹50,000 for Laptop by Dec 2026.'),
        findsOneWidget,
      );
      expect(find.text('Laptop Fund'), findsOneWidget);
      expect(find.text('₹50,000.00'), findsOneWidget);
      expect(
        find.text(
          'This will save a goal in FinTrack. No actual money will be moved.',
        ),
        findsOneWidget,
      );
      expect(find.text('Confirm & Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets(
      'tapping Confirm & Save invokes provider.confirmPendingAction and displays success',
      (tester) async {
        final mockRepo = MockCompanionRepository();
        final provider = AnalyticsProvider(repository: mockRepo);

        const preview = FinActionPreview(
          capability: 'create_savings_goal',
          title: 'Create Savings Goal',
          description: 'Prepare a goal of ₹50,000 for Laptop.',
          parameters: {'name': 'Laptop Fund', 'target_amount': '50000'},
          impact: 'No bank transfer will occur.',
          requiresConfirmation: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<AnalyticsProvider>.value(
                value: provider,
                child: const FinActionPreviewCard(actionPreview: preview),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Confirm & Save'));
        await tester.pumpAndSettle();

        expect(mockRepo.confirmActionCalled, isTrue);
        expect(mockRepo.lastConfirmedCapability, 'create_savings_goal');
        expect(find.text('Confirmed'), findsOneWidget);
        expect(
          find.text(
            'Savings goal "Emergency Fund" created with target ₹50,000.00.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('tapping Cancel dismisses the preview card', (tester) async {
      final mockRepo = MockCompanionRepository();
      final provider = AnalyticsProvider(repository: mockRepo);

      const preview = FinActionPreview(
        capability: 'create_savings_goal',
        title: 'Create Savings Goal',
        description: 'Prepare goal.',
        parameters: {},
        impact: 'No money moved.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<AnalyticsProvider>.value(
              value: provider,
              child: const FinActionPreviewCard(actionPreview: preview),
            ),
          ),
        ),
      );

      expect(find.text('Create Savings Goal'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Create Savings Goal'), findsNothing);
    });
  });

  group('5E.2 — Persistent Relationship Preferences Sheet', () {
    testWidgets(
      'renders preferences sheet controls and allows updating settings',
      (tester) async {
        final mockRepo = MockCompanionRepository();
        final provider = AnalyticsProvider(repository: mockRepo);
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

        expect(find.text('FIN Companion Settings'), findsOneWidget);
        expect(find.text('Preferred Name'), findsOneWidget);
        expect(find.text('Response Style'), findsOneWidget);
        expect(find.text('Friendly'), findsOneWidget);
        expect(find.text('Concise'), findsOneWidget);
        expect(find.text('Detailed'), findsOneWidget);
        expect(find.text('Smooth 2.5D Animations'), findsOneWidget);
        expect(find.text('Personalized Greetings'), findsOneWidget);

        // Select Concise style and enter name
        await tester.tap(find.text('Concise'));
        await tester.enterText(find.byType(TextField), 'Alexander');
        await tester.pumpAndSettle();

        // Tap Save
        await tester.ensureVisible(find.text('Save Preferences'));
        await tester.tap(find.text('Save Preferences'));
        await tester.pumpAndSettle();

        expect(mockRepo.updatePreferencesCalled, isTrue);
        expect(mockRepo.lastUpdatedPrefs?.preferredName, 'Alexander');
        expect(mockRepo.lastUpdatedPrefs?.responseStyle, 'concise');
      },
    );
  });

  group('5E.1 & 5E.4 — AnalyticsScreen FIN Integration', () {
    testWidgets('renders FIN Hero card with status and greeting', (
      tester,
    ) async {
      final mockRepo = MockCompanionRepository();
      final provider = AnalyticsProvider(repository: mockRepo);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ChangeNotifierProvider<AnalyticsProvider>.value(
              value: provider,
              child: const AnalyticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('FIN'), findsOneWidget);
      expect(find.textContaining('FIN is ready to help'), findsOneWidget);
      expect(find.text('AI Financial Insights'), findsOneWidget);
      expect(find.byTooltip('FIN Settings & Memory'), findsOneWidget);
    });

    testWidgets(
      'renders action preview card and navigation action in assistant response',
      (tester) async {
        final mockRepo = MockCompanionRepository();
        final provider = AnalyticsProvider(repository: mockRepo);

        mockRepo.mockQueryResult = const ApiResponse(
          success: true,
          message: 'OK',
          data: AnalyticsQueryResult(
            intent: 'fin_action_goal',
            isRefusal: false,
            answer: 'I prepared your Laptop savings goal schedule!',
            privacyNotice: 'Saved records only.',
            characterState: 'explaining',
            actionPreview: FinActionPreview(
              capability: 'create_savings_goal',
              title: 'Create Laptop Goal',
              description: 'Save ₹50,000 for Laptop by Dec 2026.',
              parameters: {'target_amount': '₹50,000.00'},
              impact: 'Only updates planned goals in FinTrack.',
            ),
            navigationAction: FinNavigationAction(
              route: '/planning',
              label: 'Open Savings Goals & Planning',
            ),
            suggestions: [],
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(splashFactory: NoSplash.splashFactory),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: ChangeNotifierProvider<AnalyticsProvider>.value(
                value: provider,
                child: const AnalyticsScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await provider.askQuestion('Help me save ₹50,000 for a laptop');
        await tester.pumpAndSettle();

        expect(
          find.text('I prepared your Laptop savings goal schedule!'),
          findsOneWidget,
        );
        expect(find.text('Create Laptop Goal'), findsOneWidget);
        expect(find.text('Open Savings Goals & Planning'), findsOneWidget);
      },
    );

    testWidgets(
      'clearSession resets companion state to idle and clears pending context',
      (tester) async {
        final mockRepo = MockCompanionRepository();
        final provider = AnalyticsProvider(repository: mockRepo);

        await provider.askQuestion('Help me save');
        provider.setCharacterState(FinCharacterState.concerned);
        expect(provider.characterState, FinCharacterState.concerned);

        provider.clearSession();
        expect(provider.characterState, FinCharacterState.idle);
        expect(provider.messages, isEmpty);
        expect(provider.latestResult, isNull);
      },
    );

    testWidgets('normal screen entry clears a stale error pose', (
      tester,
    ) async {
      final provider = AnalyticsProvider(repository: MockCompanionRepository());
      provider.setCharacterState(FinCharacterState.error);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: ChangeNotifierProvider<AnalyticsProvider>.value(
              value: provider,
              child: const AnalyticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.characterState, FinCharacterState.idle);
      expect(find.text('FIN encountered an issue'), findsNothing);
      expect(find.text('FIN is ready to help'), findsOneWidget);
    });

    testWidgets('small Android layout and privacy sheet do not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = AnalyticsProvider(repository: MockCompanionRepository());
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              disableAnimations: true,
            ),
            child: ChangeNotifierProvider<AnalyticsProvider>.value(
              value: provider,
              child: const AnalyticsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byTooltip('Privacy Guarantee'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy & Isolation Guarantee'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
