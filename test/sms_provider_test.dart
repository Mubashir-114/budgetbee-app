import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/sms_service.dart';
import 'package:frontend/core/utils/sms_parser.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/sms_provider.dart';
import 'package:frontend/repositories/transaction_repository.dart';

class _FakeSmsService extends SmsService {
  _FakeSmsService(this.transactions);

  final List<ParsedSmsTransaction> transactions;
  int readCount = 0;

  @override
  Future<PermissionStatus> getPermissionStatus() async =>
      PermissionStatus.granted;

  @override
  Future<List<ParsedSmsTransaction>> readAndParseSms() async {
    readCount++;
    return transactions;
  }
}

class _FakeTransactionRepository extends TransactionRepository {
  _FakeTransactionRepository({
    required this.hashResponse,
    required this.importResponse,
  });

  final ApiResponse<List<String>> hashResponse;
  final ApiResponse<SmsImportResponse> importResponse;
  int importCount = 0;

  @override
  Future<ApiResponse<List<String>>> getImportedSmsHashes() async =>
      hashResponse;

  @override
  Future<ApiResponse<SmsImportResponse>> importSmsTransactions(
    List<ParsedSmsTransaction> transactions,
  ) async {
    importCount++;
    return importResponse;
  }
}

ParsedSmsTransaction _transaction(String hash) {
  return ParsedSmsTransaction(
    amount: 14.25,
    type: 'expense',
    merchant: 'Market',
    bank: 'Test Bank',
    date: DateTime(2026, 10, 8),
    smsHash: hash,
    messageBody: 'Test transaction message',
    sender: 'BANK',
    category: 'Shopping',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'keeps selected SMS transactions visible after partial import failure',
    () async {
      final smsService = _FakeSmsService([_transaction('hash-1')]);
      final repository = _FakeTransactionRepository(
        hashResponse: const ApiResponse(
          success: true,
          message: '',
          data: <String>[],
        ),
        importResponse: ApiResponse(
          success: true,
          message: 'Some transactions failed',
          data: SmsImportResponse(imported: 0, duplicates: 0, failed: 1),
        ),
      );
      final provider = SmsProvider(
        smsService: smsService,
        repository: repository,
      );

      await provider.scanSms();
      expect(provider.selectedCount, 1);

      expect(await provider.importSelectedTransactions(), isTrue);
      expect(repository.importCount, 1);
      expect(provider.transactions, hasLength(1));
      expect(provider.archivedTransactions, isEmpty);
      expect(provider.selectedCount, 1);
    },
  );

  test(
    'does not treat a failed duplicate lookup as an empty imported set',
    () async {
      final smsService = _FakeSmsService([_transaction('hash-1')]);
      final provider = SmsProvider(
        smsService: smsService,
        repository: _FakeTransactionRepository(
          hashResponse: const ApiResponse(
            success: false,
            message: 'Hash lookup failed',
            data: <String>[],
          ),
          importResponse: ApiResponse(
            success: true,
            message: '',
            data: SmsImportResponse(imported: 1, duplicates: 0, failed: 0),
          ),
        ),
      );

      await provider.scanSms();

      expect(provider.errorMessage, 'Hash lookup failed');
      expect(provider.transactions, isEmpty);
      expect(smsService.readCount, 0);
    },
  );

  test(
    'archives selected transactions only when the whole import has no failures',
    () async {
      final smsService = _FakeSmsService([_transaction('hash-1')]);
      final provider = SmsProvider(
        smsService: smsService,
        repository: _FakeTransactionRepository(
          hashResponse: const ApiResponse(
            success: true,
            message: '',
            data: <String>[],
          ),
          importResponse: ApiResponse(
            success: true,
            message: '',
            data: SmsImportResponse(imported: 1, duplicates: 0, failed: 0),
          ),
        ),
      );

      await provider.scanSms();
      expect(await provider.importSelectedTransactions(), isTrue);

      expect(provider.transactions, isEmpty);
      expect(provider.archivedTransactions, hasLength(1));
      expect(provider.selectedCount, 0);
    },
  );
}
