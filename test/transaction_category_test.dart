import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/category_model.dart';
import 'package:frontend/models/transaction_model.dart';
import 'package:frontend/core/utils/category_utils.dart';
import 'package:frontend/core/utils/decimal_money.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/screens/transactions/transactions_list_screen.dart';

void main() {
  group('Category Integrity & Database Synchronization', () {
    test('Category IDs match real MySQL database categories', () {
      // 1. Income categories
      final incomeCategories = CategoryModel.getIncomeCategories();
      expect(incomeCategories.length, 2);
      expect(incomeCategories.map((c) => c.name), containsAll(['Salary', 'Other Income']));
      expect(incomeCategories.firstWhere((c) => c.name == 'Salary').id, 1);
      expect(incomeCategories.firstWhere((c) => c.name == 'Other Income').id, 2);

      // 2. Expense categories
      final expenseCategories = CategoryModel.getExpenseCategories();
      expect(expenseCategories.length, 10);
      expect(
        expenseCategories.map((c) => c.name),
        containsAll([
          'Food',
          'Transport',
          'Housing',
          'Utilities',
          'Healthcare',
          'Entertainment',
          'Shopping',
          'Education',
          'Travel',
          'Other Expense',
        ]),
      );

      // 3. Mandatory regression check: Food is ID 3, Healthcare is ID 7
      final foodCat = expenseCategories.firstWhere((c) => c.name == 'Food');
      expect(foodCat.id, 3, reason: 'Food must be categoryId: 3 in MySQL, never 7');
      expect(foodCat.type, 'expense');

      final healthcareCat = expenseCategories.firstWhere((c) => c.name == 'Healthcare');
      expect(healthcareCat.id, 7, reason: 'Healthcare must be categoryId: 7 in MySQL');
      expect(healthcareCat.type, 'expense');

      // 4. Name lookup by ID
      expect(CategoryModel.getNameById(3), 'Food');
      expect(CategoryModel.getNameById(7), 'Healthcare');
      expect(CategoryModel.getNameById(1), 'Salary');
      expect(CategoryModel.getNameById(2), 'Other Income');

      // 5. Lookup helper methods
      expect(CategoryModel.findById(3)?.name, 'Food');
      expect(CategoryModel.findById(7)?.name, 'Healthcare');
      expect(CategoryModel.findByName('food', type: 'expense')?.id, 3);
      expect(CategoryModel.findByName('healthcare', type: 'expense')?.id, 7);
    });

    test('Category icons and semantic colors resolve accurately', () {
      expect(getCategoryIcon('Food'), Icons.restaurant_rounded);
      expect(getCategoryIcon('Healthcare'), Icons.local_hospital_rounded);
      expect(getCategoryIcon('Salary'), Icons.payments_rounded);
      expect(getCategoryIcon('Utilities'), Icons.bolt_rounded);
      expect(getCategoryIcon('Housing'), Icons.home_rounded);

      // Colors should be valid and distinct
      expect(getCategoryColor('Food'), isNotNull);
      expect(getCategoryColor('Healthcare'), isNotNull);
      expect(getCategoryColor('Food'), isNot(equals(getCategoryColor('Healthcare'))));
    });

    test('Mandhi Food transaction serializes and deserializes consistently', () {
      final json = {
        "id": 42,
        "user_id": 1,
        "category_id": 3, // Real Food ID
        "type": "expense",
        "title": "Mandhi",
        "amount": "450.00",
        "transaction_date": "2026-10-12",
        "note": "Dinner with family",
        "category": "Food", // Joined category name from MySQL
        "created_at": "2026-10-12T19:30:00Z",
        "source": "manual",
        "account_id": 1,
        "account_name": "Primary HDFC",
      };

      final tx = TransactionModel.fromJson(json);

      expect(tx.id, 42);
      expect(tx.title, 'Mandhi');
      expect(tx.categoryId, 3, reason: 'Persisted categoryId must be 3 for Food');
      expect(tx.category, 'Food');
      expect(tx.type, 'expense');
      expect(tx.amount, 450.0);
      expect(tx.accountId, 1);
      expect(tx.accountName, 'Primary HDFC');

      final serialized = tx.toJson();
      expect(serialized['category_id'], 3);
      expect(serialized['category'], 'Food');
      expect(serialized['account_id'], 1);
    });

    test('DecimalMoney validates exact financial inputs without float error', () {
      expect(DecimalMoney.isValidDecimal('450.00'), isTrue);
      expect(DecimalMoney.isValidDecimal('120'), isTrue);
      expect(DecimalMoney.isValidDecimal('0.50'), isTrue);
      expect(DecimalMoney.isValidDecimal('abc'), isFalse);
      expect(DecimalMoney.isValidDecimal('-50.00'), isTrue);

      final minor = DecimalMoney.parseToMinor('450.50');
      expect(minor, BigInt.from(45050));
      expect(DecimalMoney.formatMinor(minor), '450.50');
    });

    test('formatFriendlyDate produces clean readable relative dates', () {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      expect(formatFriendlyDate(todayStr), 'Today');

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().split('T')[0];
      expect(formatFriendlyDate(yesterdayStr), 'Yesterday');
    });
  });

  group('AddEditTransactionSheet UI & Form Behavior', () {
    Widget createSheetWidget({
      TransactionModel? transaction,
      bool disableAnimations = false,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
          ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ChangeNotifierProvider(create: (_) => AccountProvider()),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Scaffold(
              body: AddEditTransactionSheet(transaction: transaction),
            ),
          ),
        ),
      );
    }

    testWidgets('Renders Add Transaction sheet with Expense defaults and Food selected', (tester) async {
      await tester.pumpWidget(createSheetWidget());
      await tester.pumpAndSettle();

      // Title & Action
      expect(find.text('New Transaction'), findsOneWidget);
      expect(find.text('ADD TRANSACTION'), findsOneWidget);

      // Mode indicator
      expect(find.text('Expense'), findsWidgets);
      expect(find.text('Income'), findsWidgets);
      expect(find.text('Outflow'), findsOneWidget);

      // Default selected expense category is Food (id: 3)
      expect(find.text('Food'), findsWidgets);
      expect(find.byKey(const ValueKey('cat_chip_3')), findsOneWidget);

      // Healthcare is also available in Expense mode
      expect(find.byKey(const ValueKey('cat_chip_7')), findsOneWidget);
    });

    testWidgets('Switching transaction type updates available categories dynamically', (tester) async {
      await tester.pumpWidget(createSheetWidget());
      await tester.pumpAndSettle();

      // Initially in Expense mode: Food (3) is present, Salary (1) is not in expense wrap
      expect(find.byKey(const ValueKey('cat_chip_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_1')), findsNothing);

      // Tap 'Income' tab
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // In Income mode: Inflow indicator active, Salary (1) is present, Food (3) is not
      expect(find.text('Inflow'), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_3')), findsNothing);

      // Tap back to 'Expense' tab
      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();

      expect(find.text('Outflow'), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_3')), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_1')), findsNothing);
    });

    testWidgets('Editing existing transaction preserves category and identity', (tester) async {
      final existingTx = TransactionModel(
        id: 99,
        userId: 1,
        categoryId: 3, // Food
        type: 'expense',
        title: 'Mandhi Feast',
        amount: 850.00,
        transactionDate: '2026-10-12',
        note: 'Arabic restaurant',
        category: 'Food',
        source: 'manual',
      );

      await tester.pumpWidget(createSheetWidget(transaction: existingTx));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
      expect(find.text('SAVE CHANGES'), findsOneWidget);
      expect(find.text('Mandhi Feast'), findsOneWidget);
      expect(find.text('850.00'), findsOneWidget);
      expect(find.text('Arabic restaurant'), findsOneWidget);

      // Category Food (3) must be the active selected category
      expect(find.byKey(const ValueKey('cat_chip_3')), findsOneWidget);
    });

    testWidgets('Reduced motion settings render without animations gracefully', (tester) async {
      await tester.pumpWidget(createSheetWidget(disableAnimations: true));
      await tester.pumpAndSettle();

      expect(find.text('New Transaction'), findsOneWidget);
      expect(find.byKey(const ValueKey('cat_chip_3')), findsOneWidget);

      // Switch to Income under reduced motion
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('cat_chip_1')), findsOneWidget);
    });
  });
}
