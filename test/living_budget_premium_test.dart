import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/budget_model.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/screens/budgets/budgets_list_screen.dart';
import 'package:frontend/screens/budgets/widgets/budget_empty_state.dart';
import 'package:frontend/screens/budgets/widgets/budget_hero_overview.dart';
import 'package:frontend/screens/budgets/widgets/budget_month_selector.dart';
import 'package:frontend/screens/budgets/widgets/category_budget_card.dart';
import 'package:frontend/core/services/cache_service.dart';

class MockBudgetProvider extends BudgetProvider {
  BudgetProgressResponseModel? _mockProgress;
  BudgetAlertsResponseModel? _mockAlerts;
  List<BudgetSuggestionModel> _mockSuggestions = [];
  List<BudgetHistoryItemModel> _mockHistory = [];
  bool _mockLoading = false;
  String? _mockError;

  int _currentMonth = 10;
  int _currentYear = 2026;

  int changeDateCallCount = 0;
  int lastChangedMonth = 0;
  int lastChangedYear = 0;

  @override
  int get selectedMonth => _currentMonth;

  @override
  int get selectedYear => _currentYear;

  void setMockData({
    BudgetProgressResponseModel? progress,
    BudgetAlertsResponseModel? alerts,
    List<BudgetSuggestionModel>? suggestions,
    List<BudgetHistoryItemModel>? history,
    bool isLoading = false,
    String? error,
    int month = 10,
    int year = 2026,
  }) {
    _mockProgress = progress;
    _mockAlerts = alerts;
    _mockSuggestions = suggestions ?? [];
    _mockHistory = history ?? [];
    _mockLoading = isLoading;
    _mockError = error;
    _currentMonth = month;
    _currentYear = year;
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
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {}

  @override
  Future<void> loadBudgetSuggestions() async {}

  @override
  Future<void> loadBudgetHistory({int months = 6}) async {}

  @override
  void changeDate(int month, int year) {
    changeDateCallCount++;
    lastChangedMonth = month;
    lastChangedYear = year;
    _currentMonth = month;
    _currentYear = year;
    notifyListeners();
  }
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

  group('FinTrack 2.0: THE LIVING BUDGET Premium UI Tests', () {
    testWidgets('Empty State renders distinct vector illustration, unified CTA, and NO duplicate FAB',
        (tester) async {
      final mockBudget = MockBudgetProvider();
      final mockReport = MockReportProvider();
      final currency = CurrencyProvider();

      mockBudget.setMockData(
        progress: null, // Zero budgets defined
        alerts: null,
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

      // Empty state illustration and onboarding texts rendered
      expect(find.byType(BudgetEmptyState), findsOneWidget);
      expect(find.text("Shape Your Living Budget"), findsOneWidget);
      expect(find.text("Create Budget"), findsOneWidget);
      expect(find.text("Explore Suggestions"), findsOneWidget);

      // CRITICAL REQUIREMENT: No duplicate competing FloatingActionButton when empty
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('Populated state renders Hero Overview, Category Cards, and Contextual FAB',
        (tester) async {
      final mockBudget = MockBudgetProvider();
      final mockReport = MockReportProvider();
      final currency = CurrencyProvider();

      mockBudget.setMockData(
        month: 10,
        year: 2026,
        progress: BudgetProgressResponseModel(
          month: 10,
          year: 2026,
          period: const BudgetPeriodModel(
            daysInMonth: 31,
            daysElapsed: 12,
            daysRemaining: 19,
            isCurrentPeriod: true,
            estimationMethod: "Linear Daily Burn-Rate",
          ),
          overall: const BudgetOverallProgressModel(
            budgetLimit: "30000.00",
            actualSpending: "12500.00",
            remainingAmount: "17500.00",
            utilizationPercentage: "41.7",
            dailyBurnRate: "1041.67",
            projectedSpending: "32291.67",
            status: "on_track",
            hasBudgetsDefined: true,
          ),
          categoryBudgets: const [
            BudgetCategoryProgressModel(
              budgetId: 10,
              categoryId: 3,
              category: "Food",
              categoryType: "expense",
              budgetLimit: "12000.00",
              actualSpending: "6000.00",
              remainingAmount: "6000.00",
              utilizationPercentage: "50.0",
              projectedSpending: "15500.00",
              status: "on_track",
              daysRemaining: 19,
            ),
          ],
          uncategorizedSpending: "500.00",
          savings: const BudgetSavingsProgressModel(
            totalIncome: "75000.00",
            totalExpense: "12500.00",
            netSavings: "62500.00",
            projectedNetSavings: "42708.33",
            savingsTarget: "40000.00",
            progressPercentage: "156.3",
            isTargetAchieved: true,
          ),
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

      // Hero overview rendered
      expect(find.byType(BudgetHeroOverview), findsOneWidget);
      expect(find.text("Monthly Total Budget"), findsOneWidget);
      expect(find.text("ON TRACK"), findsWidgets);

      // Category card rendered
      expect(find.byType(CategoryBudgetCard), findsOneWidget);
      expect(find.text("Food"), findsOneWidget);

      // Contextual FAB is visible when budgets are populated
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text("Add Budget"), findsOneWidget);
    });

    testWidgets('Month selector handles previous and next month navigation seamlessly',
        (tester) async {
      final mockBudget = MockBudgetProvider();
      final mockReport = MockReportProvider();
      final currency = CurrencyProvider();

      mockBudget.setMockData(month: 10, year: 2026);

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

      // Find month selector
      expect(find.byType(BudgetMonthSelector), findsOneWidget);

      // Tap previous month
      final prevBtn = find.byTooltip("Previous Month");
      expect(prevBtn, findsOneWidget);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      expect(mockBudget.changeDateCallCount, 1);
      expect(mockBudget.lastChangedMonth, 9);
      expect(mockBudget.lastChangedYear, 2026);

      // Tap next month
      final nextBtn = find.byTooltip("Next Month");
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      expect(mockBudget.changeDateCallCount, 2);
      expect(mockBudget.lastChangedMonth, 10);
      expect(mockBudget.lastChangedYear, 2026);
    });
  });
}
