import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/analytics_model.dart';
import 'package:frontend/providers/analytics_provider.dart';
import 'package:frontend/repositories/analytics_repository.dart';
import 'package:frontend/screens/analytics/widgets/insights_feed_view.dart';
import 'package:frontend/screens/analytics/widgets/alert_preferences_sheet.dart';

class MockProactiveRepository extends AnalyticsRepository {
  List<SmartAlertItem> mockAlerts = [];
  String? lastCapturedQuestion;
  String? lastCapturedCategory;
  String? lastCapturedPeriod;

  @override
  Future<ApiResponse<List<SmartAlertItem>>> getProactiveAlerts({
    String? period,
    String? month,
    String? startDate,
    String? endDate,
    AlertPreferences? preferences,
  }) async {
    lastCapturedPeriod = period;
    return ApiResponse(
      success: true,
      message: "Proactive alerts fetched",
      data: mockAlerts,
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
    lastCapturedCategory = category;
    lastCapturedPeriod = period;

    return ApiResponse(
      success: true,
      message: "Query processed",
      data: AnalyticsQueryResult(
        intent: "budget_status",
        isRefusal: false,
        answer: "You have spent ₹8,500.00 of your ₹10,000.00 budget.",
        privacyNotice: "Saved records only.",
        suggestions: const [],
        conversationContext: ConversationContext(
          previousIntent: "budget_status",
          activePeriod: period ?? "current_month",
          activeCategory: category,
          turnCount: 1,
        ),
      ),
    );
  }

  @override
  Future<ApiResponse<AnalyticsCapability>> getCapabilities() async {
    return const ApiResponse(
      success: true,
      message: "Success",
      data: AnalyticsCapability(
        supportedIntents: ["budget_status", "explain_calculation"],
        suggestedQuestions: [],
        maxDateRangeDays: 365,
        maxQuestionLength: 200,
        readOnly: true,
        privacyNotice: "Phase 5C deterministic intelligence.",
      ),
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
      message: "Success",
      data: {
        "period": {"startDate": "2026-10-01", "endDate": "2026-10-31", "label": "October 2026"},
        "insights": [],
      },
    );
  }
}

void main() {
  group('Phase 5C SmartAlert Models & Preferences Serialization', () {
    test('SmartAlertProvenance parses correctly from json', () {
      final json = {
        'source': 'MySQL analytics_readonly',
        'recordCount': 12,
        'period': 'October 2026',
        'evaluatedAt': '2026-10-13T10:00:00Z',
      };
      final prov = SmartAlertProvenance.fromJson(json);
      expect(prov.source, 'MySQL analytics_readonly');
      expect(prov.recordCount, 12);
      expect(prov.period, 'October 2026');
      expect(prov.evaluatedAt, '2026-10-13T10:00:00Z');

      final out = prov.toJson();
      expect(out['recordCount'], 12);
      expect(out['period'], 'October 2026');
    });

    test('SmartAlertItem parses correctly with priority and calculated values', () {
      final json = {
        'id': 'alert_budget_exceeded_Food_2026-10',
        'type': 'budget_exceeded',
        'severity': 'critical',
        'priority': 1,
        'category': 'Food & Dining',
        'period': 'current_month',
        'title': 'Budget Exceeded: Food & Dining',
        'explanation': 'You spent ₹11,200.00 against your ₹10,000.00 budget (112.0%).',
        'calculatedValues': {
          'spent': 11200.0,
          'budget': 10000.0,
          'overspentAmount': 1200.0,
          'percentage': 112.0,
        },
        'provenance': {
          'source': 'MySQL analytics_readonly',
          'recordCount': 15,
          'period': 'October 2026',
          'evaluatedAt': '2026-10-13T10:00:00Z',
        },
      };

      final alert = SmartAlertItem.fromJson(json);
      expect(alert.id, 'alert_budget_exceeded_Food_2026-10');
      expect(alert.type, 'budget_exceeded');
      expect(alert.severity, 'critical');
      expect(alert.priority, 1);
      expect(alert.category, 'Food & Dining');
      expect(alert.calculatedValues['spent'], 11200.0);
      expect(alert.provenance?.recordCount, 15);

      final out = alert.toJson();
      expect(out['id'], 'alert_budget_exceeded_Food_2026-10');
      expect(out['priority'], 1);
    });

    test('AlertPreferences default values and query params mapping', () {
      const prefs = AlertPreferences();
      expect(prefs.enableProactiveInsights, true);
      expect(prefs.enableBudgetAlerts, true);
      expect(prefs.enableAnomalyAlerts, true);
      expect(prefs.enableSavingsAlerts, true);
      expect(prefs.budgetThreshold, 0.80);

      final params = prefs.toQueryParams();
      expect(params['enableProactiveInsights'], 'true');
      expect(params['enableBudgetAlerts'], 'true');
      expect(params['budgetThreshold'], '80');

      final custom = prefs.copyWith(
        enableBudgetAlerts: false,
        budgetThreshold: 0.90,
      );
      expect(custom.enableBudgetAlerts, false);
      expect(custom.budgetThreshold, 0.90);
      expect(custom.toQueryParams()['enableBudgetAlerts'], 'false');
      expect(custom.toQueryParams()['budgetThreshold'], '90');
    });
  });

  group('Phase 5C AnalyticsProvider Alert Lifecycle & Deduplication', () {
    late MockProactiveRepository mockRepo;
    late AnalyticsProvider provider;

    final testAlert1 = SmartAlertItem(
      id: 'alert_budget_1',
      type: 'budget_exceeded',
      severity: 'critical',
      priority: 1,
      category: 'Food',
      period: const AnalyticsPeriod(
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        label: 'current_month',
      ),
      title: 'Budget Exceeded',
      explanation: 'Over budget by ₹1,000.00',
      calculatedValues: const {'spent': 6000.0, 'budget': 5000.0},
      provenance: const SmartAlertProvenance(
        source: 'MySQL',
        recordCount: 10,
        period: 'Current Month',
        evaluatedAt: '2026-10-13T10:00:00Z',
      ),
    );

    final testAlert2 = SmartAlertItem(
      id: 'alert_anomaly_2',
      type: 'unusual_category_spending',
      severity: 'high',
      priority: 2,
      category: 'Shopping',
      period: const AnalyticsPeriod(
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        label: 'current_month',
      ),
      title: 'Unusual Spike',
      explanation: 'Spending spiked 2.5x above historical baseline',
      calculatedValues: const {'anomalyRatio': 2.5},
      provenance: const SmartAlertProvenance(
        source: 'MySQL',
        recordCount: 8,
        period: 'Current Month',
        evaluatedAt: '2026-10-13T10:00:00Z',
      ),
    );

    setUp(() {
      mockRepo = MockProactiveRepository();
      provider = AnalyticsProvider(repository: mockRepo);
    });

    test('loadAlerts populates alerts and activeAlerts', () async {
      mockRepo.mockAlerts = [testAlert1, testAlert2];

      await provider.loadAlerts();

      expect(provider.alerts.length, 2);
      expect(provider.activeAlerts.length, 2);
      expect(provider.activeAlerts.first.id, 'alert_budget_1');
    });

    test('dismissAlert removes item from activeAlerts and records dismissed ID', () async {
      mockRepo.mockAlerts = [testAlert1, testAlert2];
      await provider.loadAlerts();

      expect(provider.activeAlerts.length, 2);

      await provider.dismissAlert('alert_budget_1');

      expect(provider.dismissedAlertIds.contains('alert_budget_1'), true);
      expect(provider.activeAlerts.length, 1);
      expect(provider.activeAlerts.first.id, 'alert_anomaly_2');
    });

    test('resetDismissedAlerts restores all dismissed alerts', () async {
      mockRepo.mockAlerts = [testAlert1, testAlert2];
      await provider.loadAlerts();
      await provider.dismissAlert('alert_budget_1');
      await provider.dismissAlert('alert_anomaly_2');

      expect(provider.activeAlerts.isEmpty, true);

      await provider.resetDismissedAlerts();

      expect(provider.dismissedAlertIds.isEmpty, true);
      expect(provider.activeAlerts.length, 2);
    });

    test('disabling enableProactiveInsights returns empty activeAlerts', () async {
      mockRepo.mockAlerts = [testAlert1, testAlert2];
      await provider.loadAlerts();

      expect(provider.activeAlerts.length, 2);

      await provider.updatePreferences(
        provider.preferences.copyWith(enableProactiveInsights: false),
      );

      expect(provider.activeAlerts.isEmpty, true);
      expect(provider.preferences.enableProactiveInsights, false);
    });

    test('clearSession clears all alerts, dismissed state, and resets preferences', () async {
      mockRepo.mockAlerts = [testAlert1, testAlert2];
      await provider.loadAlerts();
      await provider.dismissAlert('alert_budget_1');

      expect(provider.alerts.isNotEmpty, true);
      expect(provider.dismissedAlertIds.isNotEmpty, true);

      provider.clearSession();

      expect(provider.alerts.isEmpty, true);
      expect(provider.activeAlerts.isEmpty, true);
      expect(provider.dismissedAlertIds.isEmpty, true);
      expect(provider.preferences.enableProactiveInsights, true);
    });

    test('askAlertQuestion passes structured period and category to assistant query', () async {
      await provider.askAlertQuestion(testAlert1, "Why am I over budget?");

      expect(mockRepo.lastCapturedQuestion, "Why am I over budget?");
      expect(mockRepo.lastCapturedCategory, "Food");
      expect(mockRepo.lastCapturedPeriod, "current_month");
    });
  });

  group('Phase 5C UI Widgets Rendering', () {
    late MockProactiveRepository mockRepo;
    late AnalyticsProvider provider;

    final testAlert = SmartAlertItem(
      id: 'alert_budget_test',
      type: 'budget_exceeded',
      severity: 'critical',
      priority: 1,
      category: 'Dining',
      period: const AnalyticsPeriod(
        startDate: '2026-10-01',
        endDate: '2026-10-31',
        label: 'current_month',
      ),
      title: 'Budget Exceeded: Dining',
      explanation: 'Over budget by ₹1,500.00 against limit of ₹5,000.00',
      calculatedValues: const {'spent': 6500.0, 'budget': 5000.0},
      provenance: const SmartAlertProvenance(
        source: 'MySQL analytics_readonly',
        recordCount: 14,
        period: 'October 2026',
        evaluatedAt: '2026-10-13T10:00:00Z',
      ),
    );

    setUp(() {
      mockRepo = MockProactiveRepository();
      provider = AnalyticsProvider(repository: mockRepo);
    });

    Widget createTestApp(Widget child) {
      return MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: ChangeNotifierProvider<AnalyticsProvider>.value(
          value: provider,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );
    }

    testWidgets('InsightsFeedView renders prioritized alert card and contextual questions', (tester) async {
      mockRepo.mockAlerts = [testAlert];
      await provider.loadAlerts();

      await tester.pumpWidget(createTestApp(const InsightsFeedView()));
      await tester.pumpAndSettle();

      expect(find.text("Smart Alerts Feed"), findsOneWidget);
      expect(find.text("CRITICAL"), findsOneWidget);
      expect(find.text("Budget Exceeded: Dining"), findsOneWidget);
      expect(find.textContaining("Over budget by ₹1,500.00"), findsOneWidget);
      expect(find.textContaining("MySQL analytics_readonly • October 2026"), findsOneWidget);

      // Contextual questions for budget alert
      expect(find.text("Why am I over budget?"), findsOneWidget);
      expect(find.text("How was this calculated?"), findsOneWidget);
      expect(find.text("What can I do to improve?"), findsOneWidget);
    });

    testWidgets('Tapping dismiss button in InsightsFeedView dismisses the alert', (tester) async {
      mockRepo.mockAlerts = [testAlert];
      await provider.loadAlerts();

      await tester.pumpWidget(createTestApp(const InsightsFeedView()));
      await tester.pumpAndSettle();

      expect(find.text("Budget Exceeded: Dining"), findsOneWidget);

      // Tap dismiss icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Card is dismissed, now empty state is shown
      expect(find.text("Budget Exceeded: Dining"), findsNothing);
      expect(find.text("All Clear! No Active Alerts"), findsOneWidget);
      expect(find.text("Reset Dismissed"), findsOneWidget);
    });

    testWidgets('Tapping contextual AI question chip calls askAlertQuestion', (tester) async {
      mockRepo.mockAlerts = [testAlert];
      await provider.loadAlerts();

      await tester.pumpWidget(createTestApp(const InsightsFeedView()));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Why am I over budget?"));
      await tester.pumpAndSettle();

      expect(mockRepo.lastCapturedQuestion, "Why am I over budget?");
      expect(mockRepo.lastCapturedCategory, "Dining");
    });

    testWidgets('AlertPreferencesSheet renders controls and threshold slider', (tester) async {
      await tester.pumpWidget(createTestApp(const AlertPreferencesSheet()));
      await tester.pumpAndSettle();

      expect(find.text("Alert Preferences"), findsOneWidget);
      expect(find.text("Proactive Financial Insights"), findsOneWidget);
      expect(find.text("Budget Limit Warnings"), findsOneWidget);
      expect(find.text("Unusual Spending Alerts"), findsOneWidget);
      expect(find.text("Savings Opportunities"), findsOneWidget);
      expect(find.text("Budget Warning Threshold"), findsOneWidget);
      expect(find.text("80%"), findsOneWidget);
      expect(find.text("Save Preferences"), findsOneWidget);
    });
  });
}
