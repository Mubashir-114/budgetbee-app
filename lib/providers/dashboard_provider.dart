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

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DashboardSummary? get summary => _summary;
  List<MonthlySummary> get monthlySummaries => _monthlySummaries;
  List<CategorySummary> get categorySummaries => _categorySummaries;
  List<TransactionModel> get recentTransactions => _recentTransactions;

  Future<void> loadDashboardData() async {
    try {
      _isLoading = true;
      _errorMessage = null;

      // Try loading from local cache first
      final cached = await CacheService.get("dashboard_cache");
      if (cached != null) {
        try {
          _summary = DashboardSummary.fromJson(cached["summary"]);
          _monthlySummaries = (cached["monthly"] as List).map((i) => MonthlySummary.fromJson(i)).toList();
          _categorySummaries = (cached["categories"] as List).map((i) => CategorySummary.fromJson(i)).toList();
          _recentTransactions = (cached["recent"] as List).map((i) => TransactionModel.fromJson(i)).toList();
          notifyListeners();
        } catch (_) {
          // Ignore corrupted cache
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
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load dashboard data";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
