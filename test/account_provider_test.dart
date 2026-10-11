import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/models/account_model.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/providers/account_provider.dart';
import 'package:frontend/repositories/account_repository.dart';

class _FakeAccountRepository extends AccountRepository {
  List<AccountModel> accountsList = [];
  int getAccountsCallCount = 0;
  Completer<ApiResponse<AccountListResponse>>? hangGetAccounts;
  bool shouldFailGet = false;
  String? failMessage;

  @override
  Future<ApiResponse<AccountListResponse>> getAccounts({
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    getAccountsCallCount++;
    if (hangGetAccounts != null) {
      return hangGetAccounts!.future;
    }
    if (shouldFailGet) {
      throw DioException(
        requestOptions: RequestOptions(path: 'accounts'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: 'accounts'),
          statusCode: 500,
          data: {'success': false, 'message': failMessage ?? 'Server error'},
        ),
      );
    }
    return ApiResponse(
      success: true,
      data: AccountListResponse(
        accounts: accountsList,
        total: accountsList.length,
        page: page,
        limit: limit,
      ),
      message: 'OK',
    );
  }

  @override
  Future<ApiResponse<AccountModel>> createAccount({
    required String type,
    required String subtype,
    required String displayName,
    String? institutionName,
    String? maskedLast4,
    String currencyCode = 'INR',
    String openingAmount = '0.00',
    String? creditLimit,
    bool isDefault = false,
    required String clientCreationKey,
  }) async {
    final newAccount = AccountModel(
      id: accountsList.length + 1,
      type: type,
      subtype: subtype,
      displayName: displayName,
      institutionName: institutionName,
      maskedLast4: maskedLast4,
      currencyCode: currencyCode,
      openingAmount: openingAmount,
      creditLimit: creditLimit,
      isDefault: isDefault,
      status: 'active',
    );
    if (isDefault) {
      accountsList = accountsList.map((a) => a.copyWith(isDefault: false)).toList();
    }
    accountsList.add(newAccount);
    return ApiResponse(success: true, data: newAccount, message: 'Created');
  }

  @override
  Future<ApiResponse<AccountModel>> updateAccount(
    int id, {
    required String displayName,
    String? institutionName,
    String? maskedLast4,
  }) async {
    final idx = accountsList.indexWhere((a) => a.id == id);
    if (idx == -1) {
      throw DioException(
        requestOptions: RequestOptions(path: 'accounts/$id'),
        response: Response(
          requestOptions: RequestOptions(path: 'accounts/$id'),
          statusCode: 404,
          data: {'success': false, 'message': 'Account not found'},
        ),
      );
    }
    final updated = accountsList[idx].copyWith(
      displayName: displayName,
      institutionName: institutionName,
      maskedLast4: maskedLast4,
    );
    accountsList[idx] = updated;
    return ApiResponse(success: true, data: updated, message: 'Updated');
  }

  @override
  Future<ApiResponse<AccountModel>> setDefault(int id) async {
    final idx = accountsList.indexWhere((a) => a.id == id);
    if (idx == -1) {
      throw Exception('Not found');
    }
    if (accountsList[idx].type == 'credit_card') {
      throw DioException(
        requestOptions: RequestOptions(path: 'accounts/$id/default'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: 'accounts/$id/default'),
          statusCode: 400,
          data: {
            'success': false,
            'message': 'Credit card accounts cannot be set as default'
          },
        ),
      );
    }
    accountsList = accountsList.map((a) {
      if (a.id == id) return a.copyWith(isDefault: true);
      return a.copyWith(isDefault: false);
    }).toList();
    return ApiResponse(
      success: true,
      data: accountsList.firstWhere((a) => a.id == id),
      message: 'Default set',
    );
  }

  @override
  Future<ApiResponse<AccountModel>> archiveAccount(int id) async {
    final idx = accountsList.indexWhere((a) => a.id == id);
    final archived = accountsList[idx].copyWith(status: 'archived', isDefault: false);
    accountsList.removeAt(idx);
    return ApiResponse(success: true, data: archived, message: 'Archived');
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CacheService.setUserId(10);
    await CacheService.initialize();
  });

  group('AccountProvider', () {
    test('loads accounts and populates state and cache', () async {
      final fakeRepo = _FakeAccountRepository();
      fakeRepo.accountsList = [
        const AccountModel(
          id: 1,
          type: 'bank',
          subtype: 'savings',
          displayName: 'Savings',
          currencyCode: 'INR',
          openingAmount: '5000.00',
          isDefault: true,
          status: 'active',
        ),
      ];

      final provider = AccountProvider(repository: fakeRepo);
      expect(provider.isLoading, isFalse);
      expect(provider.accounts, isEmpty);

      await provider.loadAccounts();

      expect(provider.isLoading, isFalse);
      expect(provider.accounts.length, 1);
      expect(provider.accounts.first.displayName, 'Savings');
      expect(provider.defaultAccount?.id, 1);

      // Verify cache was populated for user 10
      final cached = await CacheService.get('accounts_active_page1');
      expect(cached, isNotNull);
      expect((cached['accounts'] as List).length, 1);
    });

    test('isolates cache per authenticated user', () async {
      final fakeRepo = _FakeAccountRepository();
      fakeRepo.accountsList = [
        const AccountModel(
          id: 1,
          type: 'cash',
          subtype: 'cash',
          displayName: 'Wallet Cash',
          currencyCode: 'INR',
          openingAmount: '100.00',
          isDefault: false,
          status: 'active',
        ),
      ];

      final provider = AccountProvider(repository: fakeRepo);
      await provider.loadAccounts();

      // User 10 has cached accounts
      expect(await CacheService.get('accounts_active_page1'), isNotNull);

      // Switch to User 20
      CacheService.setUserId(20);
      expect(await CacheService.get('accounts_active_page1'), isNull);
    });

    test('session reset clears all data and prevents stale async results', () async {
      final fakeRepo = _FakeAccountRepository();
      fakeRepo.hangGetAccounts = Completer<ApiResponse<AccountListResponse>>();

      final provider = AccountProvider(repository: fakeRepo);
      // Fire request that hangs
      final future = provider.loadAccounts();

      // Logout / reset session in between
      provider.clearSession();

      expect(provider.accounts, isEmpty);
      expect(provider.isLoading, isFalse);

      // Complete the in-flight request now
      fakeRepo.hangGetAccounts!.complete(
        ApiResponse(
          success: true,
          data: AccountListResponse(
            accounts: [
              const AccountModel(
                id: 99,
                type: 'bank',
                subtype: 'savings',
                displayName: 'Stale Account',
                currencyCode: 'INR',
                openingAmount: '0.00',
                isDefault: false,
                status: 'active',
              ),
            ],
            total: 1,
            page: 1,
            limit: 20,
          ),
          message: 'OK',
        ),
      );

      await future;

      // Stale response must NOT populate the cleared provider
      expect(provider.accounts, isEmpty);
    });

    test('setDefault promotes target and updates defaultAccount getter', () async {
      final fakeRepo = _FakeAccountRepository();
      fakeRepo.accountsList = [
        const AccountModel(
          id: 1,
          type: 'bank',
          subtype: 'savings',
          displayName: 'Bank 1',
          currencyCode: 'INR',
          openingAmount: '1000.00',
          isDefault: true,
          status: 'active',
        ),
        const AccountModel(
          id: 2,
          type: 'bank',
          subtype: 'current',
          displayName: 'Bank 2',
          currencyCode: 'INR',
          openingAmount: '2000.00',
          isDefault: false,
          status: 'active',
        ),
      ];

      final provider = AccountProvider(repository: fakeRepo);
      await provider.loadAccounts();
      expect(provider.defaultAccount?.id, 1);

      final success = await provider.setDefault(2);
      expect(success, isTrue);
      expect(provider.defaultAccount?.id, 2);
    });

    test('rejects setting credit card as default', () async {
      final fakeRepo = _FakeAccountRepository();
      fakeRepo.accountsList = [
        const AccountModel(
          id: 5,
          type: 'credit_card',
          subtype: 'credit_card',
          displayName: 'Credit Card',
          currencyCode: 'INR',
          openingAmount: '0.00',
          creditLimit: '50000.00',
          isDefault: false,
          status: 'active',
        ),
      ];

      final provider = AccountProvider(repository: fakeRepo);
      await provider.loadAccounts();

      final success = await provider.setDefault(5);
      expect(success, isFalse);
      expect(provider.actionError, contains('Credit card accounts cannot be set as default'));
    });

    test('archiveAccount removes account from active list', () async {
      final fakeRepo = _FakeAccountRepository();
      fakeRepo.accountsList = [
        const AccountModel(
          id: 1,
          type: 'cash',
          subtype: 'cash',
          displayName: 'Cash',
          currencyCode: 'INR',
          openingAmount: '500.00',
          isDefault: false,
          status: 'active',
        ),
      ];

      final provider = AccountProvider(repository: fakeRepo);
      await provider.loadAccounts();
      expect(provider.accounts.length, 1);

      final success = await provider.archiveAccount(1);
      expect(success, isTrue);
      expect(provider.accounts, isEmpty);
    });

    test('handles API errors gracefully and records error message', () async {
      final fakeRepo = _FakeAccountRepository();
      fakeRepo.shouldFailGet = true;
      fakeRepo.failMessage = 'Network unreachable';

      final provider = AccountProvider(repository: fakeRepo);
      await provider.loadAccounts();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Network unreachable');
    });
  });
}
