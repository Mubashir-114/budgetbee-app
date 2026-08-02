import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/report_models.dart';

class ReportRepository {
  final Dio _dio = ApiClient.dio;

  Future<ApiResponse<ReportSummary>> getSummary({
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final response = await _dio.get(
      "reports/summary",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => ReportSummary.fromJson(json),
    );
  }

  Future<ApiResponse<List<MonthlyReport>>> getMonthly({
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final response = await _dio.get(
      "reports/monthly",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => MonthlyReport.fromJson(item)).toList();
      },
    );
  }

  Future<ApiResponse<List<CategoryReport>>> getCategory({
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final response = await _dio.get(
      "reports/category",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => CategoryReport.fromJson(item)).toList();
      },
    );
  }

  Future<ApiResponse<List<TrendsReport>>> getTrends({
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final response = await _dio.get(
      "reports/trends",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => TrendsReport.fromJson(item)).toList();
      },
    );
  }

  Future<ApiResponse<List<CashflowReport>>> getCashflow({
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{};
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final response = await _dio.get(
      "reports/cashflow",
      queryParameters: queryParams,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List;
        return list.map((item) => CashflowReport.fromJson(item)).toList();
      },
    );
  }

  Future<String> exportReportCsv({
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{'format': 'csv'};
    if (from != null && from.isNotEmpty) queryParams['from'] = from;
    if (to != null && to.isNotEmpty) queryParams['to'] = to;

    final response = await _dio.get<String>(
      "reports/export",
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.plain),
    );

    return response.data ?? '';
  }
}
