import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/analytics_model.dart';
import '../repositories/analytics_repository.dart';
import '../core/services/cache_service.dart';
import '../screens/analytics/widgets/fin_visual_controller.dart';

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

  // Phase 5E FIN Living Companion State
  CompanionPreferences _companionPreferences = const CompanionPreferences();
  FinCharacterState _characterState = FinCharacterState.idle;
  FinActionPreview? _pendingAction;
  bool _isExecutingAction = false;
  String? _actionSuccessMessage;
  late final FinVisualController visualController = FinVisualController();

  String? _lastQuestion;

  bool get isLoading => _isLoading;
  bool get isTyping => _isTyping;
  String? get errorMessage => _errorMessage;
  bool get isRateLimited => _isRateLimited;
  bool get isOffline => _isOffline;
  String? get lastQuestion => _lastQuestion;

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

  // Phase 5E Getters
  CompanionPreferences get companionPreferences => _companionPreferences;
  FinCharacterState get characterState => _characterState;
  FinActionPreview? get pendingAction => _pendingAction;
  bool get isExecutingAction => _isExecutingAction;
  String? get actionSuccessMessage => _actionSuccessMessage;

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

    // Phase 5E Companion Reset
    _companionPreferences = const CompanionPreferences();
    _characterState = FinCharacterState.idle;
    _pendingAction = null;
    _isExecutingAction = false;
    _actionSuccessMessage = null;

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
    _characterState = FinCharacterState.idle;
    _pendingAction = null;
    _isExecutingAction = false;
    _actionSuccessMessage = null;
    notifyListeners();
  }

  /// Starts a normal companion-screen visit without carrying a transient
  /// operation pose over from the app-scoped provider's previous route visit.
  /// Conversation/results remain intact; only presentation/error flags reset.
  void prepareForScreenEntry() {
    if (_isLoading || _isExecutingAction) return;
    _characterState = FinCharacterState.idle;
    visualController.onIdle();
    _errorMessage = null;
    _isRateLimited = false;
    _isOffline = false;
    notifyListeners();
  }

  void setCharacterState(FinCharacterState state) {
    _characterState = state;
    visualController.setState(state);
    notifyListeners();
  }

  void setPendingAction(FinActionPreview? action) {
    _pendingAction = action;
    notifyListeners();
  }

  void clearPendingAction() {
    _pendingAction = null;
    notifyListeners();
  }

  Future<void> loadCompanionPreferences() async {
    try {
      final res = await _repository.getCompanionPreferences();
      var prefs = res.success ? res.data : _companionPreferences;

      try {
        final local = await CacheService.get('fin_companion_local_prefs').timeout(
          const Duration(milliseconds: 150),
          onTimeout: () => null,
        );
        if (local is Map<String, dynamic>) {
          prefs = prefs.copyWith(
            showAcrossApp: local['showAcrossApp'] as bool?,
            edgePosition: local['edgePosition'] as String?,
            proactiveHints: local['proactiveHints'] as bool?,
          );
        }
      } catch (_) {}

      _companionPreferences = prefs;
      visualController.setAnimationsEnabled(prefs.animationsEnabled);
      notifyListeners();
    } catch (_) {
      // Non-critical background fetch failure
    }
  }

  Future<bool> updateCompanionPreferences(CompanionPreferences prefs) async {
    try {
      try {
        await CacheService.save('fin_companion_local_prefs', {
          'showAcrossApp': prefs.showAcrossApp,
          'edgePosition': prefs.edgePosition,
          'proactiveHints': prefs.proactiveHints,
        }).timeout(const Duration(milliseconds: 150));
      } catch (_) {}

      final res = await _repository.updateCompanionPreferences(prefs);
      if (res.success) {
        _companionPreferences = res.data.copyWith(
          showAcrossApp: prefs.showAcrossApp,
          edgePosition: prefs.edgePosition,
          proactiveHints: prefs.proactiveHints,
        );
      } else {
        _companionPreferences = prefs;
      }
      visualController.setAnimationsEnabled(_companionPreferences.animationsEnabled);
      notifyListeners();
      return true;
    } catch (_) {
      _companionPreferences = prefs;
      visualController.setAnimationsEnabled(_companionPreferences.animationsEnabled);
      notifyListeners();
      return true;
    }
  }

  Future<bool> resetCompanionPreferences() async {
    try {
      try {
        await CacheService.remove('fin_companion_local_prefs').timeout(
          const Duration(milliseconds: 150),
        );
      } catch (_) {}
      final res = await _repository.resetCompanionPreferences();
      if (res.success) {
        _companionPreferences = res.data;
      } else {
        _companionPreferences = const CompanionPreferences();
      }
      visualController.setAnimationsEnabled(_companionPreferences.animationsEnabled);
      notifyListeners();
      return true;
    } catch (_) {}
    _companionPreferences = const CompanionPreferences();
    visualController.setAnimationsEnabled(true);
    notifyListeners();
    return true;
  }

  Future<bool> confirmPendingAction(FinActionPreview action) async {
    _isExecutingAction = true;
    _characterState = FinCharacterState.thinking;
    _errorMessage = null;
    _actionSuccessMessage = null;
    notifyListeners();

    try {
      final res = await _repository.confirmAction(
        action.capability,
        action.parameters,
      );

      if (res.success) {
        _pendingAction = null;
        _characterState = FinCharacterState.celebrating;
        _actionSuccessMessage = res.message;

        final confirmationMsg = ChatMessage(
          id: "a_conf_${DateTime.now().millisecondsSinceEpoch}",
          sender: MessageSender.assistant,
          text: res.message,
          timestamp: DateTime.now(),
          characterState: 'celebrating',
        );
        _messages.add(confirmationMsg);
        return true;
      } else {
        _characterState = FinCharacterState.error;
        _errorMessage = res.message;
        return false;
      }
    } on DioException catch (dioErr) {
      _characterState = FinCharacterState.error;
      _handleDioError(dioErr);
      return false;
    } catch (e) {
      _characterState = FinCharacterState.error;
      _errorMessage = "Failed to execute action. Please try again.";
      return false;
    } finally {
      _isExecutingAction = false;
      notifyListeners();
    }
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

    _lastQuestion = trimmed;

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
    _characterState = FinCharacterState.thinking;
    visualController.onQuerySubmitted(trimmed);
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
        if (res.data.actionPreview != null) {
          _pendingAction = res.data.actionPreview;
        }

        _characterState = FinCharacterState.fromString(res.data.characterState);
        visualController.setState(_characterState);

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
          characterState: res.data.characterState,
          actionPreview: res.data.actionPreview,
          navigationAction: res.data.navigationAction,
        );
        _messages.add(assistantMsg);
      } else {
        _characterState = FinCharacterState.error;
        _errorMessage = res.message;
        visualController.onError(res.message);
      }
    } on DioException catch (dioErr) {
      _characterState = FinCharacterState.error;
      _handleDioError(dioErr);
      visualController.onError(_errorMessage);
    } catch (e) {
      _characterState = FinCharacterState.error;
      _errorMessage = "Unable to process query. Please try again.";
      visualController.onError(_errorMessage);
    } finally {
      _isLoading = false;
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> retryLastQuestion() async {
    if (_lastQuestion != null && _lastQuestion!.isNotEmpty) {
      final q = _lastQuestion!;
      if (_messages.isNotEmpty &&
          _messages.last.sender == MessageSender.user &&
          _messages.last.text == q) {
        _messages.removeLast();
      }
      await askQuestion(q);
    }
  }

  Future<void> selectIntent(
    String intent, {
    String? period,
    String? category,
  }) async {
    _isLoading = true;
    _isTyping = true;
    _characterState = FinCharacterState.thinking;
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
        if (res.data.actionPreview != null) {
          _pendingAction = res.data.actionPreview;
        }

        _characterState = FinCharacterState.fromString(res.data.characterState);

        final assistantMsg = ChatMessage(
          id: "a_${DateTime.now().millisecondsSinceEpoch}",
          sender: MessageSender.assistant,
          text: res.data.answer,
          timestamp: DateTime.now(),
          result: res.data,
          isRefusal: res.data.isRefusal,
          clarificationOptions: res.data.clarificationOptions,
          followUpSuggestions: res.data.followUpSuggestions,
          characterState: res.data.characterState,
          actionPreview: res.data.actionPreview,
          navigationAction: res.data.navigationAction,
        );
        _messages.add(assistantMsg);
      } else {
        _characterState = FinCharacterState.error;
        _errorMessage = res.message;
      }
    } on DioException catch (dioErr) {
      _characterState = FinCharacterState.error;
      _handleDioError(dioErr);
    } catch (e) {
      _characterState = FinCharacterState.error;
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
            .map(
              (i) => AnalyticsInsightItem.fromJson(i as Map<String, dynamic>),
            )
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
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      _isOffline = true;
      _errorMessage = "Request timed out. Please check your connection and retry.";
    } else if (error.type == DioExceptionType.connectionError) {
      _isOffline = true;
      _errorMessage = "Offline Mode: Unable to connect to local server";
    } else if (error.response?.statusCode == 401) {
      _errorMessage = "Your session has expired. Please sign in again.";
    } else if (error.response?.statusCode == 403) {
      _errorMessage = "This question couldn't be processed due to privacy limits.";
    } else if (error.response?.statusCode == 400) {
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        _errorMessage = data['message'].toString();
      } else {
        _errorMessage = "Invalid query parameters.";
      }
    } else {
      _errorMessage = "I couldn't complete that analysis right now.";
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

  Future<void> askAlertQuestion(SmartAlertItem alert, String question) async {
    await askQuestion(
      question,
      period: alert.period?.label ?? 'current_month',
      category: alert.category,
    );
  }
}
