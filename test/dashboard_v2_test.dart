import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/dashboard_models.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/screens/dashboard/dashboard_screen.dart';
import 'package:frontend/core/services/cache_service.dart';

class MockAuthProvider extends AuthProvider {
  UserModel? _mockUser;

  void setMockUser(UserModel user) {
    _mockUser = user;
    notifyListeners();
  }

  @override
  UserModel? get currentUser => _mockUser;
}

class MockDashboardProvider extends DashboardProvider {
  DashboardSummary? _mockSummary;
  List<MonthlySummary> _mockMonthly = [];
  List<CategorySummary> _mockCategories = [];
  List<TransactionModel> _mockRecent = [];
  bool _mockLoading = false;
  String? _mockError;

  void setMockData({
    DashboardSummary? summary,
    List<MonthlySummary>? monthly,
    List<CategorySummary>? categories,
    List<TransactionModel>? recent,
    bool isLoading = false,
    String? error,
  }) {
    _mockSummary = summary;
    _mockMonthly = monthly ?? [];
    _mockCategories = categories ?? [];
    _mockRecent = recent ?? [];
    _mockLoading = isLoading;
    _mockError = error;
    notifyListeners();
  }

  @override
  DashboardSummary? get summary => _mockSummary;

  @override
  FinancialOverview? get overview => _mockSummary?.overview;

  @override
  List<DashboardAccountItem> get accounts => _mockSummary?.accounts ?? [];

  @override
  List<MonthlySummary> get monthlySummaries => _mockMonthly;

  @override
  List<CategorySummary> get categorySummaries =>
      _mockSummary?.categories.isNotEmpty == true ? _mockSummary!.categories : _mockCategories;

  @override
  List<SpendingMerchant> get topMerchants => _mockSummary?.topMerchants ?? [];

  @override
  List<FinancialInsight> get insights => _mockSummary?.insights ?? [];

  @override
  List<TransactionModel> get recentTransactions => _mockRecent;

  @override
  bool get isLoading => _mockLoading;

  @override
  String? get errorMessage => _mockError;

  @override
  Future<void> loadDashboardData() async {
    // No-op in widget mock
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheService.initialize();
  });

  group('Dashboard 2.0 Model Serialization', () {
    test('DashboardSummary parses rich 2.0 payload correctly with exact strings', () {
      final json = {
        'totalIncome': 50000.0,
        'totalExpense': 20000.0,
        'balance': 30000.0,
        'smsImportedToday': 2,
        'totalSmsImported': 15,
        'overview': {
          'totalAssets': '150000.00',
          'totalLiabilities': '25000.00',
          'netWorth': '125000.00',
          'monthlyIncome': '50000.00',
          'monthlyExpenses': '20000.00',
          'monthlyNetSavings': '30000.00',
          'savingsRate': '60.0',
          'monthOverMonth': {
            'incomeChangePercent': '+10.5',
            'expenseChangePercent': '-5.0',
            'savingsChangePercent': '+25.0',
          },
        },
        'accounts': {
          'items': [
            {
              'id': 1,
              'displayName': 'Main Bank',
              'type': 'bank',
              'subtype': 'savings',
              'currencyCode': 'INR',
              'currentBalance': '150000.00',
              'isDefault': true,
              'status': 'active',
              'assetPercentage': '100.0',
            },
            {
              'id': 2,
              'displayName': 'Millennia Card',
              'type': 'credit_card',
              'currentBalance': '25000.00',
              'outstandingDebt': '25000.00',
              'creditLimit': '100000.00',
              'availableCredit': '75000.00',
              'utilizationPercentage': '25.00',
              'billingStatus': 'due_soon',
              'isDefault': false,
              'status': 'active',
            },
          ],
        },
        'spending': {
          'byCategory': [
            {
              'id': 10,
              'name': 'Dining',
              'total': '12000.00',
              'percentage': '60.0',
            },
          ],
          'topMerchants': [
            {
              'merchant': 'Swiggy',
              'total': '8000.00',
              'count': 6,
              'percentage': '40.0',
            },
          ],
        },
        'insights': [
          {
            'type': 'highest_category',
            'message': 'Highest spending category is Dining.',
          },
        ],
        'period': {
          'selectedMonth': '2026-10',
          'type': 'current_month',
        },
      };

      final summary = DashboardSummary.fromJson(json);

      expect(summary.totalIncome, 50000.0);
      expect(summary.totalExpense, 20000.0);
      expect(summary.balance, 30000.0);
      expect(summary.smsImportedToday, 2);
      expect(summary.totalSmsImported, 15);

      final overview = summary.overview!;
      expect(overview.totalAssets, '150000.00');
      expect(overview.totalLiabilities, '25000.00');
      expect(overview.netWorth, '125000.00');
      expect(overview.incomeChangePercent, '+10.5');
      expect(overview.expenseChangePercent, '-5.0');
      expect(overview.savingsChangePercent, '+25.0');

      expect(summary.accounts.length, 2);
      expect(summary.accounts[0].displayName, 'Main Bank');
      expect(summary.accounts[0].currentBalance, '150000.00');
      expect(summary.accounts[1].outstandingDebt, '25000.00');
      expect(summary.accounts[1].utilizationPercentage, '25.00');

      expect(summary.categories.length, 1);
      expect(summary.categories[0].name, 'Dining');
      expect(summary.topMerchants[0].merchant, 'Swiggy');
      expect(summary.insights[0].type, 'highest_category');

      // Round-trip toJson
      final exported = summary.toJson();
      expect(exported['overview']['netWorth'], '125000.00');
      expect(exported['accounts']['items'].length, 2);
    });

    test('handles fallback serialization gracefully for minimal old payloads', () {
      final oldJson = {
        'totalIncome': 1000.0,
        'totalExpense': 400.0,
        'balance': 600.0,
      };

      final summary = DashboardSummary.fromJson(oldJson);
      expect(summary.totalIncome, 1000.0);
      expect(summary.totalExpense, 400.0);
      expect(summary.balance, 600.0);
      expect(summary.overview, isNull);
      expect(summary.accounts, isEmpty);
      expect(summary.categories, isEmpty);
    });
  });

  group('DashboardProvider Session Isolation & Invalidation', () {
    test('clearSession resets state and isolates generations', () {
      final provider = DashboardProvider();
      provider.clearSession();

      expect(provider.summary, isNull);
      expect(provider.overview, isNull);
      expect(provider.accounts, isEmpty);
      expect(provider.monthlySummaries, isEmpty);
      expect(provider.categorySummaries, isEmpty);
      expect(provider.recentTransactions, isEmpty);
      expect(provider.selectedPeriod, 'current_month');
      expect(provider.selectedMonth, isNull);
    });
  });

  group('DashboardScreen Widget Functionality', () {
    testWidgets('renders Net Worth, Cash Flow, Accounts, and Categories accurately', (tester) async {
      final mockProvider = MockDashboardProvider();
      mockProvider.setMockData(
        summary: DashboardSummary.fromJson({
          'overview': {
            'totalAssets': '50000.00',
            'totalLiabilities': '15000.00',
            'netWorth': '35000.00',
            'monthlyIncome': '25000.00',
            'monthlyExpenses': '8000.00',
            'monthlyNetSavings': '17000.00',
            'savingsRate': '68.0',
            'monthOverMonth': {
              'incomeChangePercent': '+12.0',
              'expenseChangePercent': '-4.5',
              'savingsChangePercent': '+20.0',
            },
          },
          'accounts': {
            'items': [
              {
                'id': 1,
                'displayName': 'Savings Vault',
                'type': 'bank',
                'subtype': 'savings',
                'currencyCode': 'INR',
                'currentBalance': '50000.00',
                'isDefault': true,
                'status': 'active',
              },
            ],
          },
          'spending': {
            'byCategory': [
              {
                'id': 5,
                'name': 'Groceries',
                'total': '6000.00',
                'percentage': '75.0',
              },
            ],
            'topMerchants': [
              {
                'merchant': 'BigBasket',
                'total': '4500.00',
                'count': 3,
                'percentage': '56.2',
              },
            ],
          },
          'insights': [
            {
              'type': 'highest_category',
              'message': 'Groceries was your highest expense category.',
            },
          ],
        }),
        recent: [
          const TransactionModel(
            id: 101,
            userId: 1,
            categoryId: 5,
            category: 'Groceries',
            type: 'expense',
            title: 'BigBasket Run',
            amount: 1500.0,
            transactionDate: '2026-10-05',
            source: 'manual',
          ),
        ],
      );

      final authProvider = MockAuthProvider();
      authProvider.setMockUser(
        const UserModel(id: 1, name: 'Alice Doe', email: 'alice@example.com'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: mockProvider),
            ChangeNotifierProvider<SmsProvider>.value(value: SmsProvider()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header
      expect(find.text('Hello, Alice Doe'), findsOneWidget);
      expect(find.text('FinTrack Dashboard'), findsOneWidget);

      // Section 7: Filter Chips
      expect(find.text('Current Month'), findsOneWidget);
      expect(find.text('Previous Month'), findsOneWidget);

      // Section 1: Net Worth Card
      expect(find.text('NET WORTH'), findsOneWidget);
      expect(find.text('₹35,000.00'), findsOneWidget); // Net worth
      expect(find.text('₹50,000.00'), findsNWidgets(2)); // Total Assets + Savings Vault account
      expect(find.text('₹15,000.00'), findsOneWidget); // Total Liabilities

      // Section 2: Cash Flow
      expect(find.text('Monthly Cash Flow'), findsOneWidget);
      expect(find.text('₹25,000.00'), findsOneWidget); // Income
      expect(find.text('₹8,000.00'), findsOneWidget); // Expenses
      expect(find.text('68.0%'), findsOneWidget); // Savings rate

      // Section 5: Accounts
      expect(find.text('Account Balances'), findsOneWidget);
      expect(find.text('Savings Vault'), findsOneWidget);

      // Section 3: Spending by category
      expect(find.text('Spending by Category'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.textContaining('Groceries was your highest expense category.'), findsOneWidget);
      expect(find.textContaining('Groceries • Oct 05, 2026'), findsOneWidget);
      expect(find.text('75.0% of expenses'), findsOneWidget);

      // Section 6: Recent Transactions
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('BigBasket Run'), findsOneWidget);
      expect(find.text('-₹1500.00'), findsOneWidget);
    });

    testWidgets('renders empty state when no transactions exist', (tester) async {
      final mockProvider = MockDashboardProvider();
      mockProvider.setMockData(
        summary: DashboardSummary.fromJson({
          'overview': {
            'totalAssets': '0.00',
            'totalLiabilities': '0.00',
            'netWorth': '0.00',
            'monthlyIncome': '0.00',
            'monthlyExpenses': '0.00',
            'monthlyNetSavings': '0.00',
          },
          'accounts': {'items': []},
          'spending': {'byCategory': [], 'topMerchants': []},
        }),
      );

      final authProvider = MockAuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: mockProvider),
            ChangeNotifierProvider<SmsProvider>.value(value: SmsProvider()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No accounts linked yet.'), findsOneWidget);
      expect(find.text('No expenses recorded for this period.'), findsOneWidget);
      expect(find.text('No transactions recorded yet.'), findsOneWidget);
    });

    testWidgets('renders error message and retry button on fetch failure', (tester) async {
      final mockProvider = MockDashboardProvider();
      mockProvider.setMockData(
        error: 'Network connection failed',
      );

      final authProvider = MockAuthProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<DashboardProvider>.value(value: mockProvider),
            ChangeNotifierProvider<SmsProvider>.value(value: SmsProvider()),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
