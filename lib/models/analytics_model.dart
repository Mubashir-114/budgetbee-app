class SuggestedQuestion {
  final String intent;
  final String question;
  final String label;

  const SuggestedQuestion({
    required this.intent,
    required this.question,
    required this.label,
  });

  factory SuggestedQuestion.fromJson(Map<String, dynamic> json) {
    return SuggestedQuestion(
      intent: json['intent'] as String? ?? '',
      question: json['question'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'intent': intent,
    'question': question,
    'label': label,
  };
}

class ClarificationOption {
  final String label;
  final String question;

  const ClarificationOption({
    required this.label,
    required this.question,
  });

  factory ClarificationOption.fromJson(Map<String, dynamic> json) {
    return ClarificationOption(
      label: json['label'] as String? ?? '',
      question: json['question'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'question': question,
  };
}

class ConversationContext {
  final String? previousIntent;
  final String? activePeriod;
  final String? activeCategory;
  final String? activeMonth;
  final int turnCount;

  const ConversationContext({
    this.previousIntent,
    this.activePeriod,
    this.activeCategory,
    this.activeMonth,
    this.turnCount = 0,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      previousIntent: json['previousIntent'] as String?,
      activePeriod: json['activePeriod'] as String?,
      activeCategory: json['activeCategory'] as String?,
      activeMonth: json['activeMonth'] as String?,
      turnCount: (json['turnCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    if (previousIntent != null) 'previousIntent': previousIntent,
    if (activePeriod != null) 'activePeriod': activePeriod,
    if (activeCategory != null) 'activeCategory': activeCategory,
    if (activeMonth != null) 'activeMonth': activeMonth,
    'turnCount': turnCount,
  };

  ConversationContext copyWith({
    String? previousIntent,
    String? activePeriod,
    String? activeCategory,
    String? activeMonth,
    int? turnCount,
  }) {
    return ConversationContext(
      previousIntent: previousIntent ?? this.previousIntent,
      activePeriod: activePeriod ?? this.activePeriod,
      activeCategory: activeCategory ?? this.activeCategory,
      activeMonth: activeMonth ?? this.activeMonth,
      turnCount: turnCount ?? this.turnCount,
    );
  }
}

class AnalyticsCapability {
  final List<String> supportedIntents;
  final List<SuggestedQuestion> suggestedQuestions;
  final int maxDateRangeDays;
  final int maxQuestionLength;
  final bool readOnly;
  final String privacyNotice;

  const AnalyticsCapability({
    required this.supportedIntents,
    required this.suggestedQuestions,
    required this.maxDateRangeDays,
    required this.maxQuestionLength,
    required this.readOnly,
    required this.privacyNotice,
  });

  factory AnalyticsCapability.fromJson(Map<String, dynamic> json) {
    final constraints = json['constraints'] as Map<String, dynamic>? ?? {};
    final questionsList = (json['suggestedQuestions'] as List<dynamic>? ?? [])
        .map((q) => SuggestedQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return AnalyticsCapability(
      supportedIntents: (json['supportedIntents'] as List<dynamic>? ?? [])
          .map((i) => i.toString())
          .toList(),
      suggestedQuestions: questionsList,
      maxDateRangeDays: constraints['maxDateRangeDays'] as int? ?? 365,
      maxQuestionLength: constraints['maxQuestionLength'] as int? ?? 200,
      readOnly: constraints['readOnly'] as bool? ?? true,
      privacyNotice: json['privacyNotice'] as String? ?? '',
    );
  }
}

class AnalyticsPeriod {
  final String startDate;
  final String endDate;
  final String label;

  const AnalyticsPeriod({
    required this.startDate,
    required this.endDate,
    required this.label,
  });

  factory AnalyticsPeriod.fromJson(Map<String, dynamic> json) {
    return AnalyticsPeriod(
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }
}

class AnalyticsProvenance {
  final int recordCount;
  final String startDate;
  final String endDate;
  final String disclaimer;
  final String privacyNotice;

  const AnalyticsProvenance({
    required this.recordCount,
    required this.startDate,
    required this.endDate,
    required this.disclaimer,
    required this.privacyNotice,
  });

  factory AnalyticsProvenance.fromJson(Map<String, dynamic> json) {
    return AnalyticsProvenance(
      recordCount: (json['recordCount'] as num?)?.toInt() ?? 0,
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      disclaimer: json['disclaimer'] as String? ?? '',
      privacyNotice: json['privacyNotice'] as String? ?? '',
    );
  }
}

class CategorySpendingItem {
  final int id;
  final String name;
  final double total;
  final int count;
  final String percentage;

  const CategorySpendingItem({
    required this.id,
    required this.name,
    required this.total,
    required this.count,
    required this.percentage,
  });

  factory CategorySpendingItem.fromJson(Map<String, dynamic> json) {
    return CategorySpendingItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? 'Uncategorized',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: json['percentage']?.toString() ?? '0.0',
    );
  }
}

class AnalyticsBudgetItem {
  final int budgetId;
  final int categoryId;
  final String categoryName;
  final double budgetLimit;
  final double spent;
  final double remaining;
  final String percentage;
  final String status;

  const AnalyticsBudgetItem({
    required this.budgetId,
    required this.categoryId,
    required this.categoryName,
    required this.budgetLimit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
  });

  factory AnalyticsBudgetItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsBudgetItem(
      budgetId: (json['budgetId'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      budgetLimit: (json['budgetLimit'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      percentage: json['percentage']?.toString() ?? '0.0',
      status: json['status'] as String? ?? 'on_track',
    );
  }
}

class AnalyticsLargestExpenseItem {
  final int id;
  final String title;
  final double amount;
  final String date;
  final String category;

  const AnalyticsLargestExpenseItem({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  factory AnalyticsLargestExpenseItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsLargestExpenseItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }
}

class CategoryComparisonItem {
  final int id;
  final String name;
  final double currentTotal;
  final double previousTotal;
  final double difference;
  final String percentChange;
  final String direction;
  final int currentCount;
  final int previousCount;

  const CategoryComparisonItem({
    required this.id,
    required this.name,
    required this.currentTotal,
    required this.previousTotal,
    required this.difference,
    required this.percentChange,
    required this.direction,
    required this.currentCount,
    required this.previousCount,
  });

  factory CategoryComparisonItem.fromJson(Map<String, dynamic> json) {
    return CategoryComparisonItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      currentTotal: (json['currentTotal'] as num?)?.toDouble() ?? 0.0,
      previousTotal: (json['previousTotal'] as num?)?.toDouble() ?? 0.0,
      difference: (json['difference'] as num?)?.toDouble() ?? 0.0,
      percentChange: json['percentChange']?.toString() ?? '0.0',
      direction: json['direction'] as String? ?? 'unchanged',
      currentCount: (json['currentCount'] as num?)?.toInt() ?? 0,
      previousCount: (json['previousCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CategoryBudgetDetail {
  final String categoryName;
  final double budgetLimit;
  final double spent;
  final double remaining;
  final String percentage;
  final String status;

  const CategoryBudgetDetail({
    required this.categoryName,
    required this.budgetLimit,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.status,
  });

  factory CategoryBudgetDetail.fromJson(Map<String, dynamic> json) {
    return CategoryBudgetDetail(
      categoryName: json['categoryName'] as String? ?? '',
      budgetLimit: (json['budgetLimit'] as num?)?.toDouble() ?? 0.0,
      spent: (json['spent'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      percentage: json['percentage']?.toString() ?? '0.0',
      status: json['status'] as String? ?? 'on_track',
    );
  }
}

class UnusualSpendingIndicator {
  final String type;
  final String severity;
  final String title;
  final String description;
  final double amount;
  final String? category;

  const UnusualSpendingIndicator({
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.amount,
    this.category,
  });

  factory UnusualSpendingIndicator.fromJson(Map<String, dynamic> json) {
    return UnusualSpendingIndicator(
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String?,
    );
  }
}

class SavingsOpportunityItem {
  final String type;
  final String category;
  final double potentialSavings;
  final String reason;

  const SavingsOpportunityItem({
    required this.type,
    required this.category,
    required this.potentialSavings,
    required this.reason,
  });

  factory SavingsOpportunityItem.fromJson(Map<String, dynamic> json) {
    return SavingsOpportunityItem(
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      potentialSavings: (json['potentialSavings'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
    );
  }
}

class AnalyticsInsightItem {
  final String type;
  final String title;
  final String message;

  const AnalyticsInsightItem({
    required this.type,
    required this.title,
    required this.message,
  });

  factory AnalyticsInsightItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsInsightItem(
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }
}

class AnalyticsQueryResult {
  final String intent;
  final bool isRefusal;
  final String? refusalReason;
  final AnalyticsPeriod? period;
  final Map<String, dynamic>? metrics;
  final String answer;
  final AnalyticsProvenance? provenance;
  final String privacyNotice;
  final List<SuggestedQuestion> suggestions;
  final List<SuggestedQuestion> followUpSuggestions;
  final List<ClarificationOption> clarificationOptions;
  final String? confidence;
  final ConversationContext? conversationContext;

  const AnalyticsQueryResult({
    required this.intent,
    required this.isRefusal,
    this.refusalReason,
    this.period,
    this.metrics,
    required this.answer,
    this.provenance,
    required this.privacyNotice,
    required this.suggestions,
    this.followUpSuggestions = const [],
    this.clarificationOptions = const [],
    this.confidence,
    this.conversationContext,
  });

  factory AnalyticsQueryResult.fromJson(Map<String, dynamic> json) {
    final periodJson = json['period'] as Map<String, dynamic>?;
    final provenanceJson = json['provenance'] as Map<String, dynamic>?;
    final suggestionsList = (json['suggestions'] as List<dynamic>? ?? [])
        .map((s) => SuggestedQuestion.fromJson(s as Map<String, dynamic>))
        .toList();
    final followUpList = (json['followUpSuggestions'] as List<dynamic>? ?? [])
        .map((s) => SuggestedQuestion.fromJson(s as Map<String, dynamic>))
        .toList();
    final clarificationList = (json['clarificationOptions'] as List<dynamic>? ?? [])
        .map((c) => ClarificationOption.fromJson(c as Map<String, dynamic>))
        .toList();
    final contextJson = json['conversationContext'] as Map<String, dynamic>?;

    return AnalyticsQueryResult(
      intent: json['intent'] as String? ?? 'unsupported',
      isRefusal: json['isRefusal'] as bool? ?? false,
      refusalReason: json['refusalReason'] as String?,
      period: periodJson != null ? AnalyticsPeriod.fromJson(periodJson) : null,
      metrics: json['metrics'] as Map<String, dynamic>?,
      answer: json['answer'] as String? ?? '',
      provenance: provenanceJson != null ? AnalyticsProvenance.fromJson(provenanceJson) : null,
      privacyNotice: json['privacyNotice'] as String? ?? '',
      suggestions: suggestionsList,
      followUpSuggestions: followUpList.isNotEmpty ? followUpList : suggestionsList,
      clarificationOptions: clarificationList,
      confidence: json['confidence'] as String?,
      conversationContext: contextJson != null ? ConversationContext.fromJson(contextJson) : null,
    );
  }

  // Helper getters for structured metrics
  List<CategorySpendingItem> get categories {
    final list = metrics?['categories'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((c) => CategorySpendingItem.fromJson(c as Map<String, dynamic>)).toList();
  }

  List<AnalyticsBudgetItem> get budgetItems {
    final list = metrics?['items'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((b) => AnalyticsBudgetItem.fromJson(b as Map<String, dynamic>)).toList();
  }

  CategoryBudgetDetail? get categoryBudget {
    final map = metrics?['categoryBudget'] as Map<String, dynamic>?;
    if (map == null) return null;
    return CategoryBudgetDetail.fromJson(map);
  }

  List<CategoryComparisonItem> get comparisonCategories {
    final list = metrics?['categories'] as List<dynamic>?;
    if (list == null || intent != 'category_comparison') return [];
    return list.map((c) => CategoryComparisonItem.fromJson(c as Map<String, dynamic>)).toList();
  }

  CategoryComparisonItem? get largestIncrease {
    final map = metrics?['largestIncrease'] as Map<String, dynamic>?;
    if (map == null) return null;
    return CategoryComparisonItem.fromJson(map);
  }

  CategoryComparisonItem? get largestDecrease {
    final map = metrics?['largestDecrease'] as Map<String, dynamic>?;
    if (map == null) return null;
    return CategoryComparisonItem.fromJson(map);
  }

  List<UnusualSpendingIndicator> get unusualIndicators {
    final list = metrics?['indicators'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((i) => UnusualSpendingIndicator.fromJson(i as Map<String, dynamic>)).toList();
  }

  List<SavingsOpportunityItem> get savingsOpportunities {
    final list = metrics?['opportunities'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((o) => SavingsOpportunityItem.fromJson(o as Map<String, dynamic>)).toList();
  }

  List<AnalyticsLargestExpenseItem> get largestExpenses {
    final list = metrics?['largestExpenses'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => AnalyticsLargestExpenseItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}

enum MessageSender { user, assistant }

class ChatMessage {
  final String id;
  final MessageSender sender;
  final String text;
  final DateTime timestamp;
  final AnalyticsQueryResult? result;
  final bool isRefusal;
  final List<ClarificationOption> clarificationOptions;
  final List<SuggestedQuestion> followUpSuggestions;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.result,
    this.isRefusal = false,
    this.clarificationOptions = const [],
    this.followUpSuggestions = const [],
  });
}
