import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/dashboard_models.dart';
import '../models/transaction_model.dart';

class DashboardRepository {
  final Dio _dio = ApiClient.dio;

  Future<ApiResponse<DashboardSummary>> getSummary() async {
    final response = await _dio.get("dashboard");
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

  Future<ApiResponse<List<CategorySummary>>> getCategorySummary() async {
    final response = await _dio.get("dashboard/categories");
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => CategorySummary.fromJson(item)).toList();
      },
    );
  }

  Future<ApiResponse<List<TransactionModel>>> getRecentTransactions() async {
    final response = await _dio.get("dashboard/recent");
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => TransactionModel.fromJson(item)).toList();
      },
    );
  }
}
