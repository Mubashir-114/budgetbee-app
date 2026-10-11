import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  final Dio _dio = ApiClient.dio;

  Future<ApiResponse<List<BudgetModel>>> getBudgets({
    int? month,
    int? year,
    int? categoryId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    if (categoryId != null) queryParams['categoryId'] = categoryId;

    final response = await _dio.get(
      "budgets",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json["budgets"] as List;
        return list.map((item) => BudgetModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<List<BudgetStatusModel>>> getBudgetStatus({
    required int month,
    required int year,
  }) async {
    final response = await _dio.get(
      "budgets/status",
      queryParameters: {
        'month': month,
        'year': year,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json["budgets"] as List;
        return list.map((item) => BudgetStatusModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<BudgetProgressResponseModel>> getBudgetProgress({
    required int month,
    required int year,
    double? savingsTarget,
  }) async {
    final queryParams = <String, dynamic>{
      'month': month,
      'year': year,
    };
    if (savingsTarget != null && savingsTarget > 0) {
      queryParams['savingsTarget'] = savingsTarget;
    }

    final response = await _dio.get(
      "budgets/progress",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => BudgetProgressResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<BudgetAlertsResponseModel>> getBudgetAlerts({
    required int month,
    required int year,
  }) async {
    final response = await _dio.get(
      "budgets/alerts",
      queryParameters: {
        'month': month,
        'year': year,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => BudgetAlertsResponseModel.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<List<BudgetSuggestionModel>>> getBudgetSuggestions({
    int? month,
    int? year,
    double? savingsTarget,
  }) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    if (savingsTarget != null && savingsTarget > 0) {
      queryParams['savingsTarget'] = savingsTarget;
    }

    final response = await _dio.get(
      "budgets/suggestions",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json["suggestions"] as List? ?? [];
        return list.map((item) => BudgetSuggestionModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<List<BudgetHistoryItemModel>>> getBudgetHistory({
    int months = 6,
  }) async {
    final response = await _dio.get(
      "budgets/history",
      queryParameters: {
        'months': months,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json["history"] as List? ?? [];
        return list.map((item) => BudgetHistoryItemModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  Future<ApiResponse<BudgetModel>> addBudget({
    required int categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final response = await _dio.post(
      "budgets",
      data: {
        "categoryId": categoryId,
        "amount": amount,
        "month": month,
        "year": year,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => BudgetModel.fromJson(json["budget"] as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<BudgetModel>> editBudget({
    required int id,
    required int categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final response = await _dio.put(
      "budgets/$id",
      data: {
        "categoryId": categoryId,
        "amount": amount,
        "month": month,
        "year": year,
      },
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => BudgetModel.fromJson(json["budget"] as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> removeBudget(int id) async {
    final response = await _dio.delete("budgets/$id");
    return ApiResponse.fromJson(
      response.data,
      (_) {},
    );
  }
}
