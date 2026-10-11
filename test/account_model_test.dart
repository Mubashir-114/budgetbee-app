import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/screens/accounts/widgets/money_text.dart';

void main() {
  group('AccountModel JSON serialization', () {
    test('parses bank account json correctly preserving exact string amounts', () {
      final json = {
        'id': 101,
        'type': 'bank',
        'subtype': 'savings',
        'displayName': 'HDFC Salary Account',
        'institutionName': 'HDFC Bank',
        'maskedLast4': '4321',
        'currencyCode': 'INR',
        'openingAmount': '50000.75',
        'creditLimit': null,
        'isDefault': true,
        'status': 'active',
        'createdAt': '2026-10-11T10:00:00Z',
        'updatedAt': '2026-10-11T10:00:00Z',
      };

      final account = AccountModel.fromJson(json);

      expect(account.id, 101);
      expect(account.type, 'bank');
      expect(account.subtype, 'savings');
      expect(account.displayName, 'HDFC Salary Account');
      expect(account.institutionName, 'HDFC Bank');
      expect(account.maskedLast4, '4321');
      expect(account.currencyCode, 'INR');
      expect(account.openingAmount, '50000.75'); // exact string, not double
      expect(account.creditLimit, isNull);
      expect(account.isDefault, isTrue);
      expect(account.status, 'active');
      expect(account.isAsset, isTrue);
      expect(account.isActive, isTrue);
      expect(account.isArchived, isFalse);
    });

    test('parses credit card account json with credit limit', () {
      final json = {
        'id': 102,
        'type': 'credit_card',
        'subtype': 'credit_card',
        'displayName': 'Axis Neo Card',
        'institutionName': 'Axis Bank',
        'maskedLast4': '9876',
        'currencyCode': 'INR',
        'openingAmount': '15000.00',
        'creditLimit': '100000.00',
        'isDefault': false,
        'status': 'active',
      };

      final account = AccountModel.fromJson(json);

      expect(account.id, 102);
      expect(account.type, 'credit_card');
      expect(account.openingAmount, '15000.00');
      expect(account.creditLimit, '100000.00');
      expect(account.isAsset, isFalse);
      expect(account.isDefault, isFalse);
    });

    test('applies defaults for missing optional fields', () {
      final json = {
        'id': 103,
        'type': 'cash',
        'subtype': 'cash',
        'displayName': 'Wallet Cash',
      };

      final account = AccountModel.fromJson(json);

      expect(account.currencyCode, 'INR');
      expect(account.openingAmount, '0.00');
      expect(account.isDefault, isFalse);
      expect(account.status, 'active');
      expect(account.institutionName, isNull);
      expect(account.maskedLast4, isNull);
    });

    test('toJson roundtrip preserves exact values', () {
      const account = AccountModel(
        id: 104,
        type: 'wallet',
        subtype: 'stored_value',
        displayName: 'Paytm Wallet',
        institutionName: 'Paytm',
        maskedLast4: null,
        currencyCode: 'INR',
        openingAmount: '2499.50',
        creditLimit: null,
        isDefault: false,
        status: 'active',
      );

      final map = account.toJson();
      expect(map['openingAmount'], '2499.50');
      expect(map['displayName'], 'Paytm Wallet');
      expect(map['type'], 'wallet');

      final roundtrip = AccountModel.fromJson(map);
      expect(roundtrip.id, account.id);
      expect(roundtrip.openingAmount, account.openingAmount);
      expect(roundtrip.displayName, account.displayName);
    });

    test('parses AccountListResponse with pagination and summary', () {
      final json = {
        'accounts': [
          {
            'id': 1,
            'type': 'bank',
            'subtype': 'savings',
            'displayName': 'Main Savings',
            'currencyCode': 'INR',
            'openingAmount': '10000.00',
            'isDefault': true,
            'status': 'active',
          }
        ],
        'total': 1,
        'page': 1,
        'limit': 20,
        'hasMore': false,
        'summary': {
          'totalAccounts': 1,
          'activeAccounts': 1,
          'archivedAccounts': 0,
        },
      };

      final listResponse = AccountListResponse.fromJson(json);
      expect(listResponse.accounts.length, 1);
      expect(listResponse.total, 1);
      expect(listResponse.page, 1);
      expect(listResponse.limit, 20);
    });
  });

  group('Exact monetary representation & formatting', () {
    test('formats Indian number system correctly without floating point errors', () {
      expect(MoneyText.format('100000.00', 'INR'), '₹1,00,000.00');
      expect(MoneyText.format('12500.50', 'INR'), '₹12,500.50');
      expect(MoneyText.format('500.00', 'INR'), '₹500.00');
      expect(MoneyText.format('10000000.00', 'INR'), '₹1,00,00,000.00');
      expect(MoneyText.format('0.00', 'INR'), '₹0.00');
    });

    test('formats standard currency with standard grouping', () {
      expect(MoneyText.format('100000.00', 'USD'), '\$100,000.00');
      expect(MoneyText.format('1234.56', 'EUR'), '€1,234.56');
    });

    test('handles negative amounts cleanly', () {
      expect(MoneyText.format('-5000.00', 'INR'), '-₹5,000.00');
    });
  });
}
