import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/repositories/analytics_repository.dart';
import 'package:frontend/screens/analytics/analytics_screen.dart';

class MockAssistantRepository extends AnalyticsRepository {
  AnalyticsQueryResult? mockQueryResult;
  String? lastCapturedQuestion;
  ConversationContext? lastCapturedContext;

  @override
  Future<ApiResponse<AnalyticsCapability>> getCapabilities() async {
    return const ApiResponse(
      success: true,
      message: "Success",
      data: AnalyticsCapability(
        supportedIntents: [
          "total_spending",
          "category_comparison",
          "budget_status",
          "remaining_allowance",
        ],
        suggestedQuestions: [
          SuggestedQuestion(
            intent: "category_comparison",
            question: "Which category increased the most?",
            label: "Category Comparison",
          ),
          SuggestedQuestion(
            intent: "budget_status",
            question: "Am I exceeding my food budget?",
            label: "Food Budget",
          ),
          SuggestedQuestion(
            intent: "remaining_allowance",
            question: "How much can I still spend?",
            label: "Remaining Allowance",
          ),
        ],
        maxDateRangeDays: 365,
        maxQuestionLength: 200,
        readOnly: true,
        privacyNotice: "Phase 5B assistant analyzed only saved FinTrack records.",
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
    lastCapturedQuestion = question;
    lastCapturedContext = conversationContext;

    final result = mockQueryResult ??
        AnalyticsQueryResult(
          intent: intent ?? "total_spending",
          isRefusal: false,
          answer: "Your spending was ₹5,000.00.",
          privacyNotice: "Saved records only.",
          suggestions: const [],
          followUpSuggestions: const [
            SuggestedQuestion(
              intent: "category_comparison",
              question: "Which category increased the most?",
              label: "Category Comparison",
            ),
          ],
          conversationContext: ConversationContext(
            previousIntent: intent ?? "total_spending",
            activePeriod: period ?? "current_month",
            turnCount: (conversationContext?.turnCount ?? 0) + 1,
          ),
        );

    return ApiResponse(
      success: true,
      message: "Query processed",
      data: result,
    );
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
      message: "Insights fetched",
      data: {
        "period": {
          "startDate": "2026-10-01",
          "endDate": "2026-10-31",
          "label": "October 2026",
        },
        "insights": [],
      },
    );
  }
}

void main() {
  group('Phase 5B Analytics Models Parsing', () {
    test('ConversationContext serialization and deserialization', () {
      final json = {
        'previousIntent': 'total_spending',
        'activePeriod': 'current_month',
        'activeCategory': 'Food',
        'activeMonth': '2026-10',
        'turnCount': 2,
      };

      final ctx = ConversationContext.fromJson(json);
      expect(ctx.previousIntent, 'total_spending');
      expect(ctx.activePeriod, 'current_month');
      expect(ctx.activeCategory, 'Food');
      expect(ctx.activeMonth, '2026-10');
      expect(ctx.turnCount, 2);

      final out = ctx.toJson();
      expect(out['previousIntent'], 'total_spending');
      expect(out['turnCount'], 2);
    });

    test('CategoryComparisonItem and CategoryBudgetDetail parsing', () {
      final compJson = {
        'id': 1,
        'name': 'Food & Dining',
        'currentTotal': 8000.0,
        'previousTotal': 5000.0,
        'difference': 3000.0,
        'percentChange': '60.0',
        'direction': 'increased',
        'currentCount': 8,
        'previousCount': 5,
      };
      final comp = CategoryComparisonItem.fromJson(compJson);
      expect(comp.name, 'Food & Dining');
      expect(comp.difference, 3000.0);
      expect(comp.percentChange, '60.0');

      final budgetJson = {
        'categoryName': 'Food',
        'budgetLimit': 5000.0,
        'spent': 6500.0,
        'remaining': 0.0,
        'percentage': '130.0',
        'status': 'exceeded',
      };
      final bDetail = CategoryBudgetDetail.fromJson(budgetJson);
      expect(bDetail.categoryName, 'Food');
      expect(bDetail.spent, 6500.0);
      expect(bDetail.status, 'exceeded');
    });

    test('UnusualSpendingIndicator and SavingsOpportunityItem parsing', () {
      final unusualJson = {
        'type': 'category_spike',
        'severity': 'warning',
        'title': 'Shopping Surge',
        'description': 'Shopping increased by 80%',
        'amount': 4000.0,
        'category': 'Shopping',
      };
      final ind = UnusualSpendingIndicator.fromJson(unusualJson);
      expect(ind.title, 'Shopping Surge');
      expect(ind.amount, 4000.0);

      final savingsJson = {
        'type': 'budget_overrun',
        'category': 'Food',
        'potentialSavings': 1500.0,
        'reason': 'Exceeded Food budget by ₹1,500.00',
      };
      final opp = SavingsOpportunityItem.fromJson(savingsJson);
      expect(opp.potentialSavings, 1500.0);
      expect(opp.reason, contains('Exceeded Food budget'));
    });
  });

  group('Phase 5B AnalyticsProvider Conversational State', () {
    late MockAssistantRepository mockRepo;
    late AnalyticsProvider provider;

    setUp(() {
      mockRepo = MockAssistantRepository();
      provider = AnalyticsProvider(repository: mockRepo);
    });

    test('askQuestion appends user and assistant chat messages and maintains context', () async {
      expect(provider.messages.isEmpty, true);

      await provider.askQuestion("How much did I spend this month?");

      expect(provider.messages.length, 2);
      expect(provider.messages[0].sender, MessageSender.user);
      expect(provider.messages[0].text, "How much did I spend this month?");

      expect(provider.messages[1].sender, MessageSender.assistant);
      expect(provider.messages[1].text, contains("Your spending was"));

      expect(provider.conversationContext?.previousIntent, "total_spending");
      expect(provider.conversationContext?.turnCount, 1);

      // Multi-turn turn 2
      await provider.askQuestion("What about last month?");
      expect(provider.messages.length, 4);
      expect(mockRepo.lastCapturedContext?.turnCount, 1);
      expect(provider.conversationContext?.turnCount, 2);
    });

    test('clearConversation resets chat messages and context cleanly', () async {
      await provider.askQuestion("Initial question");
      expect(provider.messages.length, 2);
      expect(provider.conversationContext != null, true);

      provider.clearConversation();

      expect(provider.messages.isEmpty, true);
      expect(provider.conversationContext, null);
      expect(provider.latestResult, null);
    });
  });

  group('Phase 5B AnalyticsScreen Conversational UI', () {
    late MockAssistantRepository mockRepo;
    late AnalyticsProvider provider;

    setUp(() {
      mockRepo = MockAssistantRepository();
      provider = AnalyticsProvider(repository: mockRepo);
    });

    Widget createTestWidget() {
      return MaterialApp(
        theme: ThemeData(
          splashFactory: NoSplash.splashFactory,
        ),
        home: ChangeNotifierProvider<AnalyticsProvider>.value(
          value: provider,
          child: const AnalyticsScreen(),
        ),
      );
    }

    testWidgets('renders category comparison card with delta and percentages', (tester) async {
      mockRepo.mockQueryResult = const AnalyticsQueryResult(
        intent: "category_comparison",
        isRefusal: false,
        period: AnalyticsPeriod(startDate: "2026-10-01", endDate: "2026-10-31", label: "October 2026"),
        metrics: {
          "categories": [
            {
              "id": 1,
              "name": "Food & Dining",
              "currentTotal": 9000.0,
              "previousTotal": 6000.0,
              "difference": 3000.0,
              "percentChange": "50.0",
              "direction": "increased",
              "currentCount": 8,
              "previousCount": 6,
            },
          ],
          "largestIncrease": {
            "id": 1,
            "name": "Food & Dining",
            "currentTotal": 9000.0,
            "previousTotal": 6000.0,
            "difference": 3000.0,
            "percentChange": "50.0",
            "direction": "increased",
            "currentCount": 8,
            "previousCount": 6,
          },
        },
        answer: "Calculated Fact: Food & Dining had the largest spending increase.",
        privacyNotice: "Saved records only.",
        suggestions: [],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await provider.askQuestion("Which category increased the most?");
      await tester.pumpAndSettle();

      expect(find.text("CATEGORY COMPARISON"), findsOneWidget);
      expect(find.text("MONTH-OVER-MONTH CHANGES"), findsOneWidget);
      expect(find.text("Food & Dining"), findsOneWidget);
      expect(find.text("+50.0%"), findsOneWidget);
    });

    testWidgets('renders category budget card with gauge and status', (tester) async {
      mockRepo.mockQueryResult = const AnalyticsQueryResult(
        intent: "budget_status",
        isRefusal: false,
        period: AnalyticsPeriod(startDate: "2026-10-01", endDate: "2026-10-31", label: "October 2026"),
        metrics: {
          "categoryBudget": {
            "categoryName": "Food",
            "budgetLimit": 5000.0,
            "spent": 6500.0,
            "remaining": 0.0,
            "percentage": "130.0",
            "status": "exceeded",
          },
        },
        answer: "Calculated Fact: Yes, you are exceeding your Food budget.",
        privacyNotice: "Saved records only.",
        suggestions: [],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await provider.askQuestion("Am I exceeding my food budget?");
      await tester.pumpAndSettle();

      expect(find.text("FOOD BUDGET PROGRESS"), findsOneWidget);
      expect(find.text("EXCEEDED"), findsOneWidget);
      expect(find.text("Spent: ₹6500.00"), findsOneWidget);
      expect(find.text("Limit: ₹5000.00"), findsOneWidget);
    });

    testWidgets('renders unusual spending and savings opportunities cards', (tester) async {
      mockRepo.mockQueryResult = const AnalyticsQueryResult(
        intent: "unusual_spending",
        isRefusal: false,
        period: AnalyticsPeriod(startDate: "2026-10-01", endDate: "2026-10-31", label: "October 2026"),
        metrics: {
          "indicators": [
            {
              "type": "category_spike",
              "severity": "warning",
              "title": "Dining Surge",
              "description": "Dining spending increased by 65%",
              "amount": 2500.0,
            },
          ],
          "opportunities": [
            {
              "type": "budget_overrun",
              "category": "Food",
              "potentialSavings": 1500.0,
              "reason": "Aligning Food to budget saves ₹1,500.00",
            },
          ],
        },
        answer: "Calculated Fact: 1 unusual indicator detected.",
        privacyNotice: "Saved records only.",
        suggestions: [],
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await provider.askQuestion("Any unusual spending?");
      await tester.pumpAndSettle();

      expect(find.text("UNUSUAL SPENDING INDICATORS"), findsOneWidget);
      expect(find.text("• Dining spending increased by 65%"), findsOneWidget);
      expect(find.text("DETERMINISTIC SAVINGS OPPORTUNITIES"), findsOneWidget);
      expect(find.text("• Aligning Food to budget saves ₹1,500.00"), findsOneWidget);
    });

    testWidgets('submitting question via text field triggers query and clears field', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);

      await tester.enterText(inputFinder, "How much did I spend this month?");
      await tester.tap(find.byTooltip("Ask Question"));
      await tester.pumpAndSettle();

      expect(mockRepo.lastCapturedQuestion, "How much did I spend this month?");
    });
  });
}
