import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/account_balance_model.dart';
import 'package:frontend/models/account_activity_model.dart';
import 'package:frontend/models/account_adjustment_model.dart';
import 'package:frontend/models/transfer_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/repositories/account_repository.dart';
import 'package:frontend/screens/transfers/transfer_screen.dart';

class MockAccountRepository extends Fake implements AccountRepository {
  List<AccountModel> mockAccounts = [];
  AccountBalanceModel? mockBalance;
  AccountActivityListResponse? mockActivity;
  TransferModel? mockTransfer;
  AccountAdjustmentModel? mockAdjustment;

  @override
  Future<ApiResponse<AccountListResponse>> getAccounts({
    String? status,
    String? type,
    int page = 1,
    int limit = 20,
    dynamic cancelToken,
  }) async {
    return ApiResponse(
      success: true,
      message: 'Success',
      data: AccountListResponse(
        accounts: mockAccounts,
        total: mockAccounts.length,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<ApiResponse<AccountBalanceModel>> getAccountBalance(
    int id, {
    dynamic cancelToken,
  }) async {
    return ApiResponse(
      success: true,
      message: 'Success',
      data: mockBalance ??
          AccountBalanceModel(
            accountId: id,
            displayName: 'Savings',
            type: 'bank',
            subtype: 'savings',
            currencyCode: 'INR',
            openingAmount: '1000.00',
            currentBalance: '1500.00',
            totalIncome: '500.00',
            totalExpense: '0.00',
            transfersIn: '0.00',
            transfersOut: '0.00',
            totalAdjustments: '0.00',
          ),
    );
  }

  @override
  Future<ApiResponse<AccountActivityListResponse>> getAccountActivity(
    int id, {
    int page = 1,
    int limit = 20,
    dynamic cancelToken,
  }) async {
    return ApiResponse(
      success: true,
      message: 'Success',
      data: mockActivity ??
          AccountActivityListResponse(
            activities: [],
            total: 0,
            page: page,
            limit: limit,
          ),
    );
  }

  @override
  Future<ApiResponse<TransferModel>> createTransfer({
    required int sourceAccountId,
    required int destinationAccountId,
    required String amount,
    required String transferDate,
    String? note,
    required String clientTransferKey,
  }) async {
    return ApiResponse(
      success: true,
      message: 'Transfer completed',
      data: TransferModel(
        id: 99,
        sourceAccountId: sourceAccountId,
        destinationAccountId: destinationAccountId,
        amount: amount,
        currencyCode: 'INR',
        transferDate: transferDate,
        note: note,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<ApiResponse<AccountAdjustmentModel>> createAdjustment(
    int id, {
    required String amount,
    required String reason,
    required String adjustmentDate,
    required String clientAdjustmentKey,
  }) async {
    return ApiResponse(
      success: true,
      message: 'Adjustment recorded',
      data: AccountAdjustmentModel(
        id: 55,
        accountId: id,
        amount: amount,
        reason: reason,
        adjustmentDate: adjustmentDate,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CacheService.setUserId(10);
    await CacheService.initialize();
  });

  group('Phase 3A.3 - Ledger & Transfer Models', () {
    test('TransferModel parses and preserves exact string amounts', () {
      final json = {
        'id': 1,
        'sourceAccountId': 10,
        'destinationAccountId': 20,
        'amount': '1500.50',
        'currencyCode': 'INR',
        'transferDate': '2026-10-11',
        'note': 'Rent split',
        'sourceAccountName': 'Checking',
        'destinationAccountName': 'Savings',
        'createdAt': '2026-10-11T12:00:00Z',
      };

      final transfer = TransferModel.fromJson(json);

      expect(transfer.id, 1);
      expect(transfer.sourceAccountId, 10);
      expect(transfer.destinationAccountId, 20);
      expect(transfer.amount, '1500.50');
      expect(transfer.currencyCode, 'INR');
      expect(transfer.note, 'Rent split');
      expect(transfer.sourceAccountName, 'Checking');
      expect(transfer.destinationAccountName, 'Savings');
    });

    test('AccountBalanceModel parses ledger balances and available credit', () {
      final json = {
        'accountId': 42,
        'displayName': 'Axis Credit Card',
        'type': 'credit_card',
        'subtype': 'credit_card',
        'currencyCode': 'INR',
        'openingAmount': '5000.00',
        'currentBalance': '12500.00',
        'totalIncome': '0.00',
        'totalExpense': '7500.00',
        'transfersIn': '0.00',
        'transfersOut': '0.00',
        'totalAdjustments': '0.00',
        'creditLimit': '50000.00',
        'availableCredit': '37500.00',
      };

      final balance = AccountBalanceModel.fromJson(json);

      expect(balance.accountId, 42);
      expect(balance.isCreditCard, isTrue);
      expect(balance.currentBalance, '12500.00');
      expect(balance.creditLimit, '50000.00');
      expect(balance.availableCredit, '37500.00');
      expect(balance.totalExpense, '7500.00');
    });

    test('AccountActivityModel handles diverse entry types and inflows/outflows', () {
      final item1 = AccountActivityModel.fromJson({
        'id': 'tx_1',
        'activityType': 'transaction',
        'type': 'income',
        'title': 'Salary deposit',
        'amount': '75000.00',
        'date': '2026-10-01',
      });
      expect(item1.isIncomeOrInflow, isTrue);

      final item2 = AccountActivityModel.fromJson({
        'id': 'tr_1',
        'activityType': 'transfer',
        'type': 'transfer_out',
        'title': 'Transfer to Savings',
        'amount': '20000.00',
        'date': '2026-10-02',
      });
      expect(item2.isIncomeOrInflow, isFalse);

      final item3 = AccountActivityModel.fromJson({
        'id': 'adj_1',
        'activityType': 'adjustment',
        'type': 'adjustment_credit',
        'title': 'Adjustment: Correction',
        'amount': '150.00',
        'date': '2026-10-03',
      });
      expect(item3.isIncomeOrInflow, isTrue);
    });

    test('AccountAdjustmentModel parses auditable adjustment record', () {
      final json = {
        'id': 7,
        'accountId': 10,
        'amount': '-25.00',
        'reason': 'Bank maintenance fee',
        'adjustmentDate': '2026-10-10',
      };

      final adj = AccountAdjustmentModel.fromJson(json);
      expect(adj.id, 7);
      expect(adj.accountId, 10);
      expect(adj.amount, '-25.00');
      expect(adj.reason, 'Bank maintenance fee');
      expect(adj.isPositive, isFalse);
    });
  });

  group('Phase 3A.3 - AccountProvider Ledger Operations', () {
    late MockAccountRepository mockRepo;
    late AccountProvider provider;

    setUp(() {
      mockRepo = MockAccountRepository();
      provider = AccountProvider(repository: mockRepo);
    });

    test('getAccountBalance delegates to repository successfully', () async {
      final bal = await provider.getAccountBalance(10);
      expect(bal, isNotNull);
      expect(bal!.currentBalance, '1500.00');
    });

    test('createTransfer calls repository and succeeds', () async {
      final ok = await provider.createTransfer(
        sourceAccountId: 1,
        destinationAccountId: 2,
        amount: '250.00',
        transferDate: '2026-10-11',
        clientTransferKey: 'test-key-1',
      );
      expect(ok, isTrue);
      expect(provider.actionStatus, AccountActionStatus.success);
    });

    test('createAdjustment calls repository and succeeds', () async {
      final ok = await provider.createAdjustment(
        1,
        amount: '50.00',
        reason: 'Reconciliation',
        adjustmentDate: '2026-10-11',
        clientAdjustmentKey: 'adj-test-1',
      );
      expect(ok, isTrue);
      expect(provider.actionStatus, AccountActionStatus.success);
    });
  });

  group('Phase 3A.3 - TransferScreen UI Validation', () {
    testWidgets('TransferScreen shows form elements and validates fields',
        (tester) async {
      final mockRepo = MockAccountRepository();
      mockRepo.mockAccounts = [
        const AccountModel(
          id: 1,
          type: 'bank',
          subtype: 'savings',
          displayName: 'HDFC Savings',
          currencyCode: 'INR',
          openingAmount: '1000.00',
          isDefault: true,
          status: 'active',
        ),
        const AccountModel(
          id: 2,
          type: 'wallet',
          subtype: 'stored_value',
          displayName: 'Paytm Wallet',
          currencyCode: 'INR',
          openingAmount: '500.00',
          isDefault: false,
          status: 'active',
        ),
      ];

      final provider = AccountProvider(repository: mockRepo);
      await provider.loadAccounts();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AccountProvider>.value(
            value: provider,
            child: const TransferScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transfer Funds'), findsNWidgets(2));
      expect(find.text('From Account'), findsOneWidget);
      expect(find.text('To Account'), findsOneWidget);
      expect(find.text('Amount (INR)'), findsOneWidget);

      // Attempt to submit without filling fields
      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Expect validation error
      expect(find.text('Please enter amount'), findsOneWidget);
    });
  });
}
