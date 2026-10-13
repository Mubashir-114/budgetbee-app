import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../models/analytics_model.dart';
import '../repositories/analytics_repository.dart';

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
}
