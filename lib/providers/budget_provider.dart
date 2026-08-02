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

  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  List<BudgetModel> get budgets => _budgets;
  List<BudgetStatusModel> get budgetStatuses => _budgetStatuses;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  void changeDate(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    loadBudgetStatus();
  }

  Future<void> loadBudgets() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.getBudgets();
      _budgets = response.data;
    } on DioException catch (e) {
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load budgets";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadBudgetStatus() async {
    final String cacheKey = "budget_status_${_selectedMonth}_$_selectedYear";
    try {
      _isLoading = true;
      _errorMessage = null;

      final cached = await CacheService.get(cacheKey);
      if (cached != null) {
        try {
          _budgetStatuses = (cached as List).map((i) => BudgetStatusModel.fromJson(i)).toList();
          notifyListeners();
        } catch (_) {}
      } else {
        notifyListeners();
      }

      final response = await _repository.getBudgetStatus(
        month: _selectedMonth,
        year: _selectedYear,
      );
      _budgetStatuses = response.data;

      await CacheService.save(cacheKey, _budgetStatuses.map((b) => b.toJson()).toList());
    } on DioException catch (e) {
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load budget status";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addBudget({
    required int categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
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

      await loadBudgetStatus();
      await loadBudgets();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to add budget";
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> editBudget({
    required int id,
    required int categoryId,
    required double amount,
    required int month,
    required int year,
  }) async {
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

      await loadBudgetStatus();
      await loadBudgets();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to update budget";
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBudget(int id) async {
    try {
      _isActionLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _repository.removeBudget(id);

      await loadBudgetStatus();
      await loadBudgets();
      return true;
    } on DioException catch (e) {
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to delete budget";
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isActionLoading = false;
      notifyListeners();
    }
  }
}
