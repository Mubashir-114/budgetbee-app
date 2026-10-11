import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/dashboard_models.dart';
import '../models/transaction_model.dart';

class DashboardRepository {
  final Dio _dio = ApiClient.dio;

  Future<ApiResponse<DashboardSummary>> getSummary({
    String? month,
    String? period,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, dynamic> query = {};
    if (month != null && month.isNotEmpty) query['month'] = month;
    if (period != null && period.isNotEmpty) query['period'] = period;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    final response = await _dio.get(
      "dashboard",
      queryParameters: query.isNotEmpty ? query : null,
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => DashboardSummary.fromJson(json),
    );
  }

  Future<ApiResponse<List<MonthlySummary>>> getMonthlySummary() async {
    final response = await _dio.get("dashboard/monthly");
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => MonthlySummary.fromJson(item)).toList();
      },
    );
  }

  Future<ApiResponse<List<CategorySummary>>> getCategorySummary({
    String? month,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, dynamic> query = {};
    if (month != null && month.isNotEmpty) query['month'] = month;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    final response = await _dio.get(
      "dashboard/categories",
      queryParameters: query.isNotEmpty ? query : null,
    );
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => CategorySummary.fromJson(item)).toList();
      },
    );
  }

  Future<ApiResponse<List<TransactionModel>>> getRecentTransactions({int limit = 10}) async {
    final response = await _dio.get(
      "dashboard/recent",
      queryParameters: {"limit": limit},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => TransactionModel.fromJson(item)).toList();
      },
    );
  }
}
