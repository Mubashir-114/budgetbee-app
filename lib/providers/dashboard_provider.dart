import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/dashboard_models.dart';
import '../models/transaction_model.dart';
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
  int _sessionGeneration = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardSummary? get summary => _summary;
  List<MonthlySummary> get monthlySummaries => _monthlySummaries;
  List<CategorySummary> get categorySummaries => _categorySummaries;
  List<TransactionModel> get recentTransactions => _recentTransactions;

  void clearSession() {
    _sessionGeneration++;
    _isLoading = false;
    _errorMessage = null;
    _summary = null;
    _monthlySummaries = [];
    _categorySummaries = [];
    _recentTransactions = [];
    notifyListeners();
  }

  Future<void> loadDashboardData() async {
    final generation = _sessionGeneration;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Try loading from local cache first
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
      } else {
        notifyListeners();
      }

      // Run requests concurrently
      final responses = await Future.wait([
        _repository.getSummary(),
        _repository.getMonthlySummary(),
        _repository.getCategorySummary(),
        _repository.getRecentTransactions(),
      ]);
      if (generation != _sessionGeneration) return;

      _summary = responses[0].data as DashboardSummary;
      _monthlySummaries = responses[1].data as List<MonthlySummary>;
      _categorySummaries = responses[2].data as List<CategorySummary>;
      _recentTransactions = responses[3].data as List<TransactionModel>;

      // Save to local cache
      await CacheService.save("dashboard_cache", {
        "summary": _summary?.toJson(),
        "monthly": _monthlySummaries.map((m) => m.toJson()).toList(),
        "categories": _categorySummaries.map((c) => c.toJson()).toList(),
        "recent": _recentTransactions.map((r) => r.toJson()).toList(),
      });

      _errorMessage = null;
    } on DioException catch (e) {
      if (generation != _sessionGeneration) return;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load dashboard data";
    } catch (e) {
      if (generation != _sessionGeneration) return;
      _errorMessage = e.toString();
    } finally {
      if (generation == _sessionGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }
}
