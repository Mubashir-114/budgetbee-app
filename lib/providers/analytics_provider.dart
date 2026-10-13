import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/analytics_model.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _repository;

  AnalyticsProvider({AnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isRateLimited = false;
  bool _isOffline = false;

  AnalyticsCapability? _capabilities;
  AnalyticsQueryResult? _latestResult;
  List<AnalyticsInsightItem> _insights = [];
  AnalyticsPeriod? _currentPeriod;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRateLimited => _isRateLimited;
  bool get isOffline => _isOffline;

  AnalyticsCapability? get capabilities => _capabilities;
  AnalyticsQueryResult? get latestResult => _latestResult;
  List<AnalyticsInsightItem> get insights => _insights;
  AnalyticsPeriod? get currentPeriod => _currentPeriod;

  List<SuggestedQuestion> get suggestedQuestions =>
      _capabilities?.suggestedQuestions ?? [];

  void clearSession() {
    _isLoading = false;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    _capabilities = null;
    _latestResult = null;
    _insights = [];
    _currentPeriod = null;
    notifyListeners();
  }

  void clearResult() {
    _latestResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadCapabilities() async {
    if (_capabilities != null) return;
    try {
      final res = await _repository.getCapabilities();
      if (res.success) {
        _capabilities = res.data;
        notifyListeners();
      }
    } catch (_) {
      // Non-critical background fetch failure
    }
  }

  Future<void> askQuestion(String question, {String? period}) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    notifyListeners();

    try {
      final res = await _repository.queryAnalytics(
        question: trimmed,
        period: period ?? 'current_month',
      );

      if (res.success) {
        _latestResult = res.data;
        if (res.data.period != null) {
          _currentPeriod = res.data.period;
        }
      } else {
        _errorMessage = res.message;
      }
    } on DioException catch (dioErr) {
      _handleDioError(dioErr);
    } catch (e) {
      _errorMessage = "Unable to process query. Please try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectIntent(String intent, {String? period}) async {
    _isLoading = true;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    notifyListeners();

    try {
      final res = await _repository.queryAnalytics(
        intent: intent,
        period: period ?? 'current_month',
      );

      if (res.success) {
        _latestResult = res.data;
        if (res.data.period != null) {
          _currentPeriod = res.data.period;
        }
      } else {
        _errorMessage = res.message;
      }
    } on DioException catch (dioErr) {
      _handleDioError(dioErr);
    } catch (e) {
      _errorMessage = "Unable to process intent. Please try again.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInsights({String? period, String? month}) async {
    _isLoading = true;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    notifyListeners();

    try {
      final res = await _repository.getInsights(
        period: period ?? 'current_month',
        month: month,
      );

      if (res.success) {
        final periodMap = res.data['period'] as Map<String, dynamic>?;
        if (periodMap != null) {
          _currentPeriod = AnalyticsPeriod.fromJson(periodMap);
        }

        final rawInsights = res.data['insights'] as List<dynamic>? ?? [];
        _insights = rawInsights
            .map((i) => AnalyticsInsightItem.fromJson(i as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = res.message;
      }
    } on DioException catch (dioErr) {
      _handleDioError(dioErr);
    } catch (e) {
      _errorMessage = "Unable to load financial insights.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _handleDioError(DioException error) {
    if (error.response?.statusCode == 429) {
      _isRateLimited = true;
      _errorMessage = "Query rate limit reached. Please wait a moment before trying again.";
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout) {
      _isOffline = true;
      _errorMessage = "Unable to reach server. Please check your network connection.";
    } else if (error.response?.statusCode == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        _errorMessage = data['message'].toString();
      } else {
        _errorMessage = "Invalid query parameters.";
      }
    } else {
      _errorMessage = "A secure error occurred while processing analytics. Please retry.";
    }
  }
}
