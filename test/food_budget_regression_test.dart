import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/core/theme/fin_track_theme_tokens.dart';
import 'package:frontend/models/budget_model.dart';
import 'package:frontend/models/category_model.dart';
import 'package:frontend/providers/budget_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/report_provider.dart';
import 'package:frontend/screens/budgets/budgets_list_screen.dart';
import 'package:frontend/screens/budgets/widgets/category_budget_card.dart';

class MockBudgetProvider extends BudgetProvider {
  BudgetProgressResponseModel? _simProgress;
  List<BudgetStatusModel> _simStatuses = [];
  List<BudgetModel> _simBudgets = [];
  final bool _simLoading = false;
  String? _simError;
  int _simMonth = 10;
  int _simYear = 2026;

  int addBudgetCalls = 0;
  int? lastAddedCategoryId;
  double? lastAddedAmount;
  int? lastAddedMonth;
  int? lastAddedYear;
  int loadAllCount = 0;

  @override
  int get selectedMonth => _simMonth;

  @override
  int get selectedYear => _simYear;

  @override
  BudgetProgressResponseModel? get progress => _simProgress;

  @override
  List<BudgetStatusModel> get budgetStatuses => _simStatuses;

  @override
  List<BudgetModel> get budgets => _simBudgets;

  @override
  bool get isLoading => _simLoading;

  @override
  String? get errorMessage => _simError;

  void initializeOctober2026WithHealthcareAndEntertainment() {
    _simMonth = 10;
    _simYear = 2026;

    // Budget records matching MySQL state for Oct 2026:
    // Healthcare (id: 5, catId: 7) and Entertainment (id: 6, catId: 8)
    _simBudgets = [
      const BudgetModel(
        id: 5,
        userId: 8,
        categoryId: 7,
        category: "Healthcare",
        categoryType: "expense",
        amount: 1000.0,
        month: 10,
        year: 2026,
        createdAt: "2026-10-12T07:22:00.000Z",
      ),
      const BudgetModel(
        id: 6,
        userId: 8,
        categoryId: 8,
        category: "Entertainment",
        categoryType: "expense",
        amount: 1000.0,
        month: 10,
        year: 2026,
        createdAt: "2026-10-12T09:41:18.000Z",
      ),
    ];

    _simStatuses = [
      BudgetStatusModel(
        budgetId: 5,
        categoryId: 7,
        category: "Healthcare",
        budget: 1000.0,
        spent: 0.0,
        remaining: 1000.0,
        percentageUsed: 0.0,
        status: "normal",
      ),
      BudgetStatusModel(
        budgetId: 6,
        categoryId: 8,
        category: "Entertainment",
        budget: 1000.0,
        spent: 0.0,
        remaining: 1000.0,
        percentageUsed: 0.0,
        status: "normal",
      ),
    ];

    // Progress response for initial state:
    // Food expense of ₹450 exists (Transaction 24), but Food budget is not yet defined,
    // so it shows as uncategorizedSpending: "450.00"
    _simProgress = BudgetProgressResponseModel(
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
        budgetLimit: "2000.00",
        actualSpending: "450.00",
        remainingAmount: "1550.00",
        utilizationPercentage: "22.5",
        dailyBurnRate: "37.50",
        projectedSpending: "1162.50",
        status: "on_track",
        hasBudgetsDefined: true,
      ),
      categoryBudgets: [
        const BudgetCategoryProgressModel(
          budgetId: 5,
          categoryId: 7,
          category: "Healthcare",
          categoryType: "expense",
          budgetLimit: "1000.00",
          actualSpending: "0.00",
          remainingAmount: "1000.00",
          utilizationPercentage: "0.0",
          projectedSpending: "0.00",
          status: "on_track",
          daysRemaining: 19,
        ),
        const BudgetCategoryProgressModel(
          budgetId: 6,
          categoryId: 8,
          category: "Entertainment",
          categoryType: "expense",
          budgetLimit: "1000.00",
          actualSpending: "0.00",
          remainingAmount: "1000.00",
          utilizationPercentage: "0.0",
          projectedSpending: "0.00",
          status: "on_track",
          daysRemaining: 19,
        ),
      ],
      uncategorizedSpending: "450.00",
      savings: const BudgetSavingsProgressModel(
        totalIncome: "210000.00",
        totalExpense: "450.00",
        netSavings: "209550.00",
        projectedNetSavings: "208837.50",
        isTargetAchieved: true,
      ),
    );

    notifyListeners();
  }

  @override
  Future<bool> addBudget({
    required int categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    addBudgetCalls++;
    lastAddedCategoryId = categoryId;
    lastAddedAmount = amount;
    lastAddedMonth = month;
    lastAddedYear = year;

    // Simulate backend persistence: category_id 3 (Food) saved with ID 7
    final newBudget = BudgetModel(
      id: 7,
      userId: 8,
      categoryId: categoryId,
      category: CategoryModel.getNameById(categoryId),
      categoryType: "expense",
      amount: amount,
      month: month,
      year: year,
      createdAt: DateTime.now().toIso8601String(),
    );
    _simBudgets.add(newBudget);

    _simStatuses.add(
      BudgetStatusModel(
        budgetId: 7,
        categoryId: categoryId,
        category: newBudget.category,
        budget: amount,
        spent: categoryId == 3 ? 450.0 : 0.0,
        remaining: categoryId == 3 ? (amount - 450.0) : amount,
        percentageUsed: categoryId == 3 ? ((450.0 / amount) * 100) : 0.0,
        status: "normal",
      ),
    );

    // After Food is budgeted, uncategorized spending drops from 450 to 0
    _simProgress = BudgetProgressResponseModel(
      month: 10,
      year: 2026,
      period: const BudgetPeriodModel(
        daysInMonth: 31,
        daysElapsed: 12,
        daysRemaining: 19,
        isCurrentPeriod: true,
        estimationMethod: "Linear Daily Burn-Rate",
      ),
      overall: BudgetOverallProgressModel(
        budgetLimit: (2000.0 + amount).toStringAsFixed(2),
        actualSpending: "450.00",
        remainingAmount: ((2000.0 + amount) - 450.0).toStringAsFixed(2),
        utilizationPercentage: (((450.0) / (2000.0 + amount)) * 100).toStringAsFixed(1),
        dailyBurnRate: "37.50",
        projectedSpending: "1162.50",
        status: "on_track",
        hasBudgetsDefined: true,
      ),
      categoryBudgets: [
        const BudgetCategoryProgressModel(
          budgetId: 5,
          categoryId: 7,
          category: "Healthcare",
          categoryType: "expense",
          budgetLimit: "1000.00",
          actualSpending: "0.00",
          remainingAmount: "1000.00",
          utilizationPercentage: "0.0",
          projectedSpending: "0.00",
          status: "on_track",
          daysRemaining: 19,
        ),
        const BudgetCategoryProgressModel(
          budgetId: 6,
          categoryId: 8,
          category: "Entertainment",
          categoryType: "expense",
          budgetLimit: "1000.00",
          actualSpending: "0.00",
          remainingAmount: "1000.00",
          utilizationPercentage: "0.0",
          projectedSpending: "0.00",
          status: "on_track",
          daysRemaining: 19,
        ),
        BudgetCategoryProgressModel(
          budgetId: 7,
          categoryId: categoryId,
          category: newBudget.category,
          categoryType: "expense",
          budgetLimit: amount.toStringAsFixed(2),
          actualSpending: "450.00",
          remainingAmount: (amount - 450.0).toStringAsFixed(2),
          utilizationPercentage: ((450.0 / amount) * 100).toStringAsFixed(1),
          projectedSpending: "1162.50",
          status: "on_track",
          daysRemaining: 19,
        ),
      ],
      uncategorizedSpending: "0.00",
      savings: const BudgetSavingsProgressModel(
        totalIncome: "210000.00",
        totalExpense: "450.00",
        netSavings: "209550.00",
        projectedNetSavings: "208837.50",
        isTargetAchieved: true,
      ),
    );

    notifyListeners();
    return true;
  }

  @override
  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {
    loadAllCount++;
    notifyListeners();
  }
}

class MockReportProvider extends ReportProvider {
  @override
  Future<void> loadAllReports() async {}
}

Widget buildTestWidget({
  required BudgetProvider budgetProvider,
  required ReportProvider reportProvider,
  required CurrencyProvider currencyProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<BudgetProvider>.value(value: budgetProvider),
      ChangeNotifierProvider<ReportProvider>.value(value: reportProvider),
      ChangeNotifierProvider<CurrencyProvider>.value(value: currencyProvider),
    ],
    child: MaterialApp(
      theme: ThemeData.dark().copyWith(
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

  group('Food Budget Regression Suite: Creation -> Persistence -> Refresh -> Visibility', () {
    testWidgets(
      'Full lifecycle: Food budget creation correctly maps ID 3, persists, refreshes, and renders Food card with ₹450 spending',
      (tester) async {
        final budgetProvider = MockBudgetProvider();
        final reportProvider = MockReportProvider();
        final currencyProvider = CurrencyProvider();
        await currencyProvider.setCurrency('INR');

        // 1. Initial State: October 2026 has Healthcare (₹1,000) & Entertainment (₹1,000)
        budgetProvider.initializeOctober2026WithHealthcareAndEntertainment();

        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestWidget(
            budgetProvider: budgetProvider,
            reportProvider: reportProvider,
            currencyProvider: currencyProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Verify initial state: Category Budgets (2), Healthcare and Entertainment visible, Food missing
        expect(find.text("Category Budgets (2)"), findsOneWidget);
        expect(find.text("Healthcare"), findsOneWidget);
        expect(find.text("Entertainment"), findsOneWidget);
        expect(find.text("Food"), findsNothing);
        expect(find.byType(CategoryBudgetCard), findsNWidgets(2));

        // 2. Open Add Budget Sheet
        final fab = find.byType(FloatingActionButton);
        expect(fab, findsOneWidget);
        await tester.tap(fab);
        await tester.pumpAndSettle();

        expect(find.byType(AddEditBudgetSheet), findsOneWidget);
        expect(find.text("Add Budget Limit"), findsOneWidget);
        expect(find.text("Target Period: October 2026"), findsOneWidget);

        // Verify default unbudgeted category is Food (id: 3)
        expect(find.text("Food"), findsOneWidget);

        // 3. Enter amount ₹1,000 for Food
        final amountField = find.byType(TextFormField).first;
        await tester.enterText(amountField, "1000");
        await tester.pumpAndSettle();

        // 4. Submit budget creation
        final submitButton = find.widgetWithText(ElevatedButton, "SAVE BUDGET");
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // 5. Verify backend payload submission
        expect(budgetProvider.addBudgetCalls, 1);
        expect(budgetProvider.lastAddedCategoryId, 3, reason: "Food category must submit categoryId: 3");
        expect(budgetProvider.lastAddedAmount, 1000.0);
        expect(budgetProvider.lastAddedMonth, 10);
        expect(budgetProvider.lastAddedYear, 2026);

        // Sheet closed
        expect(find.byType(AddEditBudgetSheet), findsNothing);

        // 6. Verify populated view: Category Budgets (3), Food card now visible with ₹450 spending
        expect(find.text("Category Budgets (3)"), findsOneWidget);
        expect(find.text("Food"), findsOneWidget);
        expect(find.text("Healthcare"), findsOneWidget);
        expect(find.text("Entertainment"), findsOneWidget);
        expect(find.byType(CategoryBudgetCard), findsNWidgets(3));

        // Food budget card shows ₹450 spent against ₹1,000 budget limit
        final foodCard = find.widgetWithText(CategoryBudgetCard, "Food");
        expect(foodCard, findsOneWidget);
        expect(find.descendant(of: foodCard, matching: find.text("Spent: ₹450.00")), findsOneWidget);
        expect(find.descendant(of: foodCard, matching: find.text("Limit: ₹1,000.00")), findsOneWidget);
        expect(find.descendant(of: foodCard, matching: find.text("Remaining: ₹550.00")), findsOneWidget);

        // 7. Verify refresh / reload retains Food card
        await budgetProvider.loadAllBudgetData(forceRefresh: true);
        await tester.pumpAndSettle();

        expect(find.text("Category Budgets (3)"), findsOneWidget);
        expect(find.widgetWithText(CategoryBudgetCard, "Food"), findsOneWidget);
        expect(find.widgetWithText(CategoryBudgetCard, "Healthcare"), findsOneWidget);
        expect(find.widgetWithText(CategoryBudgetCard, "Entertainment"), findsOneWidget);
      },
    );

    testWidgets(
      'Duplicate guard: Attempting to create duplicate Food budget for same period is rejected with clear error',
      (tester) async {
        final budgetProvider = MockBudgetProvider();
        final reportProvider = MockReportProvider();
        final currencyProvider = CurrencyProvider();
        await currencyProvider.setCurrency('INR');

        budgetProvider.initializeOctober2026WithHealthcareAndEntertainment();

        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildTestWidget(
            budgetProvider: budgetProvider,
            reportProvider: reportProvider,
            currencyProvider: currencyProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Add Food budget first
        await budgetProvider.addBudget(
          categoryId: 3,
          amount: 1000.0,
          month: 10,
          year: 2026,
        );
        await tester.pumpAndSettle();
        expect(budgetProvider.addBudgetCalls, 1);

        // Open Add Budget Sheet again
        final fab = find.byType(FloatingActionButton);
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Open Category Dropdown to inspect options
        final dropdownFinder = find.byType(DropdownButtonFormField<int>);
        expect(dropdownFinder, findsOneWidget);
        await tester.tap(dropdownFinder);
        await tester.pumpAndSettle();

        // Dropdown menu overlay displays (Configured) badges for existing categories
        expect(find.text("Configured"), findsWidgets);

        // Select Food (which is already configured)
        final foodOption = find.text("Food").last;
        await tester.tap(foodOption);
        await tester.pumpAndSettle();

        // Try submitting Food again
        final amountField = find.byType(TextFormField).first;
        await tester.enterText(amountField, "500");
        await tester.pumpAndSettle();

        final submitButton = find.widgetWithText(ElevatedButton, "SAVE BUDGET");
        await tester.tap(submitButton);
        await tester.pumpAndSettle();

        // Validation error appears informing user that budget already exists
        expect(find.text("Food already has a budget for October 2026"), findsOneWidget);

        // Submit must NOT dispatch addBudget to provider/backend
        expect(budgetProvider.addBudgetCalls, 1, reason: "Duplicate submission must be guarded and rejected");
      },
    );
  });
}
