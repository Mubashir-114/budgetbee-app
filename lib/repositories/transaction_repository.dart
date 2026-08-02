import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/transaction_model.dart';
import '../core/utils/sms_parser.dart';

class TransactionRepository {
  final Dio _dio = ApiClient.dio;

  Future<ApiResponse<TransactionResponse>> getTransactions({
    String? type,
    int? categoryId,
    String? search,
    String? from,
    String? to,
    String? sort, // "transaction_date", "amount", "created_at"
    String? order, // "asc", "desc"
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (type != null && type.isNotEmpty) queryParams['type'] = type;
    if (categoryId != null) queryParams['categoryId'] = categoryId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;
    if (sort != null && sort.isNotEmpty) queryParams['sort'] = sort;
    if (order != null && order.isNotEmpty) queryParams['order'] = order;

    final response = await _dio.get(
      "transactions",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => TransactionResponse.fromJson(json),
    );
  }

  Future<ApiResponse<TransactionModel>> getTransactionById(int id) async {
    final response = await _dio.get("transactions/$id");
    return ApiResponse.fromJson(
      response.data,
      (json) => TransactionModel.fromJson(json["transaction"]),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> addTransaction({
    required int categoryId,
    required String type,
    required String title,
    required double amount,
    required String transactionDate,
    String? note,
  }) async {
    final response = await _dio.post(
      "transactions",
      data: {
        "categoryId": categoryId,
        "type": type,
        "title": title,
        "amount": amount,
        "transactionDate": transactionDate,
        "note": note,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<TransactionModel>> editTransaction({
    required int id,
    required int categoryId,
    required String type,
    required String title,
    required double amount,
    required String transactionDate,
    String? note,
  }) async {
    final response = await _dio.put(
      "transactions/$id",
      data: {
        "categoryId": categoryId,
        "type": type,
        "title": title,
        "amount": amount,
        "transactionDate": transactionDate,
        "note": note,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => TransactionModel.fromJson(json["transaction"]),
    );
  }

  Future<ApiResponse<void>> removeTransaction(int id) async {
    final response = await _dio.delete("transactions/$id");
    return ApiResponse.fromJson(
      response.data,
      (_) {},
    );
  }

  Future<ApiResponse<SmsImportResponse>> importSmsTransactions(
    List<ParsedSmsTransaction> transactions,
  ) async {
    final response = await _dio.post(
      "transactions/import-sms",
      data: transactions.map((t) => t.toJson()).toList(),
    );

    final json = response.data as Map<String, dynamic>;
    return ApiResponse<SmsImportResponse>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: SmsImportResponse.fromJson(json),
    );
  }

  Future<ApiResponse<List<String>>> getImportedSmsHashes() async {
    final response = await _dio.get("transactions/imported-hashes");
    final json = response.data as Map<String, dynamic>;
    final List<dynamic> data = json["data"] ?? [];
    return ApiResponse<List<String>>(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      data: data.map((item) => item.toString()).toList(),
    );
  }
}

class SmsImportResponse {
  final int imported;
  final int duplicates;
  final int failed;

  SmsImportResponse({
    required this.imported,
    required this.duplicates,
    required this.failed,
  });

  factory SmsImportResponse.fromJson(Map<String, dynamic> json) {
    return SmsImportResponse(
      imported: json["imported"] ?? 0,
      duplicates: json["duplicates"] ?? 0,
      failed: json["failed"] ?? 0,
    );
  }
}
