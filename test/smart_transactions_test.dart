import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/sms_service.dart';
import 'package:frontend/core/utils/sms_parser.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/detected_transaction_model.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/providers/currency_provider.dart';
import 'package:frontend/providers/dashboard_provider.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/providers/transaction_provider.dart';
import 'package:frontend/repositories/account_repository.dart';
import 'package:frontend/repositories/smart_transaction_repository.dart';
import 'package:frontend/repositories/transaction_repository.dart';
import 'package:frontend/screens/transactions/sms_import_screen.dart';

class _FakeSmartTransactionRepository extends Fake implements SmartTransactionRepository {
  List<DetectedTransactionModel> mockTransactions = [];
  bool detectCalled = false;
  bool confirmCalled = false;
  bool rejectCalled = false;
  bool updateCalled = false;
  bool batchConfirmCalled = false;
  bool batchRejectCalled = false;

  @override
  Future<ApiResponse<List<DetectedTransactionModel>>> getDetectedTransactions({
    String status = "suggested",
    String? classification,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    return ApiResponse(
      success: true,
      message: "Fetched",
      data: mockTransactions,
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> confirmTransaction(
    int id, {
    Map<String, dynamic>? overrides,
  }) async {
    confirmCalled = true;
    return const ApiResponse(
      success: true,
      message: "Confirmed",
      data: {"status": "confirmed"},
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> rejectTransaction(
    int id, {
    String? reason,
  }) async {
    rejectCalled = true;
    return const ApiResponse(
      success: true,
      message: "Rejected",
      data: {"status": "rejected"},
    );
  }

  @override
  Future<ApiResponse<DetectedTransactionModel>> updateDetectedTransaction(
    int id,
    Map<String, dynamic> changes,
  ) async {
    updateCalled = true;
    final item = mockTransactions.firstWhere((t) => t.id == id);
    final updated = item.copyWith(
      merchantClean: changes["merchantClean"] as String?,
      classification: changes["classification"] as String?,
      accountId: changes["accountId"] as int?,
      categoryId: changes["categoryId"] as int?,
    );
    return ApiResponse(
      success: true,
      message: "Updated",
      data: updated,
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> batchConfirm(
    List<Map<String, dynamic>> items,
  ) async {
    batchConfirmCalled = true;
    return const ApiResponse(
      success: true,
      message: "Batch confirmed",
      data: {},
    );
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> batchReject(
    List<int> ids, {
    String? reason,
  }) async {
    batchRejectCalled = true;
    return const ApiResponse(
      success: true,
      message: "Batch rejected",
      data: {},
    );
  }
}

class _FakeSmsService extends SmsService {
  @override
  Future<PermissionStatus> getPermissionStatus() async => PermissionStatus.granted;

  @override
  Future<PermissionStatus> requestPermission() async => PermissionStatus.granted;

  @override
  Future<List<ParsedSmsTransaction>> readAndParseSms() async => [];
}

class _FakeAccountRepository extends Fake implements AccountRepository {}
class _FakeTransactionRepository extends Fake implements TransactionRepository {
  @override
  Future<ApiResponse<List<String>>> getImportedSmsHashes() async {
    return const ApiResponse(success: true, message: "", data: []);
  }
}

void main() {
  group('Phase 3B: DetectedTransactionModel Tests', () {
    test('parses JSON with camelCase and snake_case keys correctly', () {
      final json = {
        'id': 101,
        'user_id': 42,
        'account_id': 5,
        'account_name': 'HDFC Savings',
        'category_id': 2,
        'category_name': 'Food',
        'classification': 'expense',
        'amount': '450.00',
        'transaction_date': '2026-10-11',
        'merchant_raw': 'SWIGGY BANGALORE IN',
        'merchant_clean': 'Swiggy',
        'bank': 'HDFC',
        'sender': 'HDFCBK',
        'reference_number': '123456789012',
        'masked_account_hint': '1234',
        'sms_hash': 'hash_test_123',
        'confidence': 0.95,
        'confidence_reason': 'Merchant recognized: Swiggy',
        'suggested_account_id': 5,
        'suggested_account_name': 'HDFC Savings',
        'suggested_category_id': 2,
        'suggested_category_name': 'Food',
        'is_account_ambiguous': false,
        'status': 'suggested',
      };

      final model = DetectedTransactionModel.fromJson(json);

      expect(model.id, 101);
      expect(model.userId, 42);
      expect(model.accountId, 5);
      expect(model.accountName, 'HDFC Savings');
      expect(model.amount, '450.00');
      expect(model.merchantClean, 'Swiggy');
      expect(model.confidence, 0.95);
      expect(model.isAccountAmbiguous, false);
      expect(model.status, 'suggested');
    });

    test('handles ambiguous account flags and missing hints gracefully', () {
      final json = {
        'id': 102,
        'user_id': 42,
        'classification': 'credit_card_purchase',
        'amount': '1299.00',
        'transaction_date': '2026-10-11',
        'merchant_raw': 'AMAZON INDIA',
        'merchant_clean': 'Amazon',
        'sms_hash': 'hash_test_456',
        'confidence': 0.65,
        'is_account_ambiguous': true,
        'status': 'suggested',
      };

      final model = DetectedTransactionModel.fromJson(json);

      expect(model.id, 102);
      expect(model.accountId, isNull);
      expect(model.isAccountAmbiguous, isTrue);
      expect(model.confidence, 0.65);
    });

    test('copyWith updates specified fields cleanly', () {
      final base = DetectedTransactionModel(
        id: 1,
        userId: 42,
        classification: 'expense',
        amount: '100.00',
        transactionDate: '2026-10-11',
        merchantRaw: 'UBER TRIP',
        merchantClean: 'Uber',
        smsHash: 'hash1',
        confidence: 0.9,
        isAccountAmbiguous: false,
        status: 'suggested',
      );

      final updated = base.copyWith(
        merchantClean: 'Uber Technologies',
        classification: 'transfer',
      );

      expect(updated.id, 1);
      expect(updated.merchantClean, 'Uber Technologies');
      expect(updated.classification, 'transfer');
      expect(updated.amount, '100.00');
    });
  });

  group('Phase 3B: SmsProvider Smart Transactions Workflow', () {
    test('loadDetectedTransactions populates list and auto-selects all items', () async {
      final fakeSmartRepo = _FakeSmartTransactionRepository();
      fakeSmartRepo.mockTransactions = [
        DetectedTransactionModel(
          id: 1,
          userId: 42,
          classification: 'expense',
          amount: '450.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'SWIGGY',
          merchantClean: 'Swiggy',
          smsHash: 'hash1',
          confidence: 0.95,
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
        DetectedTransactionModel(
          id: 2,
          userId: 42,
          classification: 'expense',
          amount: '120.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'UBER',
          merchantClean: 'Uber',
          smsHash: 'hash2',
          confidence: 0.90,
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
      ];

      final provider = SmsProvider(
        smartRepo: fakeSmartRepo,
        repository: _FakeTransactionRepository(),
      );

      await provider.loadDetectedTransactions(status: 'suggested');

      expect(provider.detectedCount, 2);
      expect(provider.selectedDetectedCount, 2);
      expect(provider.isAllDetectedSelected, isTrue);
      expect(provider.selectedDetectedIds.contains(1), isTrue);
      expect(provider.selectedDetectedIds.contains(2), isTrue);
    });

    test('toggleDetectedSelection toggles individual selection', () async {
      final fakeSmartRepo = _FakeSmartTransactionRepository();
      fakeSmartRepo.mockTransactions = [
        DetectedTransactionModel(
          id: 1,
          userId: 42,
          classification: 'expense',
          amount: '450.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'SWIGGY',
          merchantClean: 'Swiggy',
          smsHash: 'hash1',
          confidence: 0.95,
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
      ];

      final provider = SmsProvider(smartRepo: fakeSmartRepo);
      await provider.loadDetectedTransactions();

      expect(provider.selectedDetectedCount, 1);

      provider.toggleDetectedSelection(1);
      expect(provider.selectedDetectedCount, 0);

      provider.toggleDetectedSelection(1);
      expect(provider.selectedDetectedCount, 1);
    });

    test('confirmDetected removes item from detected list and clears selection', () async {
      final fakeSmartRepo = _FakeSmartTransactionRepository();
      fakeSmartRepo.mockTransactions = [
        DetectedTransactionModel(
          id: 1,
          userId: 42,
          classification: 'expense',
          amount: '450.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'SWIGGY',
          merchantClean: 'Swiggy',
          smsHash: 'hash1',
          confidence: 0.95,
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
      ];

      final provider = SmsProvider(smartRepo: fakeSmartRepo);
      await provider.loadDetectedTransactions();

      final ok = await provider.confirmDetected(1);
      expect(ok, isTrue);
      expect(fakeSmartRepo.confirmCalled, isTrue);
      expect(provider.detectedCount, 0);
      expect(provider.selectedDetectedIds.contains(1), isFalse);
    });

    test('rejectDetected removes item from detected list', () async {
      final fakeSmartRepo = _FakeSmartTransactionRepository();
      fakeSmartRepo.mockTransactions = [
        DetectedTransactionModel(
          id: 1,
          userId: 42,
          classification: 'expense',
          amount: '450.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'SWIGGY',
          merchantClean: 'Swiggy',
          smsHash: 'hash1',
          confidence: 0.95,
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
      ];

      final provider = SmsProvider(smartRepo: fakeSmartRepo);
      await provider.loadDetectedTransactions();

      final ok = await provider.rejectDetected(1, reason: "Duplicate");
      expect(ok, isTrue);
      expect(fakeSmartRepo.rejectCalled, isTrue);
      expect(provider.detectedCount, 0);
    });

    test('batchConfirmSelected confirms all selected items', () async {
      final fakeSmartRepo = _FakeSmartTransactionRepository();
      fakeSmartRepo.mockTransactions = [
        DetectedTransactionModel(
          id: 1,
          userId: 42,
          classification: 'expense',
          amount: '450.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'SWIGGY',
          merchantClean: 'Swiggy',
          smsHash: 'hash1',
          confidence: 0.95,
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
        DetectedTransactionModel(
          id: 2,
          userId: 42,
          classification: 'expense',
          amount: '120.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'UBER',
          merchantClean: 'Uber',
          smsHash: 'hash2',
          confidence: 0.90,
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
      ];

      final provider = SmsProvider(smartRepo: fakeSmartRepo);
      await provider.loadDetectedTransactions();

      final ok = await provider.batchConfirmSelected();
      expect(ok, isTrue);
      expect(fakeSmartRepo.batchConfirmCalled, isTrue);
      expect(provider.detectedCount, 0);
    });
  });

  group('Phase 3B: SmsImportScreen Widget Tests', () {
    testWidgets('renders privacy explanation banner and smart transaction cards', (tester) async {
      final fakeSmartRepo = _FakeSmartTransactionRepository();
      fakeSmartRepo.mockTransactions = [
        DetectedTransactionModel(
          id: 10,
          userId: 42,
          accountId: 5,
          accountName: 'HDFC Savings',
          categoryId: 1,
          categoryName: 'Food',
          classification: 'expense',
          amount: '450.00',
          transactionDate: '2026-10-11',
          merchantRaw: 'SWIGGY BANGALORE IN',
          merchantClean: 'Swiggy',
          bank: 'HDFC',
          sender: 'HDFCBK',
          smsHash: 'hash123',
          confidence: 0.95,
          confidenceReason: 'Merchant recognized: Swiggy',
          isAccountAmbiguous: false,
          status: 'suggested',
        ),
      ];

      SharedPreferences.setMockInitialValues({});
      final smsProvider = SmsProvider(
        smartRepo: fakeSmartRepo,
        smsService: _FakeSmsService(),
        repository: _FakeTransactionRepository(),
      );
      await smsProvider.loadDetectedTransactions();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SmsProvider>.value(value: smsProvider),
            ChangeNotifierProvider<AccountProvider>(create: (_) => AccountProvider(repository: _FakeAccountRepository())),
            ChangeNotifierProvider<CurrencyProvider>(create: (_) => CurrencyProvider()),
            ChangeNotifierProvider<TransactionProvider>(create: (_) => TransactionProvider()),
            ChangeNotifierProvider<DashboardProvider>(create: (_) => DashboardProvider()),
          ],
          child: const MaterialApp(
            home: SmsImportScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Smart Review Tab exists
      expect(find.text("Smart Review"), findsOneWidget);

      // Verify Privacy Banner exists
      expect(find.text("Privacy & Financial Safety"), findsOneWidget);

      // Verify clean merchant name and amount are rendered
      expect(find.text("Swiggy"), findsOneWidget);
      expect(find.textContaining("450.00"), findsOneWidget);

      // Verify action buttons are rendered
      expect(find.text("Confirm"), findsWidgets);
      expect(find.text("Edit"), findsOneWidget);
      expect(find.text("Reject"), findsWidgets);
    });
  });
}
