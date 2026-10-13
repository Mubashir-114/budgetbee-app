import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/goal_model.dart';

class GoalRepository {
  final Dio _dio;

  GoalRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  /// Retrieves list of savings goals for authenticated user
  Future<ApiResponse<List<GoalModel>>> getGoals({String? status}) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }

    final response = await _dio.get("goals", queryParameters: queryParams);
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = json as List<dynamic>;
        return list.map((item) => GoalModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  /// Retrieves goal details and intelligence by ID
  Future<ApiResponse<GoalModel>> getGoalById(int goalId) async {
    final response = await _dio.get("goals/$goalId");
    return ApiResponse.fromJson(
      response.data,
      (json) => GoalModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Retrieves aggregated savings goals summary metrics
  Future<ApiResponse<GoalsSummaryModel>> getGoalsSummary() async {
    final response = await _dio.get("goals/summary");
    return ApiResponse.fromJson(
      response.data,
      (json) => GoalsSummaryModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Creates a new savings goal
  Future<ApiResponse<GoalModel>> createGoal(Map<String, dynamic> data) async {
    final response = await _dio.post("goals", data: data);
    return ApiResponse.fromJson(
      response.data,
      (json) => GoalModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Updates an existing goal
  Future<ApiResponse<GoalModel>> updateGoal(int goalId, Map<String, dynamic> data) async {
    final response = await _dio.put("goals/$goalId", data: data);
    return ApiResponse.fromJson(
      response.data,
      (json) => GoalModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Deletes a goal and its contributions
  Future<ApiResponse<void>> deleteGoal(int goalId) async {
    final response = await _dio.delete("goals/$goalId");
    return ApiResponse.fromJson(
      response.data,
      (_) {},
    );
  }

  /// Records a contribution progress allocation
  Future<ApiResponse<Map<String, dynamic>>> addContribution(int goalId, Map<String, dynamic> data) async {
    final response = await _dio.post("goals/$goalId/contributions", data: data);
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final map = json as Map<String, dynamic>;
        return {
          'contribution': GoalContributionModel.fromJson(map['contribution'] as Map<String, dynamic>),
          'goal': GoalModel.fromJson(map['goal'] as Map<String, dynamic>),
        };
      },
    );
  }

  /// Retrieves paginated contributions for a goal
  Future<ApiResponse<List<GoalContributionModel>>> getContributions(int goalId, {int page = 1, int limit = 50}) async {
    final response = await _dio.get(
      "goals/$goalId/contributions",
      queryParameters: {'page': page, 'limit': limit},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final list = (json as Map<String, dynamic>)['contributions'] as List<dynamic>;
        return list.map((item) => GoalContributionModel.fromJson(item as Map<String, dynamic>)).toList();
      },
    );
  }

  /// Corrects/updates a contribution
  Future<ApiResponse<Map<String, dynamic>>> updateContribution(
    int goalId,
    int contributionId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put("goals/$goalId/contributions/$contributionId", data: data);
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final map = json as Map<String, dynamic>;
        return {
          'contribution': GoalContributionModel.fromJson(map['contribution'] as Map<String, dynamic>),
          'goal': GoalModel.fromJson(map['goal'] as Map<String, dynamic>),
        };
      },
    );
  }

  /// Deletes a contribution record
  Future<ApiResponse<GoalModel>> deleteContribution(int goalId, int contributionId) async {
    final response = await _dio.delete("goals/$goalId/contributions/$contributionId");
    return ApiResponse.fromJson(
      response.data,
      (json) {
        final map = json as Map<String, dynamic>;
        return GoalModel.fromJson(map['goal'] as Map<String, dynamic>);
      },
    );
  }

  /// Generates cash-flow forecast across selected horizon
  Future<ApiResponse<CashFlowForecastModel>> getCashFlowForecast({String horizon = 'next_3_months'}) async {
    final response = await _dio.get(
      "goals/forecast",
      queryParameters: {'horizon': horizon},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => CashFlowForecastModel.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Executes what-if scenario simulation
  Future<ApiResponse<WhatIfSimulationModel>> runSimulation(Map<String, dynamic> scenario) async {
    final response = await _dio.post("goals/simulate", data: scenario);
    return ApiResponse.fromJson(
      response.data,
      (json) => WhatIfSimulationModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
