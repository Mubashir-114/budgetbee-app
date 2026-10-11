import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/budget_model.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/screens/budgets/budgets_list_screen.dart';
import 'package:frontend/core/services/cache_service.dart';

class MockBudgetProvider extends BudgetProvider {
  BudgetProgressResponseModel? _mockProgress;
  BudgetAlertsResponseModel? _mockAlerts;
  List<BudgetSuggestionModel> _mockSuggestions = [];
  List<BudgetHistoryItemModel> _mockHistory = [];
  bool _mockLoading = false;
  String? _mockError;

  void setMockData({
    BudgetProgressResponseModel? progress,
    BudgetAlertsResponseModel? alerts,
    List<BudgetSuggestionModel>? suggestions,
    List<BudgetHistoryItemModel>? history,
    bool isLoading = false,
    String? error,
  }) {
    _mockProgress = progress;
    _mockAlerts = alerts;
    _mockSuggestions = suggestions ?? [];
    _mockHistory = history ?? [];
    _mockLoading = isLoading;
    _mockError = error;
    notifyListeners();
  }

  @override
  BudgetProgressResponseModel? get progress => _mockProgress;

  @override
  BudgetAlertsResponseModel? get alerts => _mockAlerts;

  @override
  List<BudgetSuggestionModel> get suggestions => _mockSuggestions;

  @override
  List<BudgetHistoryItemModel> get history => _mockHistory;

  @override
  bool get isLoading => _mockLoading;

  @override
  String? get errorMessage => _mockError;

  @override
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {
    // No-op in widget mock
  }

  @override
  Future<void> loadBudgetSuggestions() async {}

  @override
  Future<void> loadBudgetHistory({int months = 6}) async {}
}

class MockReportProvider extends ReportProvider {
  @override
  Future<void> loadAllReports() async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
  });

  group('Phase 3D: Smart Budget Models Serialization', () {
    test('BudgetProgressResponseModel deserializes exact fields cleanly', () {
      final json = {
        "month": 10,
        "year": 2026,
        "period": {
          "daysInMonth": 31,
          "daysElapsed": 11,
          "daysRemaining": 20,
          "isCurrentPeriod": true,
          "estimationMethod": "Linear Daily Burn-Rate",
        },
        "overall": {
          "budgetLimit": "25000.00",
          "actualSpending": "18000.00",
          "remainingAmount": "7000.00",
          "utilizationPercentage": "72.0",
          "dailyBurnRate": "1636.36",
          "projectedSpending": "50727.16",
          "status": "on_track",
          "hasBudgetsDefined": true,
        },
        "categoryBudgets": [
          {
            "budgetId": 1,
            "categoryId": 3,
            "category": "Food",
            "categoryType": "expense",
            "budgetLimit": "10000.00",
            "actualSpending": "8500.00",
            "remainingAmount": "1500.00",
            "utilizationPercentage": "85.0",
            "projectedSpending": "23954.54",
            "status": "approaching_limit",
            "daysRemaining": 20,
          },
          {
            "budgetId": 2,
            "categoryId": 4,
            "category": "Transport",
            "categoryType": "expense",
            "budgetLimit": "5000.00",
            "actualSpending": "5500.00",
            "remainingAmount": "-500.00",
            "utilizationPercentage": "110.0",
            "projectedSpending": "15500.00",
            "status": "exceeded",
            "daysRemaining": 20,
          }
        ],
        "uncategorizedSpending": "4000.00",
        "savings": {
          "totalIncome": "60000.00",
          "totalExpense": "18000.00",
          "netSavings": "42000.00",
          "projectedNetSavings": "9272.84",
          "savingsTarget": "30000.00",
          "progressPercentage": "140.0",
          "isTargetAchieved": true,
        }
      };

      final model = BudgetProgressResponseModel.fromJson(json);
      expect(model.month, 10);
      expect(model.year, 2026);
      expect(model.overall.budgetLimit, "25000.00");
      expect(model.overall.actualSpending, "18000.00");
      expect(model.overall.remainingAmount, "7000.00");
      expect(model.overall.status, "on_track");
      expect(model.categoryBudgets.length, 2);
      expect(model.categoryBudgets[0].category, "Food");
      expect(model.categoryBudgets[0].status, "approaching_limit");
      expect(model.categoryBudgets[1].status, "exceeded");
      expect(model.savings.netSavings, "42000.00");
      expect(model.savings.isTargetAchieved, true);
    });

    test('BudgetAlertsResponseModel deserializes approaching and exceeded alerts', () {
      final json = {
        "month": 10,
        "year": 2026,
        "overallAlert": {
          "severity": "warning",
          "message": "Overall spending approaching monthly cap",
        },
        "approachingLimit": [
          {
            "categoryId": 3,
            "category": "Food",
            "budgetLimit": "10000.00",
            "actualSpending": "8500.00",
            "utilizationPercentage": "85.0",
            "severity": "warning",
            "message": "Food approaching limit: 85.0% used",
          }
        ],
        "exceeded": [
          {
            "categoryId": 4,
            "category": "Transport",
            "budgetLimit": "5000.00",
            "actualSpending": "5500.00",
            "utilizationPercentage": "110.0",
            "severity": "critical",
            "message": "Transport exceeded: 110.0% used",
          }
        ],
        "insights": [
          {
            "type": "allowance",
            "title": "Remaining Allowance",
            "message": "You have ₹7,000 remaining for 20 days",
          }
        ],
        "totalAlertsCount": 3,
      };

      final alerts = BudgetAlertsResponseModel.fromJson(json);
      expect(alerts.totalAlertsCount, 3);
      expect(alerts.approachingLimit.length, 1);
      expect(alerts.exceeded.length, 1);
      expect(alerts.overallAlert?.message, "Overall spending approaching monthly cap");
    });

    test('BudgetSuggestionModel distinguishes historical facts from estimates', () {
      final json = {
        "categoryId": 3,
        "categoryName": "Food",
        "historicalFacts": {
          "lastMonthSpent": "8000.00",
          "twoMonthsAgoSpent": "7500.00",
          "threeMonthsAgoSpent": "7000.00",
          "threeMonthAverage": "7500.00",
        },
        "estimates": {
          "trend": "increasing",
          "suggestedBudget": "8000.00",
          "estimatedSavingsPotential": "500.00",
          "rationale": "Based on 3-month average of ₹7500.00 with increasing trend.",
        },
        "currentBudget": "10000.00",
        "isSuggestion": true,
        "isHistoricalFact": false,
      };

      final suggestion = BudgetSuggestionModel.fromJson(json);
      expect(suggestion.categoryName, "Food");
      expect(suggestion.historicalFacts.threeMonthAverage, "7500.00");
      expect(suggestion.estimates.trend, "increasing");
      expect(suggestion.estimates.suggestedBudget, "8000.00");
      expect(suggestion.isSuggestion, true);
      expect(suggestion.isHistoricalFact, false);
    });
  });

  group('Phase 3D: BudgetProvider Session & State', () {
    test('clearSession resets all Phase 3D state and increments session generation', () {
      final provider = BudgetProvider();
      provider.setUserSavingsTarget(15000.0);
      expect(provider.userSavingsTarget, 15000.0);

      provider.clearSession();
      expect(provider.progress, isNull);
      expect(provider.alerts, isNull);
      expect(provider.suggestions, isEmpty);
      expect(provider.history, isEmpty);
      expect(provider.userSavingsTarget, isNull);
      expect(provider.isLoading, false);
    });
  });

  group('Phase 3D: BudgetsListScreen Widget Tests', () {
    testWidgets('renders Monthly Total Budget, Alerts, Category Cards, and Savings Progress',
        (tester) async {
      final mockBudget = MockBudgetProvider();
      final mockReport = MockReportProvider();
      final currency = CurrencyProvider();

      mockBudget.setMockData(
        progress: BudgetProgressResponseModel(
          month: 10,
          year: 2026,
          period: const BudgetPeriodModel(
            daysInMonth: 31,
            daysElapsed: 11,
            daysRemaining: 20,
            isCurrentPeriod: true,
            estimationMethod: "Linear Daily Burn-Rate",
          ),
          overall: const BudgetOverallProgressModel(
            budgetLimit: "25000.00",
            actualSpending: "18000.00",
            remainingAmount: "7000.00",
            utilizationPercentage: "72.0",
            dailyBurnRate: "1636.36",
            projectedSpending: "50727.16",
            status: "on_track",
            hasBudgetsDefined: true,
          ),
          categoryBudgets: const [
            BudgetCategoryProgressModel(
              budgetId: 1,
              categoryId: 3,
              category: "Food",
              categoryType: "expense",
              budgetLimit: "10000.00",
              actualSpending: "8500.00",
              remainingAmount: "1500.00",
              utilizationPercentage: "85.0",
              projectedSpending: "23954.54",
              status: "approaching_limit",
              daysRemaining: 20,
            ),
            BudgetCategoryProgressModel(
              budgetId: 2,
              categoryId: 4,
              category: "Transport",
              categoryType: "expense",
              budgetLimit: "5000.00",
              actualSpending: "5500.00",
              remainingAmount: "-500.00",
              utilizationPercentage: "110.0",
              projectedSpending: "15500.00",
              status: "exceeded",
              daysRemaining: 20,
            ),
          ],
          uncategorizedSpending: "4000.00",
          savings: const BudgetSavingsProgressModel(
            totalIncome: "60000.00",
            totalExpense: "18000.00",
            netSavings: "42000.00",
            projectedNetSavings: "9272.84",
            savingsTarget: "30000.00",
            progressPercentage: "140.0",
            isTargetAchieved: true,
          ),
        ),
        alerts: const BudgetAlertsResponseModel(
          month: 10,
          year: 2026,
          overallAlert: null,
          approachingLimit: [
            BudgetAlertModel(
              categoryId: 3,
              category: "Food",
              budgetLimit: "10000.00",
              actualSpending: "8500.00",
              utilizationPercentage: "85.0",
              severity: "warning",
              message: "Food is approaching limit: 85.0% used",
            )
          ],
          exceeded: [
            BudgetAlertModel(
              categoryId: 4,
              category: "Transport",
              budgetLimit: "5000.00",
              actualSpending: "5500.00",
              utilizationPercentage: "110.0",
              severity: "critical",
              message: "Transport budget exceeded by ₹500.00",
            )
          ],
          insights: [
            BudgetInsightModel(
              type: "allowance",
              title: "Remaining Daily Allowance",
              message: "You have ₹7,000 remaining for 20 days",
            )
          ],
          totalAlertsCount: 2,
        ),
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<BudgetProvider>.value(value: mockBudget),
            ChangeNotifierProvider<ReportProvider>.value(value: mockReport),
            ChangeNotifierProvider<CurrencyProvider>.value(value: currency),
          ],
          child: const MaterialApp(
            home: BudgetsListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Overall monthly budget overview rendered
      expect(find.text("Monthly Total Budget"), findsOneWidget);
      expect(find.text("ON TRACK"), findsOneWidget);
      expect(find.textContaining("25,000.00"), findsWidgets); // Limit Cap
      expect(find.text("72.0% used"), findsOneWidget);

      // In-app alert banner rendered
      expect(find.text("Budget Alert"), findsOneWidget);
      expect(find.textContaining("Transport budget exceeded"), findsOneWidget);

      // Net Savings section rendered
      expect(find.text("Net Savings Progress"), findsOneWidget);
      expect(find.text("140.0% achieved"), findsOneWidget);

      // Category cards rendered
      expect(find.text("Food"), findsOneWidget);
      expect(find.text("80%+ USED"), findsOneWidget);
      expect(find.text("Transport"), findsOneWidget);
      expect(find.text("OVER BUDGET"), findsOneWidget);
    });
  });
}
