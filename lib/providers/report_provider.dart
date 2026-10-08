import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/report_models.dart';
import '../repositories/report_repository.dart';
import '../core/utils/pdf_exporter.dart';

class ReportProvider extends ChangeNotifier {
  final ReportRepository _repository = ReportRepository();

  bool _isLoading = false;
  bool _isExporting = false;
  String? _errorMessage;

  ReportSummary? _summary;
  List<MonthlyReport> _monthlyReports = [];
  List<CategoryReport> _categoryReports = [];
  List<TrendsReport> _trendsReports = [];
  List<CashflowReport> _cashflowReports = [];

  // Date filters
  DateTimeRange? _selectedDateRange;
  int _sessionGeneration = 0;
  int _loadGeneration = 0;

  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;

  ReportSummary? get summary => _summary;
  List<MonthlyReport> get monthlyReports => _monthlyReports;
  List<CategoryReport> get categoryReports => _categoryReports;
  List<TrendsReport> get trendsReports => _trendsReports;
  List<CashflowReport> get cashflowReports => _cashflowReports;

  DateTimeRange? get selectedDateRange => _selectedDateRange;

  void clearSession() {
    _sessionGeneration++;
    _loadGeneration++;
    _isLoading = false;
    _isExporting = false;
    _isPdfExporting = false;
    _errorMessage = null;
    _summary = null;
    _monthlyReports = [];
    _categoryReports = [];
    _trendsReports = [];
    _cashflowReports = [];
    _selectedDateRange = null;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    loadAllReports();
  }

  void clearDateRange() {
    _selectedDateRange = null;
    loadAllReports();
  }

  Future<void> loadAllReports() async {
    final sessionGeneration = _sessionGeneration;
    final loadGeneration = ++_loadGeneration;
    final dateRange = _selectedDateRange;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String? fromDate;
      String? toDate;
      if (dateRange != null) {
        fromDate = dateRange.start.toIso8601String().split('T')[0];
        toDate = dateRange.end.toIso8601String().split('T')[0];
      }

      final responses = await Future.wait([
        _repository.getSummary(from: fromDate, to: toDate),
        _repository.getMonthly(from: fromDate, to: toDate),
        _repository.getCategory(from: fromDate, to: toDate),
        _repository.getTrends(from: fromDate, to: toDate),
        _repository.getCashflow(from: fromDate, to: toDate),
      ]);
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }

      _summary = responses[0].data as ReportSummary;
      _monthlyReports = responses[1].data as List<MonthlyReport>;
      _categoryReports = responses[2].data as List<CategoryReport>;
      _trendsReports = responses[3].data as List<TrendsReport>;
      _cashflowReports = responses[4].data as List<CashflowReport>;

      _errorMessage = null;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration ||
          loadGeneration != _loadGeneration) {
        return;
      }
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load reports";
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

  Future<String?> exportCSV() async {
    final sessionGeneration = _sessionGeneration;
    final dateRange = _selectedDateRange;
    try {
      _isExporting = true;
      _errorMessage = null;
      notifyListeners();

      String? fromDate;
      String? toDate;
      if (dateRange != null) {
        fromDate = dateRange.start.toIso8601String().split('T')[0];
        toDate = dateRange.end.toIso8601String().split('T')[0];
      }

      final csvContent = await _repository.exportReportCsv(
        from: fromDate,
        to: toDate,
      );

      return sessionGeneration == _sessionGeneration ? csvContent : null;
    } on DioException catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to export report";
      return null;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _errorMessage = e.toString();
      return null;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isExporting = false;
        notifyListeners();
      }
    }
  }

  bool _isPdfExporting = false;
  bool get isPdfExporting => _isPdfExporting;

  Future<String?> exportPDF(String dateRangeStr, [String currencySymbol = '\$']) async {
    if (_summary == null) return null;

    final sessionGeneration = _sessionGeneration;
    try {
      _isPdfExporting = true;
      _errorMessage = null;
      notifyListeners();

      final path = await PdfExporter.generateReport(
        summary: _summary!,
        categoryReports: _categoryReports,
        cashflowReports: _cashflowReports,
        dateRangeStr: dateRangeStr,
        currencySymbol: currencySymbol,
      );

      return sessionGeneration == _sessionGeneration ? path : null;
    } catch (e) {
      if (sessionGeneration != _sessionGeneration) return null;
      _errorMessage = e.toString();
      return null;
    } finally {
      if (sessionGeneration == _sessionGeneration) {
        _isPdfExporting = false;
        notifyListeners();
      }
    }
  }
}
