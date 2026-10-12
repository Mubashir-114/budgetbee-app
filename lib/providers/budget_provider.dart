import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import '../core/services/cache_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repository = BudgetRepository();

  bool _isLoading = false;
  bool _isActionLoading = false;
  bool _isSuggestionsLoading = false;
  bool _isHistoryLoading = false;
  String? _errorMessage;

  List<BudgetModel> _budgets = [];
  List<BudgetStatusModel> _budgetStatuses = [];
  BudgetProgressResponseModel? _progress;
  BudgetAlertsResponseModel? _alerts;
  List<BudgetSuggestionModel> _suggestions = [];
  List<BudgetHistoryItemModel> _history = [];
  double? _userSavingsTarget;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _sessionGeneration = 0;
  int _progressGeneration = 0;
  int _statusGeneration = 0;
  int _budgetsGeneration = 0;
  int _alertsGeneration = 0;
  int _suggestionsGeneration = 0;
  int _historyGeneration = 0;
  int _activeLoadsCount = 0;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  bool get isSuggestionsLoading => _isSuggestionsLoading;
  bool get isHistoryLoading => _isHistoryLoading;
  String? get errorMessage => _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  List<BudgetStatusModel> get budgetStatuses => _budgetStatuses;
  BudgetProgressResponseModel? get progress => _progress;
  BudgetAlertsResponseModel? get alerts => _alerts;
  List<BudgetSuggestionModel> get suggestions => _suggestions;
  List<BudgetHistoryItemModel> get history => _history;
  double? get userSavingsTarget => _userSavingsTarget;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void clearSession() {
    _sessionGeneration++;
    _progressGeneration++;
    _statusGeneration++;
    _budgetsGeneration++;
    _alertsGeneration++;
    _suggestionsGeneration++;
    _historyGeneration++;
    _activeLoadsCount = 0;
    _isLoading = false;
    _isActionLoading = false;
    _isSuggestionsLoading = false;
    _isHistoryLoading = false;
    _errorMessage = null;
    _budgets = [];
    _budgetStatuses = [];
    _progress = null;
    _alerts = null;
    _suggestions = [];
    _history = [];
    _userSavingsTarget = null;
    notifyListeners();
  }

  void changeDate(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    _progressGeneration++;
    _statusGeneration++;
    _budgetsGeneration++;
    _alertsGeneration++;
    loadAllBudgetData();
  }

  void setUserSavingsTarget(double? target) {
    _userSavingsTarget = target;
    loadBudgetProgress();
  }

  Future<void> loadAllBudgetData({bool forceRefresh = false}) async {
    _errorMessage = null;
    await Future.wait([
      loadBudgetProgress(forceRefresh: forceRefresh),
      loadBudgetAlerts(),
      loadBudgetStatus(forceRefresh: forceRefresh),
      loadBudgets(),
    ]);
  }

  Future<void> loadBudgets() async {
    final sessionGeneration = _sessionGeneration;
    final generation = ++_budgetsGeneration;
    try {
      _activeLoadsCount++;
      _isLoading = true;
      _errorMessage = null;

      final response = await _repository.getBudgets(
        month: _selectedMonth,
        year: _selectedYear,
      );
      if (sessionGeneration != _sessionGeneration ||
          generation != _budgetsGeneration) {
        return;
      }
      _budgets = response.data;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _budgetsGeneration) {
        return;
      }
      _errorMessage =
          e.response?.data["message"] ?? e.message ?? "Failed to load budgets";
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _budgetsGeneration) {
        return;
      }
      _errorMessage = e.toString();
    } finally {
      _activeLoadsCount = _activeLoadsCount > 0 ? _activeLoadsCount - 1 : 0;
      if (_activeLoadsCount == 0) {
        _isLoading = false;
      }
      if (sessionGeneration == _sessionGeneration &&
          generation == _budgetsGeneration) {
        notifyListeners();
      }
    }
  }

  Future<void> loadBudgetStatus({bool forceRefresh = false}) async {
    final sessionGeneration = _sessionGeneration;
    final generation = ++_statusGeneration;
    final month = _selectedMonth;
    final year = _selectedYear;
    final String cacheKey = 'budget_status_${month}_$year';
    try {
      _activeLoadsCount++;
      _isLoading = true;
      _errorMessage = null;

      if (!forceRefresh) {
        final cached = await CacheService.get(cacheKey);
        if (sessionGeneration != _sessionGeneration ||
            generation != _statusGeneration) {
          return;
        }
        if (cached != null) {
          try {
            _budgetStatuses = (cached as List)
                .map((i) => BudgetStatusModel.fromJson(i as Map<String, dynamic>))
                .toList();
            notifyListeners();
          } catch (_) {
            await CacheService.remove(cacheKey);
          }
        }
      }

      final response = await _repository.getBudgetStatus(
        month: month,
        year: year,
      );
      if (sessionGeneration != _sessionGeneration ||
          generation != _statusGeneration) {
        return;
      }
      _budgetStatuses = response.data;

      await CacheService.save(
        cacheKey,
        _budgetStatuses.map((b) => b.toJson()).toList(),
      );
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _statusGeneration) {
        return;
      }
      _errorMessage = e.response?.data["message"] ??
          e.message ??
          "Failed to load budget status";
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _statusGeneration) {
        return;
      }
      _errorMessage = e.toString();
    } finally {
      _activeLoadsCount = _activeLoadsCount > 0 ? _activeLoadsCount - 1 : 0;
      if (_activeLoadsCount == 0) {
        _isLoading = false;
      }
      if (sessionGeneration == _sessionGeneration &&
          generation == _statusGeneration) {
        notifyListeners();
      }
    }
  }

  Future<void> loadBudgetProgress({bool forceRefresh = false}) async {
    final sessionGeneration = _sessionGeneration;
    final generation = ++_progressGeneration;
    final month = _selectedMonth;
    final year = _selectedYear;
    final String cacheKey = 'budget_progress_${month}_$year';
    try {
      _activeLoadsCount++;
      _isLoading = true;
      _errorMessage = null;

      if (!forceRefresh) {
        final cached = await CacheService.get(cacheKey);
        if (sessionGeneration != _sessionGeneration ||
            generation != _progressGeneration) {
          return;
        }
        if (cached != null) {
          try {
            _progress = BudgetProgressResponseModel.fromJson(
              cached as Map<String, dynamic>,
            );
            notifyListeners();
          } catch (_) {
            await CacheService.remove(cacheKey);
          }
        }
      }

      final response = await _repository.getBudgetProgress(
        month: month,
        year: year,
        savingsTarget: _userSavingsTarget,
      );
      if (sessionGeneration != _sessionGeneration ||
          generation != _progressGeneration) {
        return;
      }
      _progress = response.data;

      await CacheService.save(cacheKey, _progress!.toJson());
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _progressGeneration) {
        return;
      }
      _errorMessage = e.response?.data["message"] ??
          e.message ??
          "Failed to load budget progress";
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _progressGeneration) {
        return;
      }
      _errorMessage = e.toString();
    } finally {
      _activeLoadsCount = _activeLoadsCount > 0 ? _activeLoadsCount - 1 : 0;
      if (_activeLoadsCount == 0) {
        _isLoading = false;
      }
      if (sessionGeneration == _sessionGeneration &&
          generation == _progressGeneration) {
        notifyListeners();
      }
    }
  }

  Future<void> loadBudgetAlerts() async {
    final sessionGeneration = _sessionGeneration;
    final generation = ++_alertsGeneration;
    final month = _selectedMonth;
    final year = _selectedYear;
    try {
      final response = await _repository.getBudgetAlerts(
        month: month,
        year: year,
      );
      if (sessionGeneration != _sessionGeneration ||
          generation != _alertsGeneration) {
        return;
      }
      _alerts = response.data;
      notifyListeners();
    } catch (_) {
      // Non-critical, fail gracefully
    }
  }

  Future<void> loadBudgetSuggestions() async {
    final sessionGeneration = _sessionGeneration;
    final generation = ++_suggestionsGeneration;
    try {
      _isSuggestionsLoading = true;
      notifyListeners();

      final response = await _repository.getBudgetSuggestions(
        month: _selectedMonth,
        year: _selectedYear,
        savingsTarget: _userSavingsTarget,
      );
      if (sessionGeneration != _sessionGeneration ||
          generation != _suggestionsGeneration) {
        return;
      }
      _suggestions = response.data;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _suggestionsGeneration) {
        return;
      }
      _errorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to load suggestions")
          : e.toString();
    } finally {
      if (sessionGeneration == _sessionGeneration &&
          generation == _suggestionsGeneration) {
        _isSuggestionsLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadBudgetHistory({int months = 6}) async {
    final sessionGeneration = _sessionGeneration;
    final generation = ++_historyGeneration;
    try {
      _isHistoryLoading = true;
      notifyListeners();

      final response = await _repository.getBudgetHistory(months: months);
      if (sessionGeneration != _sessionGeneration ||
          generation != _historyGeneration) {
        return;
      }
      _history = response.data;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          generation != _historyGeneration) {
        return;
      }
      _errorMessage = e is DioException
          ? (e.response?.data["message"] ?? e.message ?? "Failed to load history")
          : e.toString();
    } finally {
      if (sessionGeneration == _sessionGeneration &&
          generation == _historyGeneration) {
        _isHistoryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> applySuggestion(BudgetSuggestionModel suggestion) async {
    final amount = double.tryParse(suggestion.estimates.suggestedBudget) ?? 0.0;
    if (amount <= 0) return false;

    // Check if category already has a budget in this month
    final existingStatus = _budgetStatuses
        .where((b) => b.categoryId == suggestion.categoryId)
        .firstOrNull;
    final existingProgress = _progress?.categoryBudgets
        .where((b) => b.categoryId == suggestion.categoryId)
        .firstOrNull;
    final existingBudget = _budgets
        .where((b) =>
            b.categoryId == suggestion.categoryId &&
            b.month == _selectedMonth &&
            b.year == _selectedYear)
        .firstOrNull;

    final existingId = existingStatus?.budgetId ??
        existingProgress?.budgetId ??
        existingBudget?.id;

    if (existingId != null) {
      return await editBudget(
        id: existingId,
        categoryId: suggestion.categoryId,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    } else {
      return await addBudget(
        categoryId: suggestion.categoryId,
        amount: amount,
        month: _selectedMonth,
        year: _selectedYear,
      );
    }
  }

  Future<bool> addBudget({
    required int categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.addBudget(
        categoryId: categoryId,
        amount: amount,
        month: month,
        year: year,
      );

      if (sessionGeneration != _sessionGeneration) return false;
      await CacheService.clearBudgetCaches();
      await CacheService.remove('dashboard_cache');
      if (_selectedMonth != month || _selectedYear != year) {
        _selectedMonth = month;
        _selectedYear = year;
        _progressGeneration++;
        _statusGeneration++;
        _budgetsGeneration++;
        _alertsGeneration++;
      }
      await loadAllBudgetData(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage =
          e.response?.data["message"] ?? e.message ?? "Failed to add budget";
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.toString();
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> editBudget({
    required int id,
    required int categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.editBudget(
        id: id,
        categoryId: categoryId,
        amount: amount,
        month: month,
        year: year,
      );

      if (sessionGeneration != _sessionGeneration) return false;
      await CacheService.clearBudgetCaches();
      await CacheService.remove('dashboard_cache');
      if (_selectedMonth != month || _selectedYear != year) {
        _selectedMonth = month;
        _selectedYear = year;
        _progressGeneration++;
        _statusGeneration++;
        _budgetsGeneration++;
        _alertsGeneration++;
      }
      await loadAllBudgetData(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage =
          e.response?.data["message"] ?? e.message ?? "Failed to update budget";
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.toString();
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteBudget(int id) async {
    final sessionGeneration = _sessionGeneration;
    try {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.removeBudget(id);

      if (sessionGeneration != _sessionGeneration) return false;
      await CacheService.clearBudgetCaches();
      await CacheService.remove('dashboard_cache');
      await loadAllBudgetData(forceRefresh: true);
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage =
          e.response?.data["message"] ?? e.message ?? "Failed to delete budget";
      return false;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.toString();
      return false;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isActionLoading = false;
        notifyListeners();
      }
    }
  }
}
