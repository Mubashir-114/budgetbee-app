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
  });

  factory AnalyticsQueryResult.fromJson(Map<String, dynamic> json) {
    final periodJson = json['period'] as Map<String, dynamic>?;
    final provenanceJson = json['provenance'] as Map<String, dynamic>?;
    final suggestionsList = (json['suggestions'] as List<dynamic>? ?? [])
        .map((s) => SuggestedQuestion.fromJson(s as Map<String, dynamic>))
        .toList();

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

  List<AnalyticsLargestExpenseItem> get largestExpenses {
    final list = metrics?['largestExpenses'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => AnalyticsLargestExpenseItem.fromJson(e as Map<String, dynamic>)).toList();
  }
}
