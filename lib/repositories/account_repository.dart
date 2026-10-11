import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/account_activity_model.dart';
import '../models/account_adjustment_model.dart';
import '../models/account_balance_model.dart';
import '../models/account_model.dart';
import '../models/api_response.dart';
import '../models/credit_card_models.dart';
import '../models/transfer_model.dart';

/// Repository for all `/api/accounts` operations.
///
/// Uses the shared [ApiClient.dio] instance which already carries the
/// authentication interceptor and retry logic.  All money values sent to the
/// server are exact decimal strings — never doubles.
class AccountRepository {
  final Dio _dio = ApiClient.dio;

  // ── List ──────────────────────────────────────────────────────────────────

  Future<ApiResponse<AccountListResponse>> getAccounts({
    String? type,
    String? status,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;

    final response = await _dio.get(
      'accounts',
      queryParameters: params,
      cancelToken: cancelToken,
    );

    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountListResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  // ── Single ────────────────────────────────────────────────────────────────

  Future<ApiResponse<AccountModel>> getAccount(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      'accounts/$id',
      cancelToken: cancelToken,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountModel.fromJson(
        (data as Map<String, dynamic>)['account'] as Map<String, dynamic>,
      ),
    );
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<ApiResponse<AccountModel>> createAccount({
    required String type,
    required String subtype,
    required String displayName,
    String? institutionName,
    String? maskedLast4,
    String currencyCode = 'INR',
    /// Exact decimal string, e.g. "1000.00"
    String openingAmount = '0.00',
    /// Required for credit_card; null otherwise.
    String? creditLimit,
    bool isDefault = false,
    required String clientCreationKey,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'subtype': subtype,
      'displayName': displayName,
      'currencyCode': currencyCode,
      'openingAmount': openingAmount,
      'isDefault': isDefault,
      'clientCreationKey': clientCreationKey,
    };
    if (institutionName != null) body['institutionName'] = institutionName;
    if (maskedLast4 != null) body['maskedLast4'] = maskedLast4;
    if (creditLimit != null) body['creditLimit'] = creditLimit;

    final response = await _dio.post('accounts', data: body);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountModel.fromJson(
        (data as Map<String, dynamic>)['account'] as Map<String, dynamic>,
      ),
    );
  }

  // ── Update (metadata only) ────────────────────────────────────────────────

  Future<ApiResponse<AccountModel>> updateAccount(
    int id, {
    required String displayName,
    String? institutionName,
    String? maskedLast4,
  }) async {
    final body = <String, dynamic>{'displayName': displayName};
    // The backend accepts null explicitly; pass key even when null so the
    // server can clear the field.
    body['institutionName'] = institutionName;
    if (maskedLast4 != null) body['maskedLast4'] = maskedLast4;

    final response = await _dio.put('accounts/$id', data: body);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountModel.fromJson(
        (data as Map<String, dynamic>)['account'] as Map<String, dynamic>,
      ),
    );
  }

  // ── Set default ───────────────────────────────────────────────────────────

  Future<ApiResponse<AccountModel>> setDefault(int id) async {
    final response = await _dio.put('accounts/$id/default');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountModel.fromJson(
        (data as Map<String, dynamic>)['account'] as Map<String, dynamic>,
      ),
    );
  }

  // ── Archive ───────────────────────────────────────────────────────────────

  Future<ApiResponse<AccountModel>> archiveAccount(int id) async {
    final response = await _dio.put('accounts/$id/archive');
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountModel.fromJson(
        (data as Map<String, dynamic>)['account'] as Map<String, dynamic>,
      ),
    );
  }

  // ── Exact Ledger Balance ──────────────────────────────────────────────────

  Future<ApiResponse<AccountBalanceModel>> getAccountBalance(
    int id, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      'accounts/$id/balance',
      cancelToken: cancelToken,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountBalanceModel.fromJson(
        (data as Map<String, dynamic>)['balance'] as Map<String, dynamic>,
      ),
    );
  }

  // ── Account Activity Feed ─────────────────────────────────────────────────

  Future<ApiResponse<AccountActivityListResponse>> getAccountActivity(
    int id, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      'accounts/$id/activity',
      queryParameters: {'page': page, 'limit': limit},
      cancelToken: cancelToken,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountActivityListResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  // ── Balance Adjustment ───────────────────────────────────────────────────

  Future<ApiResponse<AccountAdjustmentModel>> createAdjustment(
    int id, {
    required String amount,
    required String reason,
    required String adjustmentDate,
    required String clientAdjustmentKey,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'reason': reason,
      'adjustmentDate': adjustmentDate,
      'clientAdjustmentKey': clientAdjustmentKey,
    };
    final response = await _dio.post('accounts/$id/adjustments', data: body);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountAdjustmentModel.fromJson(
        (data as Map<String, dynamic>)['adjustment'] as Map<String, dynamic>,
      ),
    );
  }

  // ── Atomic Transfers ──────────────────────────────────────────────────────

  Future<ApiResponse<TransferModel>> createTransfer({
    required int sourceAccountId,
    required int destinationAccountId,
    required String amount,
    required String transferDate,
    String? note,
    required String clientTransferKey,
  }) async {
    final body = <String, dynamic>{
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'amount': amount,
      'transferDate': transferDate,
      'clientTransferKey': clientTransferKey,
    };
    if (note != null) body['note'] = note;

    final response = await _dio.post('transfers', data: body);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => TransferModel.fromJson(
        (data as Map<String, dynamic>)['transfer'] as Map<String, dynamic>,
      ),
    );
  }

  Future<ApiResponse<TransferListResponse>> getTransfers({
    int? accountId,
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (accountId != null) params['accountId'] = accountId;

    final response = await _dio.get(
      'transfers',
      queryParameters: params,
      cancelToken: cancelToken,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => TransferListResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  // ── Credit Card Operations ────────────────────────────────────────────────

  Future<ApiResponse<CreditCardDetailsModel>> getCreditCardDetails(
    int cardId, {
    CancelToken? cancelToken,
  }) async {
    final response = await _dio.get(
      'accounts/$cardId/credit-card',
      cancelToken: cancelToken,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => CreditCardDetailsModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<AccountModel>> updateBillingSettings(
    int cardId, {
    int? statementClosingDay,
    int? paymentDueDay,
  }) async {
    final body = <String, dynamic>{
      'statementClosingDay': statementClosingDay,
      'paymentDueDay': paymentDueDay,
    };
    final response = await _dio.put('accounts/$cardId/billing', data: body);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AccountModel.fromJson(
        (data as Map<String, dynamic>)['account'] as Map<String, dynamic>,
      ),
    );
  }

  Future<ApiResponse<CreditCardRepaymentResult>> repayCreditCard(
    int cardId, {
    required int sourceAccountId,
    required String amount,
    required String paymentDate,
    String? note,
    required String clientPaymentKey,
  }) async {
    final body = <String, dynamic>{
      'sourceAccountId': sourceAccountId,
      'amount': amount,
      'paymentDate': paymentDate,
      'clientPaymentKey': clientPaymentKey,
    };
    if (note != null && note.trim().isNotEmpty) {
      body['note'] = note.trim();
    }

    final response = await _dio.post('accounts/$cardId/repay', data: body);
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => CreditCardRepaymentResult.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<CreditCardPaymentListResponse>> getCreditCardPayments(
    int cardId, {
    int page = 1,
    int limit = 20,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    final response = await _dio.get(
      'accounts/$cardId/payments',
      queryParameters: params,
      cancelToken: cancelToken,
    );
    return ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => CreditCardPaymentListResponse.fromJson(data as Map<String, dynamic>),
    );
  }
}
