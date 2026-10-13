import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/services/cache_service.dart';
import '../models/goal_model.dart';
import '../repositories/goal_repository.dart';

class GoalProvider extends ChangeNotifier {
  final GoalRepository _repository;

  GoalProvider({GoalRepository? repository})
      : _repository = repository ?? GoalRepository();

  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isForecastLoading = false;
  bool _isSimulating = false;
  String? _errorMessage;

  List<GoalModel> _goals = [];
  GoalModel? _selectedGoal;
  GoalsSummaryModel? _summary;
  CashFlowForecastModel? _forecast;
  WhatIfSimulationModel? _simulation;

  String _selectedStatusFilter = 'all'; // all, active, completed, archived
  String _selectedHorizon = 'next_3_months';

  int _sessionGeneration = 0;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isForecastLoading => _isForecastLoading;
  bool get isSimulating => _isSimulating;
  String? get errorMessage => _errorMessage;

  List<GoalModel> get goals => _goals;
  GoalModel? get selectedGoal => _selectedGoal;
  GoalsSummaryModel? get summary => _summary;
  CashFlowForecastModel? get forecast => _forecast;
  WhatIfSimulationModel? get simulation => _simulation;

  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedHorizon => _selectedHorizon;

  List<GoalModel> get filteredGoals {
    if (_selectedStatusFilter == 'all') {
      return _goals;
    }
    return _goals.where((g) => g.status == _selectedStatusFilter).toList();
  }

  void clearSession() {
    _sessionGeneration++;
    _goals = [];
    _selectedGoal = null;
    _summary = null;
    _forecast = null;
    _simulation = null;
    _errorMessage = null;
    _isLoading = false;
    _isActionLoading = false;
    _isForecastLoading = false;
    _isSimulating = false;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    if (_selectedStatusFilter == status) return;
    _selectedStatusFilter = status;
    notifyListeners();
  }

  void setHorizon(String horizon) {
    if (_selectedHorizon == horizon) return;
    _selectedHorizon = horizon;
    notifyListeners();
    loadCashFlowForecast(horizon: horizon);
  }

  void resetSimulation() {
    _simulation = null;
    notifyListeners();
  }

  /// Loads all goals with offline cache fallback
  Future<void> loadGoals({bool forceRefresh = false}) async {
    final currentGeneration = _sessionGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Load from cache first if available
    try {
      final cached = await CacheService.get('fintrack_goals_list');
      if (cached is List && cached.isNotEmpty && !forceRefresh) {
        _goals = cached
            .map((item) => GoalModel.fromJson(item as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (_) {}

    try {
      final response = await _repository.getGoals();
      if (currentGeneration != _sessionGeneration) return;

      if (response.success) {
        _goals = response.data;
        await CacheService.save(
          'fintrack_goals_list',
          _goals.map((g) => g.toJson()).toList(),
        );
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      if (currentGeneration != _sessionGeneration) return;
      _errorMessage = _parseError(e);
    } finally {
      if (currentGeneration == _sessionGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Loads aggregated goals summary metrics
  Future<void> loadSummary() async {
    final currentGeneration = _sessionGeneration;
    try {
      final response = await _repository.getGoalsSummary();
      if (currentGeneration != _sessionGeneration) return;
      if (response.success) {
        _summary = response.data;
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Loads details and contributions for a single goal
  Future<void> loadGoalById(int goalId) async {
    final currentGeneration = _sessionGeneration;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.getGoalById(goalId);
      if (currentGeneration != _sessionGeneration) return;

      if (response.success) {
        _selectedGoal = response.data;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      if (currentGeneration != _sessionGeneration) return;
      _errorMessage = _parseError(e);
    } finally {
      if (currentGeneration == _sessionGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Creates a new goal
  Future<bool> createGoal(Map<String, dynamic> data) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.createGoal(data);
      if (response.success) {
        _goals.insert(0, response.data);
        await loadSummary();
        _isActionLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Updates an existing goal
  Future<bool> updateGoal(int goalId, Map<String, dynamic> data) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.updateGoal(goalId, data);
      if (response.success) {
        final updated = response.data;
        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          _goals[index] = updated;
        }
        if (_selectedGoal?.id == goalId) {
          _selectedGoal = updated;
        }
        await loadSummary();
        _isActionLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Deletes a goal
  Future<bool> deleteGoal(int goalId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.deleteGoal(goalId);
      if (response.success) {
        _goals.removeWhere((g) => g.id == goalId);
        if (_selectedGoal?.id == goalId) {
          _selectedGoal = null;
        }
        await loadSummary();
        _isActionLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Records a contribution progress allocation
  Future<bool> addContribution(int goalId, Map<String, dynamic> data) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.addContribution(goalId, data);
      if (response.success) {
        final updatedGoal = response.data['goal'] as GoalModel;
        final contribution = response.data['contribution'] as GoalContributionModel;

        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          _goals[index] = updatedGoal;
        }

        if (_selectedGoal?.id == goalId) {
          final updatedRecent = [contribution, ..._selectedGoal!.recentContributions];
          _selectedGoal = updatedGoal.copyWith(
            recentContributions: updatedRecent,
            contributionsCount: _selectedGoal!.contributionsCount + 1,
          );
        }

        await loadSummary();
        _isActionLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Updates/corrects a contribution
  Future<bool> updateContribution(
    int goalId,
    int contributionId,
    Map<String, dynamic> data,
  ) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.updateContribution(goalId, contributionId, data);
      if (response.success) {
        final updatedGoal = response.data['goal'] as GoalModel;
        final updatedContribution = response.data['contribution'] as GoalContributionModel;

        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          _goals[index] = updatedGoal;
        }

        if (_selectedGoal?.id == goalId) {
          final list = _selectedGoal!.recentContributions.map((c) {
            return c.id == contributionId ? updatedContribution : c;
          }).toList();
          _selectedGoal = updatedGoal.copyWith(recentContributions: list);
        }

        await loadSummary();
        _isActionLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Deletes a contribution record
  Future<bool> deleteContribution(int goalId, int contributionId) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.deleteContribution(goalId, contributionId);
      if (response.success) {
        final updatedGoal = response.data;
        final index = _goals.indexWhere((g) => g.id == goalId);
        if (index != -1) {
          _goals[index] = updatedGoal;
        }

        if (_selectedGoal?.id == goalId) {
          final list = _selectedGoal!.recentContributions
              .where((c) => c.id != contributionId)
              .toList();
          _selectedGoal = updatedGoal.copyWith(
            recentContributions: list,
            contributionsCount: (_selectedGoal!.contributionsCount - 1).clamp(0, 99999),
          );
        }

        await loadSummary();
        _isActionLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
    return false;
  }

  /// Generates cash-flow forecast
  Future<void> loadCashFlowForecast({String? horizon}) async {
    final currentGeneration = _sessionGeneration;
    final targetHorizon = horizon ?? _selectedHorizon;
    _isForecastLoading = true;
    notifyListeners();

    try {
      final response = await _repository.getCashFlowForecast(horizon: targetHorizon);
      if (currentGeneration != _sessionGeneration) return;

      if (response.success) {
        _forecast = response.data;
      }
    } catch (e) {
      if (currentGeneration != _sessionGeneration) return;
      _errorMessage = _parseError(e);
    } finally {
      if (currentGeneration == _sessionGeneration) {
        _isForecastLoading = false;
        notifyListeners();
      }
    }
  }

  /// Runs interactive what-if simulation
  Future<bool> runSimulation(Map<String, dynamic> scenario) async {
    _isSimulating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.runSimulation(scenario);
      if (response.success) {
        _simulation = response.data;
        _isSimulating = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
      }
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isSimulating = false;
      notifyListeners();
    }
    return false;
  }

  String _parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data is Map) {
        final message = error.response!.data['message'];
        if (message is String) return message;
      }
      return error.message ?? "Network error occurred";
    }
    return error.toString();
  }
}
