import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/detected_transaction_model.dart';

class SmartTransactionRepository {
  final Dio _dio;

  SmartTransactionRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Detects and parses transactions from an array of SMS messages.
  Future<ApiResponse<Map<String, dynamic>>> detectTransactions(
    List<Map<String, dynamic>> messages,
  ) async {
    final response = await _dio.post(
      "smart-transactions/detect",
      data: {"messages": messages},
    );

    final json = response.data as Map<String, dynamic>;
    return ApiResponse<Map<String, dynamic>>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] as Map<String, dynamic>? ?? {},
    );
  }

  /// Lists detected transactions for current user.
  Future<ApiResponse<List<DetectedTransactionModel>>> getDetectedTransactions({
    String status = "suggested",
    String? classification,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      "status": status,
      "page": page,
      "limit": limit,
    };
    if (classification != null && classification.isNotEmpty) {
      queryParams["classification"] = classification;
    }
    if (search != null && search.isNotEmpty) {
      queryParams["search"] = search;
    }

    final response = await _dio.get(
      "smart-transactions",
      queryParameters: queryParams,
    );

    final json = response.data as Map<String, dynamic>;
    final dataObj = json["data"] as Map<String, dynamic>? ?? {};
    final list = (dataObj["detectedTransactions"] as List<dynamic>?) ?? [];

    final transactions = list
        .map((item) => DetectedTransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return ApiResponse<List<DetectedTransactionModel>>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: transactions,
    );
  }

  /// Gets a single detected transaction by ID.
  Future<ApiResponse<DetectedTransactionModel>> getDetectedTransactionById(int id) async {
    final response = await _dio.get("smart-transactions/$id");
    final json = response.data as Map<String, dynamic>;
    final dataObj = json["data"] as Map<String, dynamic>? ?? {};
    final txJson = dataObj["transaction"] as Map<String, dynamic>? ?? {};

    return ApiResponse<DetectedTransactionModel>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: DetectedTransactionModel.fromJson(txJson),
    );
  }

  /// Updates a detected transaction with manual user corrections.
  Future<ApiResponse<DetectedTransactionModel>> updateDetectedTransaction(
    int id,
    Map<String, dynamic> changes,
  ) async {
    final response = await _dio.put(
      "smart-transactions/$id",
      data: changes,
    );

    final json = response.data as Map<String, dynamic>;
    final dataObj = json["data"] as Map<String, dynamic>? ?? {};
    final txJson = dataObj["transaction"] as Map<String, dynamic>? ?? {};

    return ApiResponse<DetectedTransactionModel>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: DetectedTransactionModel.fromJson(txJson),
    );
  }

  /// Confirms a detected transaction and commits to ledger.
  Future<ApiResponse<Map<String, dynamic>>> confirmTransaction(
    int id, {
    Map<String, dynamic>? overrides,
  }) async {
    final response = await _dio.post(
      "smart-transactions/$id/confirm",
      data: overrides ?? {},
    );

    final json = response.data as Map<String, dynamic>;
    return ApiResponse<Map<String, dynamic>>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] as Map<String, dynamic>? ?? {},
    );
  }

  /// Rejects a detected transaction so it never enters the ledger.
  Future<ApiResponse<Map<String, dynamic>>> rejectTransaction(
    int id, {
    String? reason,
  }) async {
    final response = await _dio.post(
      "smart-transactions/$id/reject",
      data: {"reason": reason ?? "User rejected"},
    );

    final json = response.data as Map<String, dynamic>;
    return ApiResponse<Map<String, dynamic>>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] as Map<String, dynamic>? ?? {},
    );
  }

  /// Batch confirms multiple detected transactions.
  Future<ApiResponse<Map<String, dynamic>>> batchConfirm(
    List<Map<String, dynamic>> items,
  ) async {
    final response = await _dio.post(
      "smart-transactions/batch/confirm",
      data: {"items": items},
    );

    final json = response.data as Map<String, dynamic>;
    return ApiResponse<Map<String, dynamic>>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] as Map<String, dynamic>? ?? {},
    );
  }

  /// Batch rejects multiple detected transactions.
  Future<ApiResponse<Map<String, dynamic>>> batchReject(
    List<int> ids, {
    String? reason,
  }) async {
    final response = await _dio.post(
      "smart-transactions/batch/reject",
      data: {
        "ids": ids,
        "reason": reason ?? "Batch user rejection",
      },
    );

    final json = response.data as Map<String, dynamic>;
    return ApiResponse<Map<String, dynamic>>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: json["data"] as Map<String, dynamic>? ?? {},
    );
  }
}
