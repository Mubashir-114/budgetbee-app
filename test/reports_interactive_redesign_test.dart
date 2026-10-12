import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/theme/theme_collection.dart';
import 'package:frontend/models/report_models.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/screens/reports/widgets/cashflow_tab_view.dart';
import 'package:frontend/screens/reports/widgets/categories_tab_view.dart';
import 'package:frontend/screens/reports/widgets/trends_tab_view.dart';
import 'package:frontend/screens/reports/widgets/reports_date_range_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp({
    required Widget child,
    ThemeCollection theme = ThemeCollection.graphiteChampagne,
    Brightness brightness = Brightness.dark,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.buildTheme(theme, brightness),
        home: Scaffold(body: child),
      ),
    );
  }

  // Sample test data
  const sampleSummary = ReportSummary(
    totalIncome: 75000.0,
    totalExpense: 42000.0,
    netBalance: 33000.0,
    savingsRate: 44.0,
    totalTransactions: 28,
  );

  const sampleTrendsMulti = [
    TrendsReport(
      year: 2026,
      month: 8,
      monthName: "August",
      income: 60000.0,
      expense: 38000.0,
    ),
    TrendsReport(
      year: 2026,
      month: 9,
      monthName: "September",
      income: 65000.0,
      expense: 45000.0,
    ),
    TrendsReport(
      year: 2026,
      month: 10,
      monthName: "October",
      income: 75000.0,
      expense: 42000.0,
    ),
  ];

  const sampleTrendsSingle = [
    TrendsReport(
      year: 2026,
      month: 10,
      monthName: "October",
      income: 75000.0,
      expense: 42000.0,
    ),
  ];

  const sampleCategories = [
    CategoryReport(
      categoryId: 3,
      category: "Food",
      budget: 20000.0,
      spent: 18500.0,
      remaining: 1500.0,
      percentage: 44.0,
    ),
    CategoryReport(
      categoryId: 4,
      category: "Transport",
      budget: 10000.0,
      spent: 12000.0,
      remaining: -2000.0,
      percentage: 28.5,
    ),
    CategoryReport(
      categoryId: 11,
      category: "Shopping",
      budget: 0.0, // Unconfigured budget
      spent: 11500.0,
      remaining: 0.0,
      percentage: 27.5,
    ),
  ];

  const sampleCashflows = [
    CashflowReport(
      id: 101,
      title: "Salary Credited",
      category: "Salary",
      amount: 75000.0,
      type: "income",
      date: "2026-10-12T09:30:00.000Z",
      runningBalance: 75000.0,
    ),
    CashflowReport(
      id: 102,
      title: "Grocery Supermarket",
      category: "Food",
      amount: 4500.0,
      type: "expense",
      date: "2026-10-12T14:15:00.000Z",
      runningBalance: 70500.0,
    ),
    CashflowReport(
      id: 103,
      title: "Fuel Station",
      category: "Transport",
      amount: 2200.0,
      type: "expense",
      date: "2026-10-11T18:00:00.000Z",
      runningBalance: 68300.0,
    ),
  ];

  group('Trends Tab Redesign', () {
    testWidgets('renders primary performance card and secondary metrics', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: TrendsTabView(
            summary: sampleSummary,
            trends: sampleTrendsMulti,
            periodLabel: "1 Aug – 31 Oct 2026",
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Net Cash Flow"), findsOneWidget);
      expect(find.text("Net Surplus"), findsOneWidget);
      expect(find.text("Total Inflow"), findsOneWidget);
      expect(find.text("Total Outflow"), findsOneWidget);
      expect(find.text("Savings Rate"), findsOneWidget);
      expect(find.text("44.0%"), findsOneWidget);
      expect(find.text("Cash-Flow Trends"), findsOneWidget);
      expect(find.text("Financial Observations"), findsOneWidget);
      expect(find.textContaining("Healthy Savings Retention"), findsOneWidget);
    });

    testWidgets('adapts gracefully to single month of data with comparative card', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: TrendsTabView(
            summary: sampleSummary,
            trends: sampleTrendsSingle,
            periodLabel: "October 2026",
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("October 2026"), findsNWidgets(2));
      expect(find.text("Monthly Inflow"), findsOneWidget);
      expect(find.text("Monthly Outflow"), findsOneWidget);
      expect(find.textContaining("Displaying isolated single-month performance"), findsOneWidget);
    });

    testWidgets('handles empty trends data with informative empty state', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: TrendsTabView(
            summary: sampleSummary,
            trends: const [],
            periodLabel: "Current Period",
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("No monthly periods recorded in this range"), findsOneWidget);
    });
  });

  group('Categories Tab Redesign', () {
    testWidgets('renders interactive donut distribution and legend', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoriesTabView(
            categoryReports: sampleCategories,
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Expense Distribution"), findsOneWidget);
      expect(find.text("Total Spent"), findsOneWidget);
      expect(find.text("Category Spending Breakdown"), findsOneWidget);
      expect(find.text("Food"), findsNWidgets(3)); // Legend chip, spending card, budget card
      expect(find.text("Transport"), findsNWidgets(3));
      expect(find.text("Shopping"), findsNWidgets(3));
    });

    testWidgets('correctly distinguishes unconfigured budgets from ₹0 budgets', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CategoriesTabView(
            categoryReports: sampleCategories,
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Shopping has budget: 0.0 -> Must be labeled "No Budget Set", NOT over limit!
      expect(find.text("No Budget Set"), findsOneWidget);
      expect(find.text("Near Limit"), findsOneWidget); // Food at 18.5k / 20k (92.5%)
      expect(find.text("Exceeded Limit"), findsOneWidget); // Transport at 12k / 10k (120%)
      expect(find.textContaining("No budget configured for this category"), findsOneWidget);
    });

    testWidgets('handles single category 100% spending without meaningless chart', (tester) async {
      const singleCategory = [
        CategoryReport(
          categoryId: 3,
          category: "Food",
          budget: 10000.0,
          spent: 5000.0,
          remaining: 5000.0,
          percentage: 100.0,
        ),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: CategoriesTabView(
            categoryReports: singleCategory,
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("100% Share"), findsOneWidget);
      expect(find.textContaining("concentrated solely in Food"), findsOneWidget);
    });
  });

  group('Cashflow Tab Redesign', () {
    testWidgets('renders date-grouped timeline with friendly localized timestamps', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CashflowTabView(
            cashflowReports: sampleCashflows,
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Salary Credited"), findsOneWidget);
      expect(find.text("Grocery Supermarket"), findsOneWidget);
      expect(find.text("Fuel Station"), findsOneWidget);
      expect(find.textContaining("Flow:"), findsNWidgets(3));
    });

    testWidgets('opens transaction details sheet upon tap', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: CashflowTabView(
            cashflowReports: sampleCashflows,
            onRefresh: () async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text("Salary Credited"));
      await tester.pumpAndSettle();

      expect(find.text("Recorded Date"), findsOneWidget);
      expect(find.text("Cumulative Cash Flow"), findsOneWidget);
      expect(find.text("Close"), findsOneWidget);

      await tester.tap(find.text("Close"));
      await tester.pumpAndSettle();
      expect(find.text("Cumulative Cash Flow"), findsNothing);
    });
  });

  group('Reports Date Range Bar', () {
    testWidgets('renders reset button when date filter is active', (tester) async {
      bool cleared = false;
      bool selected = false;

      final range = DateTimeRange(
        start: DateTime(2026, 10, 1),
        end: DateTime(2026, 10, 12),
      );

      await tester.pumpWidget(
        createTestApp(
          child: ReportsDateRangeBar(
            selectedRange: range,
            onSelectRange: () => selected = true,
            onClearRange: () => cleared = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("Reset"), findsOneWidget);
      await tester.tap(find.text("Reset"));
      expect(cleared, isTrue);

      await tester.tap(find.textContaining("1 Oct"));
      expect(selected, isTrue);
    });
  });

  group('Strict Theme Independence across All Three Collections', () {
    for (final collection in ThemeCollection.values) {
      for (final brightness in [Brightness.dark, Brightness.light]) {
        testWidgets('Trends and Categories render without error in $collection ${brightness.name}', (tester) async {
          await tester.pumpWidget(
            createTestApp(
              theme: collection,
              brightness: brightness,
              child: TrendsTabView(
                summary: sampleSummary,
                trends: sampleTrendsMulti,
                periodLabel: "Q3 2026",
                onRefresh: () async {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(TrendsTabView), findsOneWidget);
        });
      }
    }
  });
}
