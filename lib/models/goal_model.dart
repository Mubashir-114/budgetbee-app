class GoalContributionModel {
  final int id;
  final int goalId;
  final int userId;
  final double amount;
  final String contributionDate;
  final String? note;
  final String? createdAt;
  final String? updatedAt;

  const GoalContributionModel({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    required this.contributionDate,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  factory GoalContributionModel.fromJson(Map<String, dynamic> json) {
    return GoalContributionModel(
      id: json['id'] as int? ?? 0,
      goalId: json['goalId'] ?? json['goal_id'] as int? ?? 0,
      userId: json['userId'] ?? json['user_id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      contributionDate: json['contributionDate'] ?? json['contribution_date'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: json['createdAt'] ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] ?? json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'userId': userId,
      'amount': amount,
      'contributionDate': contributionDate,
      if (note != null) 'note': note,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

class GoalModel {
  final int id;
  final int userId;
  final String name;
  final String? description;
  final double targetAmount;
  final String currency;
  final String? targetDate;
  final double startingAmount;
  final double savedAmount;
  final double remainingAmount;
  final double progressPercentage;
  final String status; // active, completed, archived
  final int? daysRemaining;
  final double? monthsRemaining;
  final bool isOverdue;
  final double? requiredMonthlySaving;
  final String? estimatedCompletionDate;
  final String? estimationReason;
  final bool isEstimated;
  final String intelligenceStatus; // on_track, behind_schedule, completed, in_progress, archived
  final bool isAchieved;
  final int contributionsCount;
  final List<GoalContributionModel> recentContributions;
  final String? createdAt;
  final String? updatedAt;

  const GoalModel({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.targetAmount,
    this.currency = 'INR',
    this.targetDate,
    this.startingAmount = 0.0,
    required this.savedAmount,
    required this.remainingAmount,
    required this.progressPercentage,
    this.status = 'active',
    this.daysRemaining,
    this.monthsRemaining,
    this.isOverdue = false,
    this.requiredMonthlySaving,
    this.estimatedCompletionDate,
    this.estimationReason,
    this.isEstimated = false,
    this.intelligenceStatus = 'in_progress',
    this.isAchieved = false,
    this.contributionsCount = 0,
    this.recentContributions = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    final est = json['estimatedCompletion'] as Map<String, dynamic>?;
    final contributionsRaw = json['recentContributions'] as List<dynamic>?;
    final contributions = contributionsRaw != null
        ? contributionsRaw
            .map((e) => GoalContributionModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <GoalContributionModel>[];

    return GoalModel(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] ?? json['user_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      targetAmount: (json['targetAmount'] ?? json['target_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      targetDate: json['targetDate'] ?? json['target_date'] as String?,
      startingAmount: (json['startingAmount'] ?? json['starting_amount'] as num?)?.toDouble() ?? 0.0,
      savedAmount: (json['savedAmount'] ?? json['saved_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (json['remainingAmount'] ?? json['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      progressPercentage: (json['progressPercentage'] ?? json['progress_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'active',
      daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
      monthsRemaining: (json['monthsRemaining'] as num?)?.toDouble(),
      isOverdue: json['isOverdue'] as bool? ?? false,
      requiredMonthlySaving: (json['requiredMonthlySaving'] as num?)?.toDouble(),
      estimatedCompletionDate: est?['date'] as String?,
      estimationReason: est?['reason'] as String?,
      isEstimated: est?['isEstimated'] as bool? ?? false,
      intelligenceStatus: json['intelligenceStatus'] as String? ?? 'in_progress',
      isAchieved: json['isAchieved'] as bool? ?? false,
      contributionsCount: (json['contributionsCount'] ?? json['contributions_count'] as num?)?.toInt() ?? 0,
      recentContributions: contributions,
      createdAt: json['createdAt'] ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] ?? json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      if (description != null) 'description': description,
      'targetAmount': targetAmount,
      'currency': currency,
      if (targetDate != null) 'targetDate': targetDate,
      'startingAmount': startingAmount,
      'savedAmount': savedAmount,
      'remainingAmount': remainingAmount,
      'progressPercentage': progressPercentage,
      'status': status,
      if (daysRemaining != null) 'daysRemaining': daysRemaining,
      if (monthsRemaining != null) 'monthsRemaining': monthsRemaining,
      'isOverdue': isOverdue,
      if (requiredMonthlySaving != null) 'requiredMonthlySaving': requiredMonthlySaving,
      'estimatedCompletion': {
        'date': estimatedCompletionDate,
        'reason': estimationReason,
        'isEstimated': isEstimated,
      },
      'intelligenceStatus': intelligenceStatus,
      'isAchieved': isAchieved,
      'contributionsCount': contributionsCount,
      'recentContributions': recentContributions.map((c) => c.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  GoalModel copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    double? targetAmount,
    String? currency,
    String? targetDate,
    double? startingAmount,
    double? savedAmount,
    double? remainingAmount,
    double? progressPercentage,
    String? status,
    int? daysRemaining,
    double? monthsRemaining,
    bool? isOverdue,
    double? requiredMonthlySaving,
    String? estimatedCompletionDate,
    String? estimationReason,
    bool? isEstimated,
    String? intelligenceStatus,
    bool? isAchieved,
    int? contributionsCount,
    List<GoalContributionModel>? recentContributions,
    String? createdAt,
    String? updatedAt,
  }) {
    return GoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currency: currency ?? this.currency,
      targetDate: targetDate ?? this.targetDate,
      startingAmount: startingAmount ?? this.startingAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      status: status ?? this.status,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      monthsRemaining: monthsRemaining ?? this.monthsRemaining,
      isOverdue: isOverdue ?? this.isOverdue,
      requiredMonthlySaving: requiredMonthlySaving ?? this.requiredMonthlySaving,
      estimatedCompletionDate: estimatedCompletionDate ?? this.estimatedCompletionDate,
      estimationReason: estimationReason ?? this.estimationReason,
      isEstimated: isEstimated ?? this.isEstimated,
      intelligenceStatus: intelligenceStatus ?? this.intelligenceStatus,
      isAchieved: isAchieved ?? this.isAchieved,
      contributionsCount: contributionsCount ?? this.contributionsCount,
      recentContributions: recentContributions ?? this.recentContributions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GoalsSummaryModel {
  final double totalTarget;
  final double totalSaved;
  final double totalRemaining;
  final double overallProgressPercentage;
  final int activeGoalsCount;
  final int completedGoalsCount;
  final int archivedGoalsCount;
  final int totalGoalsCount;

  const GoalsSummaryModel({
    required this.totalTarget,
    required this.totalSaved,
    required this.totalRemaining,
    required this.overallProgressPercentage,
    required this.activeGoalsCount,
    required this.completedGoalsCount,
    required this.archivedGoalsCount,
    required this.totalGoalsCount,
  });

  factory GoalsSummaryModel.fromJson(Map<String, dynamic> json) {
    return GoalsSummaryModel(
      totalTarget: (json['totalTarget'] as num?)?.toDouble() ?? 0.0,
      totalSaved: (json['totalSaved'] as num?)?.toDouble() ?? 0.0,
      totalRemaining: (json['totalRemaining'] as num?)?.toDouble() ?? 0.0,
      overallProgressPercentage: (json['overallProgressPercentage'] as num?)?.toDouble() ?? 0.0,
      activeGoalsCount: (json['activeGoalsCount'] as num?)?.toInt() ?? 0,
      completedGoalsCount: (json['completedGoalsCount'] as num?)?.toInt() ?? 0,
      archivedGoalsCount: (json['archivedGoalsCount'] as num?)?.toInt() ?? 0,
      totalGoalsCount: (json['totalGoalsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTarget': totalTarget,
      'totalSaved': totalSaved,
      'totalRemaining': totalRemaining,
      'overallProgressPercentage': overallProgressPercentage,
      'activeGoalsCount': activeGoalsCount,
      'completedGoalsCount': completedGoalsCount,
      'archivedGoalsCount': archivedGoalsCount,
      'totalGoalsCount': totalGoalsCount,
    };
  }
}

class CashFlowForecastModel {
  final String horizon;
  final int horizonMonths;
  final int historicalMonthsSampled;
  final double historicalAvgMonthlyIncome;
  final double historicalAvgMonthlyExpense;
  final double netMonthlyCashFlow;
  final double potentialMonthlySavingsCapacity;
  final double projectedIncome;
  final double projectedExpenses;
  final double projectedNetCashFlow;
  final double projectedSavingsCapacity;
  final bool isSufficient;
  final List<String> warnings;
  final String? samplePeriod;
  final int recordCount;
  final List<String> assumptions;

  const CashFlowForecastModel({
    required this.horizon,
    required this.horizonMonths,
    required this.historicalMonthsSampled,
    required this.historicalAvgMonthlyIncome,
    required this.historicalAvgMonthlyExpense,
    required this.netMonthlyCashFlow,
    required this.potentialMonthlySavingsCapacity,
    required this.projectedIncome,
    required this.projectedExpenses,
    required this.projectedNetCashFlow,
    required this.projectedSavingsCapacity,
    required this.isSufficient,
    required this.warnings,
    this.samplePeriod,
    required this.recordCount,
    required this.assumptions,
  });

  factory CashFlowForecastModel.fromJson(Map<String, dynamic> json) {
    final suff = json['dataSufficiency'] as Map<String, dynamic>?;
    final warningsRaw = suff?['warnings'] as List<dynamic>?;
    final assumptionsRaw = json['assumptions'] as List<dynamic>?;

    return CashFlowForecastModel(
      horizon: json['horizon'] as String? ?? 'next_3_months',
      horizonMonths: (json['horizonMonths'] as num?)?.toInt() ?? 3,
      historicalMonthsSampled: (json['historicalMonthsSampled'] as num?)?.toInt() ?? 0,
      historicalAvgMonthlyIncome: (json['historicalAvgMonthlyIncome'] as num?)?.toDouble() ?? 0.0,
      historicalAvgMonthlyExpense: (json['historicalAvgMonthlyExpense'] as num?)?.toDouble() ?? 0.0,
      netMonthlyCashFlow: (json['netMonthlyCashFlow'] as num?)?.toDouble() ?? 0.0,
      potentialMonthlySavingsCapacity: (json['potentialMonthlySavingsCapacity'] as num?)?.toDouble() ?? 0.0,
      projectedIncome: (json['projectedIncome'] as num?)?.toDouble() ?? 0.0,
      projectedExpenses: (json['projectedExpenses'] as num?)?.toDouble() ?? 0.0,
      projectedNetCashFlow: (json['projectedNetCashFlow'] as num?)?.toDouble() ?? 0.0,
      projectedSavingsCapacity: (json['projectedSavingsCapacity'] as num?)?.toDouble() ?? 0.0,
      isSufficient: suff?['isSufficient'] as bool? ?? false,
      warnings: warningsRaw != null ? warningsRaw.map((e) => e.toString()).toList() : [],
      samplePeriod: suff?['samplePeriod'] as String?,
      recordCount: (suff?['recordCount'] as num?)?.toInt() ?? 0,
      assumptions: assumptionsRaw != null ? assumptionsRaw.map((e) => e.toString()).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'horizon': horizon,
      'horizonMonths': horizonMonths,
      'historicalMonthsSampled': historicalMonthsSampled,
      'historicalAvgMonthlyIncome': historicalAvgMonthlyIncome,
      'historicalAvgMonthlyExpense': historicalAvgMonthlyExpense,
      'netMonthlyCashFlow': netMonthlyCashFlow,
      'potentialMonthlySavingsCapacity': potentialMonthlySavingsCapacity,
      'projectedIncome': projectedIncome,
      'projectedExpenses': projectedExpenses,
      'projectedNetCashFlow': projectedNetCashFlow,
      'projectedSavingsCapacity': projectedSavingsCapacity,
      'dataSufficiency': {
        'isSufficient': isSufficient,
        'warnings': warnings,
        'samplePeriod': samplePeriod,
        'recordCount': recordCount,
      },
      'assumptions': assumptions,
    };
  }
}

class WhatIfSimulationModel {
  final String scenarioType;
  final double baselineIncome;
  final double baselineExpense;
  final double baselineNetCashFlow;
  final double baselineSavingsCapacity;
  final String? baselineGoalName;
  final double? baselineGoalRemaining;
  final double? baselineOriginalMonths;
  final double simulatedIncome;
  final double simulatedExpense;
  final double simulatedNetCashFlow;
  final double simulatedSavingsCapacity;
  final double? simulatedMonths;
  final double? monthsSaved;
  final double? requiredMonthlySaving;
  final double monthlyDifference;
  final String explanation;
  final List<String> assumptions;

  const WhatIfSimulationModel({
    required this.scenarioType,
    required this.baselineIncome,
    required this.baselineExpense,
    required this.baselineNetCashFlow,
    required this.baselineSavingsCapacity,
    this.baselineGoalName,
    this.baselineGoalRemaining,
    this.baselineOriginalMonths,
    required this.simulatedIncome,
    required this.simulatedExpense,
    required this.simulatedNetCashFlow,
    required this.simulatedSavingsCapacity,
    this.simulatedMonths,
    this.monthsSaved,
    this.requiredMonthlySaving,
    required this.monthlyDifference,
    required this.explanation,
    required this.assumptions,
  });

  factory WhatIfSimulationModel.fromJson(Map<String, dynamic> json) {
    final base = json['baseline'] as Map<String, dynamic>? ?? {};
    final sim = json['simulated'] as Map<String, dynamic>? ?? {};
    final goal = base['goal'] as Map<String, dynamic>?;
    final timeline = sim['timelineImpact'] as Map<String, dynamic>?;
    final assumptionsRaw = json['assumptions'] as List<dynamic>?;

    return WhatIfSimulationModel(
      scenarioType: json['scenarioType'] as String? ?? 'savings_adjustment',
      baselineIncome: (base['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      baselineExpense: (base['monthlyExpense'] as num?)?.toDouble() ?? 0.0,
      baselineNetCashFlow: (base['netMonthlyCashFlow'] as num?)?.toDouble() ?? 0.0,
      baselineSavingsCapacity: (base['savingsCapacity'] as num?)?.toDouble() ?? 0.0,
      baselineGoalName: goal?['name'] as String?,
      baselineGoalRemaining: (goal?['remainingAmount'] as num?)?.toDouble(),
      baselineOriginalMonths: (goal?['originalMonthsRemaining'] as num?)?.toDouble(),
      simulatedIncome: (sim['monthlyIncome'] as num?)?.toDouble() ?? 0.0,
      simulatedExpense: (sim['monthlyExpense'] as num?)?.toDouble() ?? 0.0,
      simulatedNetCashFlow: (sim['netMonthlyCashFlow'] as num?)?.toDouble() ?? 0.0,
      simulatedSavingsCapacity: (sim['savingsCapacity'] as num?)?.toDouble() ?? 0.0,
      simulatedMonths: (timeline?['simulatedMonths'] as num?)?.toDouble(),
      monthsSaved: (timeline?['monthsSaved'] as num?)?.toDouble(),
      requiredMonthlySaving: (timeline?['requiredMonthlySaving'] as num?)?.toDouble(),
      monthlyDifference: (json['monthlyDifference'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
      assumptions: assumptionsRaw != null ? assumptionsRaw.map((e) => e.toString()).toList() : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scenarioType': scenarioType,
      'baseline': {
        'monthlyIncome': baselineIncome,
        'monthlyExpense': baselineExpense,
        'netMonthlyCashFlow': baselineNetCashFlow,
        'savingsCapacity': baselineSavingsCapacity,
        if (baselineGoalName != null)
          'goal': {
            'name': baselineGoalName,
            'remainingAmount': baselineGoalRemaining,
            'originalMonthsRemaining': baselineOriginalMonths,
          },
      },
      'simulated': {
        'monthlyIncome': simulatedIncome,
        'monthlyExpense': simulatedExpense,
        'netMonthlyCashFlow': simulatedNetCashFlow,
        'savingsCapacity': simulatedSavingsCapacity,
        'timelineImpact': {
          if (simulatedMonths != null) 'simulatedMonths': simulatedMonths,
          if (monthsSaved != null) 'monthsSaved': monthsSaved,
          if (requiredMonthlySaving != null) 'requiredMonthlySaving': requiredMonthlySaving,
        },
      },
      'monthlyDifference': monthlyDifference,
      'explanation': explanation,
      'assumptions': assumptions,
    };
  }
}
