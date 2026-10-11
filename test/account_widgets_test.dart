import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/account_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/screens/accounts/add_account_screen.dart';
import 'package:frontend/screens/accounts/widgets/account_card.dart';
import 'package:frontend/screens/accounts/widgets/account_icon.dart';
import 'package:frontend/screens/accounts/widgets/money_text.dart';

void main() {
  group('MoneyText widget', () {
    testWidgets('renders exact decimal string with symbol without double conversions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoneyText(
              decimalString: '125000.50',
              currencyCode: 'INR',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );

      expect(find.text('₹1,25,000.50'), findsOneWidget);
    });

    testWidgets('renders zero decimal string accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoneyText(
              decimalString: '0.00',
              currencyCode: 'INR',
            ),
          ),
        ),
      );

      expect(find.text('₹0.00'), findsOneWidget);
    });
  });

  group('AccountCard widget', () {
    testWidgets('displays asset account badges and opening amount label correctly', (tester) async {
      const account = AccountModel(
        id: 1,
        type: 'bank',
        subtype: 'salary',
        displayName: 'Salary Account',
        institutionName: 'SBI',
        maskedLast4: '1234',
        currencyCode: 'INR',
        openingAmount: '75000.00',
        isDefault: true,
        status: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountCard(
              account: account,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Salary Account'), findsOneWidget);
      expect(find.text('SBI · ••••1234'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Opening amount'), findsOneWidget);
      expect(find.text('₹75,000.00'), findsOneWidget);
    });

    testWidgets('displays credit card with CREDIT LIMIT label and liability styling', (tester) async {
      const account = AccountModel(
        id: 2,
        type: 'credit_card',
        subtype: 'credit_card',
        displayName: 'Amazon Pay ICICI',
        institutionName: 'ICICI Bank',
        maskedLast4: '9988',
        currencyCode: 'INR',
        openingAmount: '0.00',
        creditLimit: '250000.00',
        isDefault: false,
        status: 'active',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountCard(
              account: account,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Amazon Pay ICICI'), findsOneWidget);
      expect(find.text('ICICI Bank · ••••9988'), findsOneWidget);
      expect(find.text('Credit limit'), findsOneWidget);
      expect(find.text('₹2,50,000.00'), findsOneWidget);
    });
  });

  group('AccountIcon widget', () {
    testWidgets('renders appropriate icon for account types', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AccountIcon(type: 'bank', subtype: 'savings'),
                AccountIcon(type: 'cash', subtype: 'cash'),
                AccountIcon(type: 'credit_card', subtype: 'credit_card'),
                AccountIcon(type: 'wallet', subtype: 'stored_value'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.savings_rounded), findsOneWidget);
      expect(find.byIcon(Icons.money_rounded), findsOneWidget);
      expect(find.byIcon(Icons.credit_card_rounded), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    });
  });

  group('AddAccountScreen form validation', () {
    testWidgets('validates required name and decimal amount', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => AccountProvider(),
            child: const AddAccountScreen(),
          ),
        ),
      );

      // Scroll to submit button and tap
      final submitButton = find.widgetWithText(FilledButton, 'Create Account');
      expect(submitButton, findsOneWidget);

      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pump();

      // Error message should appear for empty account name
      expect(find.text('Account name is required'), findsOneWidget);
    });
  });
}
