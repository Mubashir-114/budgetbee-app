import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/account_model.dart';
import '../models/api_response.dart';

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
}
