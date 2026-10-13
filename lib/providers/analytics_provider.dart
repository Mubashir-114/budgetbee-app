import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/analytics_model.dart';
import '../repositories/analytics_repository.dart';
import '../core/services/cache_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _repository;

  AnalyticsProvider({AnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository();

  bool _isLoading = false;
  bool _isTyping = false;
  String? _errorMessage;
  bool _isRateLimited = false;
  bool _isOffline = false;

  AnalyticsCapability? _capabilities;
  AnalyticsQueryResult? _latestResult;
  List<AnalyticsInsightItem> _insights = [];
  AnalyticsPeriod? _currentPeriod;

  // Phase 5B Conversation State
  List<ChatMessage> _messages = [];
  ConversationContext? _conversationContext;

  // Phase 5C Proactive Alerts State
  List<SmartAlertItem> _alerts = [];
  Set<String> _dismissedAlertIds = {};
  AlertPreferences _preferences = const AlertPreferences();
  bool _isLoadingAlerts = false;
  String? _alertsError;

  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;
  bool get isRateLimited => _isRateLimited;
  bool get isOffline => _isOffline;

  AnalyticsCapability? get capabilities => _capabilities;
  AnalyticsQueryResult? get latestResult => _latestResult;
  List<AnalyticsInsightItem> get insights => _insights;
  AnalyticsPeriod? get currentPeriod => _currentPeriod;

  List<ChatMessage> get messages => _messages;
  ConversationContext? get conversationContext => _conversationContext;

  // Phase 5C Getters
  List<SmartAlertItem> get alerts => _alerts;
  Set<String> get dismissedAlertIds => _dismissedAlertIds;
  AlertPreferences get preferences => _preferences;
  bool get isLoadingAlerts => _isLoadingAlerts;
  String? get alertsError => _alertsError;

  List<SmartAlertItem> get activeAlerts {
    if (!_preferences.enableProactiveInsights) return [];
    return _alerts.where((a) => !_dismissedAlertIds.contains(a.id)).toList();
  }

  List<SuggestedQuestion> get suggestedQuestions =>
      _capabilities?.suggestedQuestions ?? [];

  void clearSession() {
    _isLoading = false;
    _isTyping = false;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    _capabilities = null;
    _latestResult = null;
    _insights = [];
    _currentPeriod = null;
    _messages = [];
    _conversationContext = null;

    // Phase 5C Alert Reset
    _alerts = [];
    _dismissedAlertIds = {};
    _preferences = const AlertPreferences();
    _isLoadingAlerts = false;
    _alertsError = null;

    notifyListeners();
  }

  void clearResult() {
    _latestResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearConversation() {
    _messages = [];
    _conversationContext = null;
    _latestResult = null;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
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

  Future<void> askQuestion(
    String question, {
    String? period,
    String? category,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    // Add user message to conversation list
    final userMsg = ChatMessage(
      id: "u_${DateTime.now().millisecondsSinceEpoch}",
      sender: MessageSender.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    _isLoading = true;
    _isTyping = true;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    notifyListeners();

    try {
      final res = await _repository.queryAnalytics(
        question: trimmed,
        period: period ?? _conversationContext?.activePeriod ?? 'current_month',
        category: category,
        conversationContext: _conversationContext,
      );

      if (res.success) {
        _latestResult = res.data;
        if (res.data.period != null) {
          _currentPeriod = res.data.period;
        }
        if (res.data.conversationContext != null) {
          _conversationContext = res.data.conversationContext;
        }

        // Add assistant response to conversation list
        final assistantMsg = ChatMessage(
          id: "a_${DateTime.now().millisecondsSinceEpoch}",
          sender: MessageSender.assistant,
          text: res.data.answer,
          timestamp: DateTime.now(),
          result: res.data,
          isRefusal: res.data.isRefusal,
          clarificationOptions: res.data.clarificationOptions,
          followUpSuggestions: res.data.followUpSuggestions,
        );
        _messages.add(assistantMsg);
      } else {
        _errorMessage = res.message;
      }
    } on DioException catch (dioErr) {
      _handleDioError(dioErr);
    } catch (e) {
      _errorMessage = "Unable to process query. Please try again.";
    } finally {
      _isLoading = false;
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> selectIntent(
    String intent, {
    String? period,
    String? category,
  }) async {
    _isLoading = true;
    _isTyping = true;
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    notifyListeners();

    try {
      final res = await _repository.queryAnalytics(
        intent: intent,
        period: period ?? _conversationContext?.activePeriod ?? 'current_month',
        category: category,
        conversationContext: _conversationContext,
      );

      if (res.success) {
        _latestResult = res.data;
        if (res.data.period != null) {
          _currentPeriod = res.data.period;
        }
        if (res.data.conversationContext != null) {
          _conversationContext = res.data.conversationContext;
        }

        final assistantMsg = ChatMessage(
          id: "a_${DateTime.now().millisecondsSinceEpoch}",
          sender: MessageSender.assistant,
          text: res.data.answer,
          timestamp: DateTime.now(),
          result: res.data,
          isRefusal: res.data.isRefusal,
          clarificationOptions: res.data.clarificationOptions,
          followUpSuggestions: res.data.followUpSuggestions,
        );
        _messages.add(assistantMsg);
      } else {
        _errorMessage = res.message;
      }
    } on DioException catch (dioErr) {
      _handleDioError(dioErr);
    } catch (e) {
      _errorMessage = "Unable to process intent. Please try again.";
    } finally {
      _isLoading = false;
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> selectClarification(ClarificationOption option) async {
    await askQuestion(option.question);
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
      _errorMessage = "Too many requests, please try again later";
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout) {
      _isOffline = true;
      _errorMessage = "Offline Mode: Unable to connect to server";
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

  // ==========================================
  // Phase 5C: Proactive Intelligence & Alerts
  // ==========================================

  Future<void> initializeAlertPreferences() async {
    try {
      final savedPrefs = await CacheService.get('smart_alert_preferences');
      if (savedPrefs != null && savedPrefs is Map<String, dynamic>) {
        _preferences = AlertPreferences.fromJson(savedPrefs);
      }
      final savedDismissed = await CacheService.get('dismissed_alert_ids');
      if (savedDismissed != null && savedDismissed is List) {
        _dismissedAlertIds = savedDismissed.map((e) => e.toString()).toSet();
      }
      notifyListeners();
    } catch (_) {
      // Graceful fallback to default preferences
    }
  }

  Future<void> updatePreferences(AlertPreferences newPreferences) async {
    _preferences = newPreferences;
    notifyListeners();
    await CacheService.save('smart_alert_preferences', _preferences.toJson());
    await loadAlerts();
  }

  Future<void> dismissAlert(String alertId) async {
    _dismissedAlertIds.add(alertId);
    notifyListeners();
    await CacheService.save('dismissed_alert_ids', _dismissedAlertIds.toList());
  }

  Future<void> resetDismissedAlerts() async {
    _dismissedAlertIds.clear();
    notifyListeners();
    await CacheService.save('dismissed_alert_ids', <String>[]);
  }

  Future<void> loadAlerts({
    String? period,
    String? month,
    String? startDate,
    String? endDate,
  }) async {
    if (!_preferences.enableProactiveInsights) {
      _alerts = [];
      _alertsError = null;
      notifyListeners();
      return;
    }

    _isLoadingAlerts = true;
    _alertsError = null;
    notifyListeners();

    try {
      final res = await _repository.getProactiveAlerts(
        period: period ?? 'current_month',
        month: month,
        startDate: startDate,
        endDate: endDate,
        preferences: _preferences,
      );

      if (res.success) {
        _alerts = res.data;
        _alertsError = null;
      } else {
        _alertsError = res.message;
      }
    } on DioException catch (dioErr) {
      if (dioErr.type == DioExceptionType.connectionTimeout ||
          dioErr.type == DioExceptionType.connectionError ||
          dioErr.type == DioExceptionType.receiveTimeout) {
        _alertsError = "Offline: Unable to evaluate live alerts";
      } else if (dioErr.response?.statusCode == 429) {
        _alertsError = "Rate limited: Please wait before refreshing alerts";
      } else {
        _alertsError = "Failed to load proactive financial alerts.";
      }
    } catch (_) {
      _alertsError = "An unexpected error occurred while loading alerts.";
    } finally {
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }

  Future<void> askAlertQuestion(
    SmartAlertItem alert,
    String question,
  ) async {
    await askQuestion(
      question,
      period: alert.period?.label ?? 'current_month',
      category: alert.category,
    );
  }
}
