import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/utils/decimal_money.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/credit_card_models.dart';
import 'package:frontend/models/transfer_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/repositories/account_repository.dart';
import 'package:frontend/screens/accounts/widgets/credit_card_components.dart';

class _FakeAccountRepository extends AccountRepository {}

void main() {
  group('DecimalMoney Exact Arithmetic (No Doubles)', () {
    test('converts exact decimal strings to minor units and back without IEEE-754 error', () {
      expect(DecimalMoney.parseToMinor('0.00'), BigInt.zero);
      expect(DecimalMoney.parseToMinor('100.50'), BigInt.from(10050));
      expect(DecimalMoney.parseToMinor('0.05'), BigInt.from(5));
      expect(DecimalMoney.parseToMinor('-25.75'), BigInt.from(-2575));

      // Precision test: 0.10 + 0.20 must exactly equal 0.30
      final sum = DecimalMoney.add('0.10', '0.20');
      expect(sum, '0.30');

      // Subtraction
      final diff = DecimalMoney.subtract('1000.00', '350.25');
      expect(diff, '649.75');

      // Comparison
      expect(DecimalMoney.compare('150.00', '200.00'), -1);
      expect(DecimalMoney.compare('200.00', '200.00'), 0);
      expect(DecimalMoney.compare('250.00', '200.00'), 1);

      // Boundaries (large BigInt values)
      final largeVal = '9007199254740991.99';
      expect(DecimalMoney.formatMinor(DecimalMoney.parseToMinor(largeVal)), largeVal);
    });

    test('validates decimal currency formats strictly', () {
      expect(DecimalMoney.isValidDecimal('100'), isTrue);
      expect(DecimalMoney.isValidDecimal('100.5'), isTrue);
      expect(DecimalMoney.isValidDecimal('100.50'), isTrue);
      expect(DecimalMoney.isValidDecimal('-50.25'), isTrue);
      expect(DecimalMoney.isValidDecimal('100.555'), isFalse); // >2 decimals
      expect(DecimalMoney.isValidDecimal('abc'), isFalse);
      expect(DecimalMoney.isValidDecimal(''), isFalse);
    });
  });

  group('Credit Card Models Serialization', () {
    test('CreditCardBillingModel parses dates, status, and estimation flag', () {
      final json = {
        'statementClosingDay': 15,
        'paymentDueDay': 5,
        'closingDate': '2026-10-15',
        'dueDate': '2026-11-05',
        'daysUntilDue': 25,
        'isDue': false,
        'isOverdue': false,
        'status': 'current',
        'isEstimated': true,
      };

      final billing = CreditCardBillingModel.fromJson(json);
      expect(billing.statementClosingDay, 15);
      expect(billing.paymentDueDay, 5);
      expect(billing.closingDate, '2026-10-15');
      expect(billing.dueDate, '2026-11-05');
      expect(billing.daysUntilDue, 25);
      expect(billing.isDue, isFalse);
      expect(billing.isOverdue, isFalse);
      expect(billing.status, 'current');
      expect(billing.isEstimated, isTrue);

      final out = billing.toJson();
      expect(out['status'], 'current');
      expect(out['isEstimated'], isTrue);
    });

    test('CreditCardDetailsModel parses exact string financial amounts', () {
      final json = {
        'accountId': 10,
        'displayName': 'Platinum Rewards Card',
        'institutionName': 'HDFC Bank',
        'maskedLast4': '4321',
        'currencyCode': 'INR',
        'creditLimit': '200000.00',
        'outstandingDebt': '14520.50',
        'availableCredit': '185479.50',
        'creditBalance': '0.00',
        'utilizationPercentage': '7.26%',
        'statementClosingDay': 15,
        'paymentDueDay': 5,
        'status': 'active',
        'billingInfo': {
          'statementClosingDay': 15,
          'paymentDueDay': 5,
          'closingDate': '2026-10-15',
          'dueDate': '2026-11-05',
          'daysUntilDue': 25,
          'isDue': false,
          'isOverdue': false,
          'status': 'current',
          'isEstimated': true,
        },
      };

      final card = CreditCardDetailsModel.fromJson(json);
      expect(card.accountId, 10);
      expect(card.displayName, 'Platinum Rewards Card');
      expect(card.institutionName, 'HDFC Bank');
      expect(card.maskedLast4, '4321');
      expect(card.creditLimit, '200000.00');
      expect(card.outstandingDebt, '14520.50');
      expect(card.availableCredit, '185479.50');
      expect(card.utilizationPercentage, '7.26%');
      expect(card.billingInfo.isEstimated, isTrue);
    });

    test('CreditCardRepaymentResult deserializes atomic repayment result', () {
      final json = {
        'payment': {
          'id': 101,
          'userId': 1,
          'sourceAccountId': 2,
          'destinationAccountId': 10,
          'amount': '5000.00',
          'currencyCode': 'INR',
          'transferDate': '2026-10-11',
          'note': 'Bill Payment',
          'clientTransferKey': 'repay-key-1',
          'sourceAccountName': 'Salary Account',
          'destinationAccountName': 'Platinum Rewards Card',
        },
        'created': true,
        'sourceBalance': '45000.00',
        'cardDebt': '9520.50',
        'availableCredit': '190479.50',
      };

      final result = CreditCardRepaymentResult.fromJson(json);
      expect(result.created, isTrue);
      expect(result.sourceBalance, '45000.00');
      expect(result.cardDebt, '9520.50');
      expect(result.availableCredit, '190479.50');
      expect(result.payment.amount, '5000.00');
    });

    test('AccountModel includes statementClosingDay and paymentDueDay', () {
      final account = AccountModel(
        id: 15,
        type: 'credit_card',
        subtype: 'credit_card',
        displayName: 'Amazon Pay ICICI',
        currencyCode: 'INR',
        openingAmount: '0.00',
        creditLimit: '150000.00',
        statementClosingDay: 20,
        paymentDueDay: 10,
        isDefault: false,
        status: 'active',
      );

      final json = account.toJson();
      expect(json['statementClosingDay'], 20);
      expect(json['paymentDueDay'], 10);

      final parsed = AccountModel.fromJson(json);
      expect(parsed.statementClosingDay, 20);
      expect(parsed.paymentDueDay, 10);
    });
  });

  group('Credit Card UI Components (Widgets)', () {
    testWidgets('CreditCardSummaryCard renders outstanding debt and utilization', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreditCardSummaryCard(
              outstandingDebt: '12500.00',
              creditLimit: '50000.00',
              availableCredit: '37500.00',
              creditBalance: '0.00',
              utilizationPercentage: '25.00%',
              currencyCode: 'INR',
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Credit Card Status'), findsOneWidget);
      expect(find.text('Current Outstanding Debt'), findsOneWidget);
      expect(find.textContaining('12,500.00'), findsOneWidget);
      expect(find.text('25.00% Utilized'), findsOneWidget);
      expect(find.text('INR 50000.00'), findsOneWidget);
      expect(find.text('INR 37500.00'), findsOneWidget);
    });

    testWidgets('CreditCardBillingCard renders estimated cycle dates and disclaimer', (tester) async {
      bool editTapped = false;
      const billing = CreditCardBillingModel(
        statementClosingDay: 15,
        paymentDueDay: 5,
        closingDate: '2026-10-15',
        dueDate: '2026-11-05',
        daysUntilDue: 25,
        status: 'current',
        isEstimated: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreditCardBillingCard(
              billing: billing,
              onEditBilling: () => editTapped = true,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Billing & Due Dates'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('2026-10-15'), findsOneWidget);
      expect(find.text('2026-11-05'), findsOneWidget);
      expect(find.text('Payment due in 25 days.'), findsOneWidget);
      expect(find.textContaining('Dates are estimated from your configured cycle days'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      expect(editTapped, isTrue);
    });

    testWidgets('CreditCardRepaymentHistoryCard renders repayment history items', (tester) async {
      final payments = [
        const TransferModel(
          id: 1,
          sourceAccountId: 2,
          destinationAccountId: 10,
          amount: '2500.00',
          currencyCode: 'INR',
          transferDate: '2026-10-08',
          note: 'Partial Repayment',
          sourceAccountName: 'HDFC Savings',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreditCardRepaymentHistoryCard(
              payments: payments,
              currencyCode: 'INR',
              isLoading: false,
              isDark: false,
            ),
          ),
        ),
      );

      expect(find.text('Repayment History'), findsOneWidget);
      expect(find.text('Paid from HDFC Savings'), findsOneWidget);
      expect(find.text('2026-10-08'), findsOneWidget);
      expect(find.text('Partial Repayment'), findsOneWidget);
      expect(find.textContaining('2,500.00'), findsOneWidget);
    });

    testWidgets('CreditCardBillingDialog validates day boundaries (1-31)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CreditCardBillingDialog(
              cardId: 10,
              currentClosingDay: 15,
              currentDueDay: 5,
            ),
          ),
        ),
      );

      expect(find.text('Edit Billing Settings'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Enter invalid day 35
      await tester.enterText(find.widgetWithText(TextFormField, '15'), '35');
      await tester.tap(find.text('Save Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Must be between 1 and 31'), findsOneWidget);
    });
  });

  group('Session Isolation in AccountProvider', () {
    test('clearSession clears accounts, error states and action status', () {
      final provider = AccountProvider(repository: _FakeAccountRepository());
      provider.clearSession();
      expect(provider.accounts, isEmpty);
      expect(provider.actionStatus, AccountActionStatus.idle);
      expect(provider.actionError, isNull);
    });
  });
}
