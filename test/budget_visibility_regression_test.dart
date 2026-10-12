import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/theme/fin_track_theme_tokens.dart';
import 'package:frontend/models/budget_model.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/screens/budgets/budgets_list_screen.dart';
import 'package:frontend/screens/budgets/widgets/budget_empty_state.dart';
import 'package:frontend/screens/budgets/widgets/budget_hero_overview.dart';
import 'package:frontend/screens/budgets/widgets/category_budget_card.dart';

class TestableBudgetProvider extends BudgetProvider {
  BudgetProgressResponseModel? _simulatedProgress;
  List<BudgetStatusModel> _simulatedStatuses = [];
  List<BudgetModel> _simulatedBudgets = [];
  bool _simulatedLoading = false;
  String? _simulatedError;
  int _activeMonth = 10;
  int _activeYear = 2026;

  int loadAllCallCount = 0;

  @override
  int get selectedMonth => _activeMonth;

  @override
  int get selectedYear => _activeYear;

  @override
  BudgetProgressResponseModel? get progress => _simulatedProgress;

  @override
  List<BudgetStatusModel> get budgetStatuses => _simulatedStatuses;

  @override
  List<BudgetModel> get budgets => _simulatedBudgets;

  @override
  bool get isLoading => _simulatedLoading;

  @override
  String? get errorMessage => _simulatedError;

  void setTestState({
    BudgetProgressResponseModel? progress,
    List<BudgetStatusModel>? statuses,
    List<BudgetModel>? budgets,
    bool isLoading = false,
    String? error,
    int month = 10,
    int year = 2026,
  }) {
    _simulatedProgress = progress;
    _simulatedStatuses = statuses ?? [];
    _simulatedBudgets = budgets ?? [];
    _simulatedLoading = isLoading;
    _simulatedError = error;
    _activeMonth = month;
    _activeYear = year;
    notifyListeners();
  }

  @override
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {
    loadAllCallCount++;
    // Simulates successful fetch
    notifyListeners();
  }

  void simulateBudgetCreated({
    required int budgetId,
    required int categoryId,
    required String category,
    required String limit,
  }) {
    _simulatedProgress = BudgetProgressResponseModel(
      month: _activeMonth,
      year: _activeYear,
      period: const BudgetPeriodModel(
        daysInMonth: 31,
        daysElapsed: 12,
        daysRemaining: 19,
        isCurrentPeriod: true,
        estimationMethod: "Linear Daily Burn-Rate",
      ),
      overall: BudgetOverallProgressModel(
        budgetLimit: limit,
        actualSpending: "0.00",
        remainingAmount: limit,
        utilizationPercentage: "0.0",
        dailyBurnRate: "0.00",
        projectedSpending: "0.00",
        status: "on_track",
        hasBudgetsDefined: true,
      ),
      categoryBudgets: [
        BudgetCategoryProgressModel(
          budgetId: budgetId,
          categoryId: categoryId,
          category: category,
          categoryType: "expense",
          budgetLimit: limit,
          actualSpending: "0.00",
          remainingAmount: limit,
          utilizationPercentage: "0.0",
          projectedSpending: "0.00",
          status: "on_track",
          daysRemaining: 19,
        ),
      ],
      uncategorizedSpending: "0.00",
      savings: const BudgetSavingsProgressModel(
        totalIncome: "50000.00",
        totalExpense: "0.00",
        netSavings: "50000.00",
        projectedNetSavings: "50000.00",
        isTargetAchieved: true,
      ),
    );
    notifyListeners();
  }
}

class TestableReportProvider extends ReportProvider {
  @override
  Future<void> loadAllReports() async {}
}

Widget createTestApp({
  required BudgetProvider budgetProvider,
  required ReportProvider reportProvider,
  required CurrencyProvider currencyProvider,
  ThemeData? theme,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
      ChangeNotifierProvider<ReportProvider>.value(value: reportProvider),
      ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
    ],
    child: MaterialApp(
      theme: theme ??
          ThemeData.dark().copyWith(
            extensions: const [FinTrackThemeTokens.graphiteChampagneDark],
          ),
      home: const BudgetsListScreen(),
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
  });

  group('FinTrack 2.0: Budget Visibility & Animated Cards Regression Tests', () {
    testWidgets(
        'Regression: Creating budget immediately replaces empty state with populated hero, card, and FAB',
        (tester) async {
      final budgetProvider = TestableBudgetProvider();
      final reportProvider = TestableReportProvider();
      final currency = CurrencyProvider();

      // Start: No budgets configured -> displays empty state
      budgetProvider.setTestState(progress: null);

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          budgetProvider: budgetProvider,
          reportProvider: reportProvider,
          currencyProvider: currency,
        ),
      );
      await tester.pumpAndSettle();

      // Empty state visible initially
      expect(find.byType(BudgetEmptyState), findsOneWidget);
      expect(find.text("Shape Your Living Budget"), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byType(CategoryBudgetCard), findsNothing);

      // Action: Budget is created
      budgetProvider.simulateBudgetCreated(
        budgetId: 101,
        categoryId: 3,
        category: "Food",
        limit: "15000.00",
      );
      await tester.pumpAndSettle();

      // Verified: Empty state is GONE immediately
      expect(find.byType(BudgetEmptyState), findsNothing);
      expect(find.text("Shape Your Living Budget"), findsNothing);

      // Verified: Monthly Total Budget overview appears
      expect(find.byType(BudgetHeroOverview), findsOneWidget);
      expect(find.text("Monthly Total Budget"), findsOneWidget);

      // Verified: Category card appears with Food identity
      expect(find.byType(CategoryBudgetCard), findsOneWidget);
      expect(find.text("Food"), findsOneWidget);
      expect(find.text("ON TRACK"), findsWidgets);

      // Verified: Contextual Add Budget FAB is rendered
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text("Add Budget"), findsOneWidget);
    });

    testWidgets(
        'Regression: Meaningful error card is displayed when loading fails instead of incorrectly showing empty state',
        (tester) async {
      final budgetProvider = TestableBudgetProvider();
      final reportProvider = TestableReportProvider();
      final currency = CurrencyProvider();

      budgetProvider.setTestState(
        progress: null,
        error: "Connection timeout to FinTrack budget service",
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          budgetProvider: budgetProvider,
          reportProvider: reportProvider,
          currencyProvider: currency,
        ),
      );
      await tester.pumpAndSettle();

      // Verified: Empty state is NOT incorrectly displayed on error
      expect(find.byType(BudgetEmptyState), findsNothing);

      // Verified: Explicit error card is displayed
      expect(find.text("Unable to Load Budgets"), findsOneWidget);
      expect(find.textContaining("Connection timeout"), findsOneWidget);
      expect(find.text("Retry"), findsOneWidget);

      // Tapping retry triggers reload
      await tester.tap(find.text("Retry"));
      await tester.pump();
      expect(budgetProvider.loadAllCallCount, greaterThan(0));
    });

    testWidgets(
        'Living Category Cards: Food, Transport, Shopping, Healthcare, Utilities render distinct identities and expand',
        (tester) async {
      final budgetProvider = TestableBudgetProvider();
      final reportProvider = TestableReportProvider();
      final currency = CurrencyProvider();

      budgetProvider.setTestState(
        progress: BudgetProgressResponseModel(
          month: 10,
          year: 2026,
          period: const BudgetPeriodModel(
            daysInMonth: 31,
            daysElapsed: 15,
            daysRemaining: 16,
            isCurrentPeriod: true,
            estimationMethod: "Linear Daily Burn-Rate",
          ),
          overall: const BudgetOverallProgressModel(
            budgetLimit: "50000.00",
            actualSpending: "32000.00",
            remainingAmount: "18000.00",
            utilizationPercentage: "64.0",
            dailyBurnRate: "2133.33",
            projectedSpending: "66133.33",
            status: "on_track",
            hasBudgetsDefined: true,
          ),
          categoryBudgets: const [
            BudgetCategoryProgressModel(
              budgetId: 1,
              categoryId: 3,
              category: "Food",
              categoryType: "expense",
              budgetLimit: "15000.00",
              actualSpending: "8000.00",
              remainingAmount: "7000.00",
              utilizationPercentage: "53.3",
              projectedSpending: "16533.33",
              status: "on_track",
              daysRemaining: 16,
            ),
            BudgetCategoryProgressModel(
              budgetId: 2,
              categoryId: 4,
              category: "Transport",
              categoryType: "expense",
              budgetLimit: "8000.00",
              actualSpending: "6800.00",
              remainingAmount: "1200.00",
              utilizationPercentage: "85.0",
              projectedSpending: "14044.44",
              status: "approaching_limit",
              daysRemaining: 16,
            ),
            BudgetCategoryProgressModel(
              budgetId: 3,
              categoryId: 9,
              category: "Shopping",
              categoryType: "expense",
              budgetLimit: "10000.00",
              actualSpending: "12500.00",
              remainingAmount: "-2500.00",
              utilizationPercentage: "125.0",
              projectedSpending: "25833.33",
              status: "exceeded",
              daysRemaining: 16,
            ),
            BudgetCategoryProgressModel(
              budgetId: 4,
              categoryId: 6,
              category: "Utilities",
              categoryType: "expense",
              budgetLimit: "7000.00",
              actualSpending: "4200.00",
              remainingAmount: "2800.00",
              utilizationPercentage: "60.0",
              projectedSpending: "8680.00",
              status: "on_track",
              daysRemaining: 16,
            ),
            BudgetCategoryProgressModel(
              budgetId: 5,
              categoryId: 7,
              category: "Healthcare",
              categoryType: "expense",
              budgetLimit: "5000.00",
              actualSpending: "1500.00",
              remainingAmount: "3500.00",
              utilizationPercentage: "30.0",
              projectedSpending: "3100.00",
              status: "on_track",
              daysRemaining: 16,
            ),
          ],
          uncategorizedSpending: "0.00",
          savings: const BudgetSavingsProgressModel(
            totalIncome: "80000.00",
            totalExpense: "32000.00",
            netSavings: "48000.00",
            projectedNetSavings: "13866.67",
            isTargetAchieved: true,
          ),
        ),
      );

      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createTestApp(
          budgetProvider: budgetProvider,
          reportProvider: reportProvider,
          currencyProvider: currency,
        ),
      );
      await tester.pumpAndSettle();

      // All 5 category cards rendered
      expect(find.byType(CategoryBudgetCard), findsNWidgets(5));
      expect(find.text("Food"), findsOneWidget);
      expect(find.text("Transport"), findsOneWidget);
      expect(find.text("Shopping"), findsOneWidget);
      expect(find.text("Utilities"), findsOneWidget);
      expect(find.text("Healthcare"), findsOneWidget);

      // Financial status indicators
      expect(find.text("80%+ USED"), findsOneWidget); // Transport
      expect(find.text("OVER BUDGET"), findsOneWidget); // Shopping
      expect(find.text("ON TRACK"), findsWidgets);

      // Living Category Specific Visual Elements rendered
      expect(find.text("Dining Allowance"), findsOneWidget); // Food
      expect(find.text("Commute Route Track"), findsOneWidget); // Transport
      expect(find.text("Retail Spending Gauge"), findsOneWidget); // Shopping
      expect(find.text("Recurring Billing Segments"), findsOneWidget); // Utilities
      expect(find.text("Vitals: Healthy Range"), findsOneWidget); // Healthcare

      // Card tap reveals smooth expanded details
      await tester.tap(find.text("Food"));
      await tester.pumpAndSettle();

      expect(find.text("Category Spending Insights"), findsOneWidget);
      expect(find.text("Projected EOM Spend:"), findsOneWidget);
      expect(find.text("Edit Limit"), findsOneWidget);
    });

    testWidgets('Theme consistency: Renders seamlessly across all three FinTrack themes',
        (tester) async {
      final budgetProvider = TestableBudgetProvider();
      final reportProvider = TestableReportProvider();
      final currency = CurrencyProvider();

      budgetProvider.simulateBudgetCreated(
        budgetId: 1,
        categoryId: 3,
        category: "Food",
        limit: "10000.00",
      );

      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Graphite & Champagne Dark
      await tester.pumpWidget(
        createTestApp(
          budgetProvider: budgetProvider,
          reportProvider: reportProvider,
          currencyProvider: currency,
          theme: ThemeData.dark().copyWith(
            extensions: const [FinTrackThemeTokens.graphiteChampagneDark],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Food"), findsOneWidget);

      // 2. Obsidian & Jade Light
      await tester.pumpWidget(
        createTestApp(
          budgetProvider: budgetProvider,
          reportProvider: reportProvider,
          currencyProvider: currency,
          theme: ThemeData.light().copyWith(
            extensions: const [FinTrackThemeTokens.obsidianJadeLight],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Food"), findsOneWidget);

      // 3. Arctic Blue Dark
      await tester.pumpWidget(
        createTestApp(
          budgetProvider: budgetProvider,
          reportProvider: reportProvider,
          currencyProvider: currency,
          theme: ThemeData.dark().copyWith(
            extensions: const [FinTrackThemeTokens.arcticBlueDark],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text("Food"), findsOneWidget);
    });
  });
}
