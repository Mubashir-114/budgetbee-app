import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/dashboard_models.dart';
import '../models/transaction_model.dart';
import '../models/api_response.dart';
import '../repositories/dashboard_repository.dart';
import '../core/services/cache_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository = DashboardRepository();

  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary? _summary;
  List<MonthlySummary> _monthlySummaries = [];
  List<CategorySummary> _categorySummaries = [];
  List<TransactionModel> _recentTransactions = [];

  String _selectedPeriod = 'current_month'; // 'current_month', 'previous_month', 'custom'
  String? _selectedMonth;
  String? _startDate;
  String? _endDate;

  int _sessionGeneration = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardSummary? get summary => _summary;
  FinancialOverview? get overview => _summary?.overview;
  List<DashboardAccountItem> get accounts => _summary?.accounts ?? [];
  List<MonthlySummary> get monthlySummaries => _monthlySummaries;
  List<CategorySummary> get categorySummaries =>
      _summary?.categories.isNotEmpty == true ? _summary!.categories : _categorySummaries;
  List<CategorySummary> get topCategories => _summary?.topCategories ?? [];
  List<SpendingMerchant> get topMerchants => _summary?.topMerchants ?? [];
  List<DailyTrend> get dailyTrends => _summary?.dailyTrends ?? [];
  List<FinancialInsight> get insights => _summary?.insights ?? [];
  List<TransactionModel> get recentTransactions => _recentTransactions;

  String get selectedPeriod => _selectedPeriod;
  String? get selectedMonth => _selectedMonth;
  String? get startDate => _startDate;
  String? get endDate => _endDate;

  void clearSession() {
    _sessionGeneration++;
    _isLoading = false;
    _errorMessage = null;
    _summary = null;
    _monthlySummaries = [];
    _categorySummaries = [];
    _recentTransactions = [];
    _selectedPeriod = 'current_month';
    _selectedMonth = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  Future<void> invalidateCache() async {
    await CacheService.remove('dashboard_cache');
  }

  Future<void> setPeriod(String period) async {
    if (_selectedPeriod == period && _selectedMonth == null && _startDate == null) return;
    _selectedPeriod = period;
    _selectedMonth = null;
    _startDate = null;
    _endDate = null;
    await loadDashboardData();
  }

  Future<void> setMonth(String month) async {
    if (_selectedMonth == month && _selectedPeriod == 'custom') return;
    _selectedMonth = month;
    _selectedPeriod = 'custom';
    _startDate = null;
    _endDate = null;
    await loadDashboardData();
  }

  Future<void> setCustomDateRange(String start, String end) async {
    _startDate = start;
    _endDate = end;
    _selectedPeriod = 'custom';
    _selectedMonth = null;
    await loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    final generation = _sessionGeneration;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Load cached data if available and in default view
      if (_selectedPeriod == 'current_month' && _selectedMonth == null && _startDate == null) {
        final cached = await CacheService.get('dashboard_cache');
        if (generation != _sessionGeneration) return;
        if (cached != null) {
          try {
            _summary = DashboardSummary.fromJson(cached["summary"]);
            _monthlySummaries = (cached["monthly"] as List).map((i) => MonthlySummary.fromJson(i)).toList();
            _categorySummaries = (cached["categories"] as List).map((i) => CategorySummary.fromJson(i)).toList();
            _recentTransactions = (cached["recent"] as List).map((i) => TransactionModel.fromJson(i)).toList();
            notifyListeners();
          } catch (_) {
            await CacheService.remove('dashboard_cache');
          }
        }
      }

      // 1. Load core financial overview FIRST (required for dashboard to function)
      ApiResponse<DashboardSummary>? summaryResponse;
      try {
        summaryResponse = await _repository.getSummary(
          period: _selectedPeriod,
          month: _selectedMonth,
          startDate: _startDate,
          endDate: _endDate,
        );
        if (generation != _sessionGeneration) return;
        _summary = summaryResponse.data;
      } on DioException catch (e) {
        if (generation != _sessionGeneration) return;
        // Auth/session errors are global - propagate immediately
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          _errorMessage = e.response?.data["message"] ?? "Authentication failed";
          _isLoading = false;
          notifyListeners();
          return;
        }
        // Non-auth errors: log but continue with cached/partial data
        _errorMessage = "Overview failed: ${e.response?.data["message"] ?? e.message}";
      } catch (e) {
        if (generation != _sessionGeneration) return;
        _errorMessage = "Overview failed: $e";
      }

      // 2. Load optional sections INDEPENDENTLY (failures don't block core dashboard)
      Future<void> loadOptionalSection(
        String sectionName,
        Future<dynamic> Function() fetcher,
        void Function(dynamic) onSuccess,
      ) async {
        try {
          final response = await fetcher();
          if (generation != _sessionGeneration) return;
          onSuccess(response.data);
        } on DioException catch (e) {
          if (generation != _sessionGeneration) return;
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            _errorMessage = e.response?.data["message"] ?? "Authentication failed";
            _isLoading = false;
            notifyListeners();
            return;
          }
          // Log optional section failure but don't block UI
          debugPrint("$sectionName failed: ${e.response?.data["message"] ?? e.message}");
        } catch (e) {
          if (generation != _sessionGeneration) return;
          debugPrint("$sectionName failed: $e");
        }
      }

      await Future.wait([
        loadOptionalSection(
          "MonthlySummary",
          () => _repository.getMonthlySummary(),
          (data) => _monthlySummaries = data as List<MonthlySummary>,
        ),
        loadOptionalSection(
          "CategorySummary",
          () => _repository.getCategorySummary(
            month: _selectedMonth,
            startDate: _startDate,
            endDate: _endDate,
          ),
          (data) => _categorySummaries = data as List<CategorySummary>,
        ),
        loadOptionalSection(
          "RecentTransactions",
          () => _repository.getRecentTransactions(limit: 10),
          (data) => _recentTransactions = data as List<TransactionModel>,
        ),
      ]);
      if (generation != _sessionGeneration) return;

      // Save to local cache for default view
      if (_selectedPeriod == 'current_month' && _selectedMonth == null && _startDate == null && _summary != null) {
        await CacheService.save("dashboard_cache", {
          "summary": _summary?.toJson(),
          "monthly": _monthlySummaries.map((m) => m.toJson()).toList(),
          "categories": _categorySummaries.map((c) => c.toJson()).toList(),
          "recent": _recentTransactions.map((r) => r.toJson()).toList(),
        });
      }

      _errorMessage = null;
    } finally {
      if (generation == _sessionGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
