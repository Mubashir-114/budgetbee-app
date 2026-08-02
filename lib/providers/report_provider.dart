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

  bool get isLoading => _isLoading;
  bool get isExporting => _isExporting;
  String? get errorMessage => _errorMessage;

  ReportSummary? get summary => _summary;
  List<MonthlyReport> get monthlyReports => _monthlyReports;
  List<CategoryReport> get categoryReports => _categoryReports;
  List<TrendsReport> get trendsReports => _trendsReports;
  List<CashflowReport> get cashflowReports => _cashflowReports;

  DateTimeRange? get selectedDateRange => _selectedDateRange;

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    loadAllReports();
  }

  void clearDateRange() {
    _selectedDateRange = null;
    loadAllReports();
  }

  Future<void> loadAllReports() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      String? fromDate;
      String? toDate;
      if (_selectedDateRange != null) {
        fromDate = _selectedDateRange!.start.toIso8601String().split('T')[0];
        toDate = _selectedDateRange!.end.toIso8601String().split('T')[0];
      }

      final responses = await Future.wait([
        _repository.getSummary(from: fromDate, to: toDate),
        _repository.getMonthly(from: fromDate, to: toDate),
        _repository.getCategory(from: fromDate, to: toDate),
        _repository.getTrends(from: fromDate, to: toDate),
        _repository.getCashflow(from: fromDate, to: toDate),
      ]);

      _summary = responses[0].data as ReportSummary;
      _monthlyReports = responses[1].data as List<MonthlyReport>;
      _categoryReports = responses[2].data as List<CategoryReport>;
      _trendsReports = responses[3].data as List<TrendsReport>;
      _cashflowReports = responses[4].data as List<CashflowReport>;

      _errorMessage = null;
    } on DioException catch (e) {
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to load reports";
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> exportCSV() async {
    try {
      _isExporting = true;
      _errorMessage = null;
      notifyListeners();

      String? fromDate;
      String? toDate;
      if (_selectedDateRange != null) {
        fromDate = _selectedDateRange!.start.toIso8601String().split('T')[0];
        toDate = _selectedDateRange!.end.toIso8601String().split('T')[0];
      }

      final csvContent = await _repository.exportReportCsv(
        from: fromDate,
        to: toDate,
      );

      return csvContent;
    } on DioException catch (e) {
      _errorMessage = e.response?.data["message"] ?? e.message ?? "Failed to export report";
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  bool _isPdfExporting = false;
  bool get isPdfExporting => _isPdfExporting;

  Future<String?> exportPDF(String dateRangeStr, [String currencySymbol = '\$']) async {
    if (_summary == null) return null;

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

      return path;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isPdfExporting = false;
      notifyListeners();
    }
  }
}
