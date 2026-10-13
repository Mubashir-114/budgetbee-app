import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/analytics_model.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Fetches allowlisted capabilities, supported questions, and privacy notice.
  Future<ApiResponse<AnalyticsCapability>> getCapabilities() async {
    final response = await _dio.get("analytics/capabilities");
    return ApiResponse.fromJson(
      response.data,
      (json) => AnalyticsCapability.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Sends a natural-language question or structured intent for local deterministic calculation.
  Future<ApiResponse<AnalyticsQueryResult>> queryAnalytics({
    String? question,
    String? intent,
    String? period,
    String? startDate,
    String? endDate,
    String? month,
  }) async {
    final Map<String, dynamic> body = {};
    if (question != null && question.trim().isNotEmpty) {
      body['question'] = question.trim();
    }
    if (intent != null && intent.isNotEmpty) {
      body['intent'] = intent;
    }
    if (period != null && period.isNotEmpty) {
      body['period'] = period;
    }
    if (startDate != null && startDate.isNotEmpty) {
      body['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      body['endDate'] = endDate;
    }
    if (month != null && month.isNotEmpty) {
      body['month'] = month;
    }

    final response = await _dio.post(
      "analytics/query",
      data: body,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => AnalyticsQueryResult.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Fetches deterministic financial insights for the requested period.
  Future<ApiResponse<Map<String, dynamic>>> getInsights({
    String? period,
    String? month,
    String? startDate,
    String? endDate,
  }) async {
    final Map<String, dynamic> query = {};
    if (period != null && period.isNotEmpty) query['period'] = period;
    if (month != null && month.isNotEmpty) query['month'] = month;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;

    final response = await _dio.get(
      "analytics/insights",
      queryParameters: query.isNotEmpty ? query : null,
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => json as Map<String, dynamic>,
    );
  }
}
