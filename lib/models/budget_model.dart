class BudgetModel {
  final int id;
  final int userId;
  final int categoryId;
  final String category;
  final String categoryType;
  final double amount;
  final int month;
  final int year;
  final String? createdAt;

  const BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.category,
    required this.categoryType,
    required this.amount,
    required this.month,
    required this.year,
    this.createdAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json["id"] as int,
      userId: json["user_id"] as int,
      categoryId: json["category_id"] as int,
      category: json["category"] as String,
      categoryType: json["category_type"] as String,
      amount: double.tryParse(json["amount"].toString()) ?? 0.0,
      month: json["month"] as int,
      year: json["year"] as int,
      createdAt: json["created_at"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "category_id": categoryId,
      "category": category,
      "category_type": categoryType,
      "amount": amount,
      "month": month,
      "year": year,
      "created_at": createdAt,
    };
  }

  BudgetModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? category,
    String? categoryType,
    double? amount,
    int? month,
    int? year,
    String? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      categoryType: categoryType ?? this.categoryType,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BudgetStatusModel {
  final int budgetId;
  final int categoryId;
  final String category;
  final double budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final String status; // "over_budget" or "safe"

  const BudgetStatusModel({
    required this.budgetId,
    required this.categoryId,
    required this.category,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.status,
  });

  factory BudgetStatusModel.fromJson(Map<String, dynamic> json) {
    return BudgetStatusModel(
      budgetId: json["budgetId"] as int,
      categoryId: json["categoryId"] as int,
      category: json["category"] as String,
      budget: (json["budget"] as num).toDouble(),
      spent: (json["spent"] as num).toDouble(),
      remaining: (json["remaining"] as num).toDouble(),
      percentageUsed: (json["percentageUsed"] as num).toDouble(),
      status: json["status"] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "budgetId": budgetId,
      "categoryId": categoryId,
      "category": category,
      "budget": budget,
      "spent": spent,
      "remaining": remaining,
      "percentageUsed": percentageUsed,
      "status": status,
    };
  }
}

// ============================================================================
// Phase 3D: Smart Budget Real-Time Progress, Alerts, and Suggestions Models
// ============================================================================

class BudgetOverallProgressModel {
  final String budgetLimit;
  final String actualSpending;
  final String remainingAmount;
  final String utilizationPercentage;
  final String dailyBurnRate;
  final String projectedSpending;
  final String status; // "on_track", "approaching_limit", "exceeded"
  final bool hasBudgetsDefined;

  const BudgetOverallProgressModel({
    required this.budgetLimit,
    required this.actualSpending,
    required this.remainingAmount,
    required this.utilizationPercentage,
    required this.dailyBurnRate,
    required this.projectedSpending,
    required this.status,
    required this.hasBudgetsDefined,
  });

  factory BudgetOverallProgressModel.fromJson(Map<String, dynamic> json) {
    return BudgetOverallProgressModel(
      budgetLimit: json["budgetLimit"]?.toString() ?? "0.00",
      actualSpending: json["actualSpending"]?.toString() ?? "0.00",
      remainingAmount: json["remainingAmount"]?.toString() ?? "0.00",
      utilizationPercentage: json["utilizationPercentage"]?.toString() ?? "0.0",
      dailyBurnRate: json["dailyBurnRate"]?.toString() ?? "0.00",
      projectedSpending: json["projectedSpending"]?.toString() ?? "0.00",
      status: json["status"]?.toString() ?? "on_track",
      hasBudgetsDefined: json["hasBudgetsDefined"] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "budgetLimit": budgetLimit,
      "actualSpending": actualSpending,
      "remainingAmount": remainingAmount,
      "utilizationPercentage": utilizationPercentage,
      "dailyBurnRate": dailyBurnRate,
      "projectedSpending": projectedSpending,
      "status": status,
      "hasBudgetsDefined": hasBudgetsDefined,
    };
  }
}

class BudgetCategoryProgressModel {
  final int budgetId;
  final int categoryId;
  final String category;
  final String categoryType;
  final String budgetLimit;
  final String actualSpending;
  final String remainingAmount;
  final String utilizationPercentage;
  final String projectedSpending;
  final String status; // "on_track", "approaching_limit", "exceeded"
  final int daysRemaining;

  const BudgetCategoryProgressModel({
    required this.budgetId,
    required this.categoryId,
    required this.category,
    required this.categoryType,
    required this.budgetLimit,
    required this.actualSpending,
    required this.remainingAmount,
    required this.utilizationPercentage,
    required this.projectedSpending,
    required this.status,
    required this.daysRemaining,
  });

  factory BudgetCategoryProgressModel.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryProgressModel(
      budgetId: json["budgetId"] as int,
      categoryId: json["categoryId"] as int,
      category: json["category"] as String? ?? "Category",
      categoryType: json["categoryType"] as String? ?? "expense",
      budgetLimit: json["budgetLimit"]?.toString() ?? "0.00",
      actualSpending: json["actualSpending"]?.toString() ?? "0.00",
      remainingAmount: json["remainingAmount"]?.toString() ?? "0.00",
      utilizationPercentage: json["utilizationPercentage"]?.toString() ?? "0.0",
      projectedSpending: json["projectedSpending"]?.toString() ?? "0.00",
      status: json["status"]?.toString() ?? "on_track",
      daysRemaining: json["daysRemaining"] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "budgetId": budgetId,
      "categoryId": categoryId,
      "category": category,
      "categoryType": categoryType,
      "budgetLimit": budgetLimit,
      "actualSpending": actualSpending,
      "remainingAmount": remainingAmount,
      "utilizationPercentage": utilizationPercentage,
      "projectedSpending": projectedSpending,
      "status": status,
      "daysRemaining": daysRemaining,
    };
  }
}

class BudgetSavingsProgressModel {
  final String totalIncome;
  final String totalExpense;
  final String netSavings;
  final String projectedNetSavings;
  final String? savingsTarget;
  final String? progressPercentage;
  final bool isTargetAchieved;

  const BudgetSavingsProgressModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.projectedNetSavings,
    this.savingsTarget,
    this.progressPercentage,
    required this.isTargetAchieved,
  });

  factory BudgetSavingsProgressModel.fromJson(Map<String, dynamic> json) {
    return BudgetSavingsProgressModel(
      totalIncome: json["totalIncome"]?.toString() ?? "0.00",
      totalExpense: json["totalExpense"]?.toString() ?? "0.00",
      netSavings: json["netSavings"]?.toString() ?? "0.00",
      projectedNetSavings: json["projectedNetSavings"]?.toString() ?? "0.00",
      savingsTarget: json["savingsTarget"]?.toString(),
      progressPercentage: json["progressPercentage"]?.toString(),
      isTargetAchieved: json["isTargetAchieved"] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "totalIncome": totalIncome,
      "totalExpense": totalExpense,
      "netSavings": netSavings,
      "projectedNetSavings": projectedNetSavings,
      "savingsTarget": savingsTarget,
      "progressPercentage": progressPercentage,
      "isTargetAchieved": isTargetAchieved,
    };
  }
}

class BudgetPeriodModel {
  final int daysInMonth;
  final int daysElapsed;
  final int daysRemaining;
  final bool isCurrentPeriod;
  final String estimationMethod;

  const BudgetPeriodModel({
    required this.daysInMonth,
    required this.daysElapsed,
    required this.daysRemaining,
    required this.isCurrentPeriod,
    required this.estimationMethod,
  });

  factory BudgetPeriodModel.fromJson(Map<String, dynamic> json) {
    return BudgetPeriodModel(
      daysInMonth: json["daysInMonth"] as int? ?? 30,
      daysElapsed: json["daysElapsed"] as int? ?? 0,
      daysRemaining: json["daysRemaining"] as int? ?? 0,
      isCurrentPeriod: json["isCurrentPeriod"] as bool? ?? false,
      estimationMethod: json["estimationMethod"] as String? ?? "Linear Daily Burn-Rate",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "daysInMonth": daysInMonth,
      "daysElapsed": daysElapsed,
      "daysRemaining": daysRemaining,
      "isCurrentPeriod": isCurrentPeriod,
      "estimationMethod": estimationMethod,
    };
  }
}

class BudgetProgressResponseModel {
  final int month;
  final int year;
  final BudgetPeriodModel period;
  final BudgetOverallProgressModel overall;
  final List<BudgetCategoryProgressModel> categoryBudgets;
  final String uncategorizedSpending;
  final BudgetSavingsProgressModel savings;

  const BudgetProgressResponseModel({
    required this.month,
    required this.year,
    required this.period,
    required this.overall,
    required this.categoryBudgets,
    required this.uncategorizedSpending,
    required this.savings,
  });

  factory BudgetProgressResponseModel.fromJson(Map<String, dynamic> json) {
    final catList = json["categoryBudgets"] as List? ?? [];
    return BudgetProgressResponseModel(
      month: json["month"] as int,
      year: json["year"] as int,
      period: BudgetPeriodModel.fromJson(json["period"] as Map<String, dynamic>? ?? {}),
      overall: BudgetOverallProgressModel.fromJson(json["overall"] as Map<String, dynamic>? ?? {}),
      categoryBudgets: catList
          .map((item) => BudgetCategoryProgressModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      uncategorizedSpending: json["uncategorizedSpending"]?.toString() ?? "0.00",
      savings: BudgetSavingsProgressModel.fromJson(json["savings"] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "month": month,
      "year": year,
      "period": period.toJson(),
      "overall": overall.toJson(),
      "categoryBudgets": categoryBudgets.map((b) => b.toJson()).toList(),
      "uncategorizedSpending": uncategorizedSpending,
      "savings": savings.toJson(),
    };
  }
}

class BudgetAlertModel {
  final int? categoryId;
  final String? category;
  final String? budgetLimit;
  final String? actualSpending;
  final String? utilizationPercentage;
  final String severity; // "warning", "critical"
  final String message;

  const BudgetAlertModel({
    this.categoryId,
    this.category,
    this.budgetLimit,
    this.actualSpending,
    this.utilizationPercentage,
    required this.severity,
    required this.message,
  });

  factory BudgetAlertModel.fromJson(Map<String, dynamic> json) {
    return BudgetAlertModel(
      categoryId: json["categoryId"] as int?,
      category: json["category"] as String?,
      budgetLimit: json["budgetLimit"]?.toString(),
      actualSpending: json["actualSpending"]?.toString(),
      utilizationPercentage: json["utilizationPercentage"]?.toString(),
      severity: json["severity"] as String? ?? "warning",
      message: json["message"] as String? ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "categoryId": categoryId,
      "category": category,
      "budgetLimit": budgetLimit,
      "actualSpending": actualSpending,
      "utilizationPercentage": utilizationPercentage,
      "severity": severity,
      "message": message,
    };
  }
}

class BudgetInsightModel {
  final String type;
  final String title;
  final String message;

  const BudgetInsightModel({
    required this.type,
    required this.title,
    required this.message,
  });

  factory BudgetInsightModel.fromJson(Map<String, dynamic> json) {
    return BudgetInsightModel(
      type: json["type"] as String? ?? "info",
      title: json["title"] as String? ?? "Insight",
      message: json["message"] as String? ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "title": title,
      "message": message,
    };
  }
}

class BudgetAlertsResponseModel {
  final int month;
  final int year;
  final BudgetAlertModel? overallAlert;
  final List<BudgetAlertModel> approachingLimit;
  final List<BudgetAlertModel> exceeded;
  final List<BudgetInsightModel> insights;
  final int totalAlertsCount;

  const BudgetAlertsResponseModel({
    required this.month,
    required this.year,
    this.overallAlert,
    required this.approachingLimit,
    required this.exceeded,
    required this.insights,
    required this.totalAlertsCount,
  });

  factory BudgetAlertsResponseModel.fromJson(Map<String, dynamic> json) {
    final appList = json["approachingLimit"] as List? ?? [];
    final excList = json["exceeded"] as List? ?? [];
    final insList = json["insights"] as List? ?? [];

    return BudgetAlertsResponseModel(
      month: json["month"] as int,
      year: json["year"] as int,
      overallAlert: json["overallAlert"] != null
          ? BudgetAlertModel.fromJson(json["overallAlert"] as Map<String, dynamic>)
          : null,
      approachingLimit: appList
          .map((item) => BudgetAlertModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      exceeded: excList
          .map((item) => BudgetAlertModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      insights: insList
          .map((item) => BudgetInsightModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAlertsCount: json["totalAlertsCount"] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "month": month,
      "year": year,
      "overallAlert": overallAlert?.toJson(),
      "approachingLimit": approachingLimit.map((a) => a.toJson()).toList(),
      "exceeded": exceeded.map((a) => a.toJson()).toList(),
      "insights": insights.map((i) => i.toJson()).toList(),
      "totalAlertsCount": totalAlertsCount,
    };
  }
}

class BudgetHistoricalFactsModel {
  final String lastMonthSpent;
  final String twoMonthsAgoSpent;
  final String threeMonthsAgoSpent;
  final String threeMonthAverage;

  const BudgetHistoricalFactsModel({
    required this.lastMonthSpent,
    required this.twoMonthsAgoSpent,
    required this.threeMonthsAgoSpent,
    required this.threeMonthAverage,
  });

  factory BudgetHistoricalFactsModel.fromJson(Map<String, dynamic> json) {
    return BudgetHistoricalFactsModel(
      lastMonthSpent: json["lastMonthSpent"]?.toString() ?? "0.00",
      twoMonthsAgoSpent: json["twoMonthsAgoSpent"]?.toString() ?? "0.00",
      threeMonthsAgoSpent: json["threeMonthsAgoSpent"]?.toString() ?? "0.00",
      threeMonthAverage: json["threeMonthAverage"]?.toString() ?? "0.00",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "lastMonthSpent": lastMonthSpent,
      "twoMonthsAgoSpent": twoMonthsAgoSpent,
      "threeMonthsAgoSpent": threeMonthsAgoSpent,
      "threeMonthAverage": threeMonthAverage,
    };
  }
}

class BudgetEstimatesModel {
  final String trend; // "increasing", "decreasing", "stable"
  final String suggestedBudget;
  final String estimatedSavingsPotential;
  final String rationale;

  const BudgetEstimatesModel({
    required this.trend,
    required this.suggestedBudget,
    required this.estimatedSavingsPotential,
    required this.rationale,
  });

  factory BudgetEstimatesModel.fromJson(Map<String, dynamic> json) {
    return BudgetEstimatesModel(
      trend: json["trend"] as String? ?? "stable",
      suggestedBudget: json["suggestedBudget"]?.toString() ?? "0.00",
      estimatedSavingsPotential: json["estimatedSavingsPotential"]?.toString() ?? "0.00",
      rationale: json["rationale"] as String? ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "trend": trend,
      "suggestedBudget": suggestedBudget,
      "estimatedSavingsPotential": estimatedSavingsPotential,
      "rationale": rationale,
    };
  }
}

class BudgetSuggestionModel {
  final int categoryId;
  final String categoryName;
  final BudgetHistoricalFactsModel historicalFacts;
  final BudgetEstimatesModel estimates;
  final String? currentBudget;
  final bool isSuggestion;
  final bool isHistoricalFact;

  const BudgetSuggestionModel({
    required this.categoryId,
    required this.categoryName,
    required this.historicalFacts,
    required this.estimates,
    this.currentBudget,
    required this.isSuggestion,
    required this.isHistoricalFact,
  });

  factory BudgetSuggestionModel.fromJson(Map<String, dynamic> json) {
    return BudgetSuggestionModel(
      categoryId: json["categoryId"] as int,
      categoryName: json["categoryName"] as String? ?? "Category",
      historicalFacts: BudgetHistoricalFactsModel.fromJson(
        json["historicalFacts"] as Map<String, dynamic>? ?? {},
      ),
      estimates: BudgetEstimatesModel.fromJson(
        json["estimates"] as Map<String, dynamic>? ?? {},
      ),
      currentBudget: json["currentBudget"]?.toString(),
      isSuggestion: json["isSuggestion"] as bool? ?? true,
      isHistoricalFact: json["isHistoricalFact"] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "categoryId": categoryId,
      "categoryName": categoryName,
      "historicalFacts": historicalFacts.toJson(),
      "estimates": estimates.toJson(),
      "currentBudget": currentBudget,
      "isSuggestion": isSuggestion,
      "isHistoricalFact": isHistoricalFact,
    };
  }
}

class BudgetHistoryItemModel {
  final int month;
  final int year;
  final String totalBudget;
  final String totalSpent;
  final String variance;
  final String utilizationPercentage;
  final String status;
  final bool hasBudgetsDefined;
  final int categoryCount;

  const BudgetHistoryItemModel({
    required this.month,
    required this.year,
    required this.totalBudget,
    required this.totalSpent,
    required this.variance,
    required this.utilizationPercentage,
    required this.status,
    required this.hasBudgetsDefined,
    required this.categoryCount,
  });

  factory BudgetHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return BudgetHistoryItemModel(
      month: json["month"] as int,
      year: json["year"] as int,
      totalBudget: json["totalBudget"]?.toString() ?? "0.00",
      totalSpent: json["totalSpent"]?.toString() ?? "0.00",
      variance: json["variance"]?.toString() ?? "0.00",
      utilizationPercentage: json["utilizationPercentage"]?.toString() ?? "0.0",
      status: json["status"] as String? ?? "on_track",
      hasBudgetsDefined: json["hasBudgetsDefined"] as bool? ?? false,
      categoryCount: json["categoryCount"] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "month": month,
      "year": year,
      "totalBudget": totalBudget,
      "totalSpent": totalSpent,
      "variance": variance,
      "utilizationPercentage": utilizationPercentage,
      "status": status,
      "hasBudgetsDefined": hasBudgetsDefined,
      "categoryCount": categoryCount,
    };
  }
}
