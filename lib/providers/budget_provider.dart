import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/budget_model.dart';
import '../repositories/budget_repository.dart';
import '../core/services/cache_service.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetRepository _repository = BudgetRepository();

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  List<BudgetModel> _budgets = [];
  List<BudgetStatusModel> _budgetStatuses = [];

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _sessionGeneration = 0;
  int _loadGeneration = 0;

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  List<BudgetStatusModel> get budgetStatuses => _budgetStatuses;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void clearSession() {
    _sessionGeneration++;
    _loadGeneration++;
    _isLoading = false;
    _isActionLoading = false;
    _errorMessage = null;
    _budgets = [];
    _budgetStatuses = [];
    notifyListeners();
  }

  void changeDate(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    loadBudgetStatus();
  }

  Future<void> loadBudgets() async {
    final sessionGeneration = _sessionGeneration;
    final loadGeneration = ++_loadGeneration;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.getBudgets();
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _budgets = response.data;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load budgets";
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage = e.toString();
    } finally {
      if (sessionGeneration == _sessionGeneration &&
          loadGeneration == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadBudgetStatus() async {
    final sessionGeneration = _sessionGeneration;
    final loadGeneration = ++_loadGeneration;
    final month = _selectedMonth;
    final year = _selectedYear;
    final String cacheKey = 'budget_status_${month}_$year';
    try {
      _isLoading = true;
      _errorMessage = null;

      final cached = await CacheService.get(cacheKey);
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      if (cached != null) {
        try {
          _budgetStatuses = (cached as List).map((i) => BudgetStatusModel.fromJson(i)).toList();
          notifyListeners();
        } catch (_) {
          await CacheService.remove(cacheKey);
        }
      } else {
        notifyListeners();
      }

      final response = await _repository.getBudgetStatus(
        month: month,
        year: year,
      );
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _budgetStatuses = response.data;

      await CacheService.save(cacheKey, _budgetStatuses.map((b) => b.toJson()).toList());
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load budget status";
    } catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage = e.toString();
    } finally {
      if (sessionGeneration == _sessionGeneration &&
          loadGeneration == _loadGeneration) {
        _isLoading = false;
        notifyListeners();
      }
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
      await loadBudgetStatus();
      await loadBudgets();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to add budget";
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
      await loadBudgetStatus();
      await loadBudgets();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to update budget";
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
      await loadBudgetStatus();
      await loadBudgets();
      return true;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return false;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to delete budget";
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
