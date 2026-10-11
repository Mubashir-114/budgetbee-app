class FinancialOverview {
  final String totalAssets;
  final String totalLiabilities;
  final String netWorth;
  final String monthlyIncome;
  final String monthlyExpenses;
  final String monthlyNetSavings;
  final String savingsRate;
  final String incomeChangePercent;
  final String expenseChangePercent;
  final String savingsChangePercent;

  const FinancialOverview({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlyNetSavings,
    this.savingsRate = '0.0',
    this.incomeChangePercent = '0.0',
    this.expenseChangePercent = '0.0',
    this.savingsChangePercent = '0.0',
  });

  factory FinancialOverview.fromJson(Map<String, dynamic> json) {
    final mom = json['monthOverMonth'] as Map<String, dynamic>? ?? {};
    return FinancialOverview(
      totalAssets: json['totalAssets']?.toString() ?? '0.00',
      totalLiabilities: json['totalLiabilities']?.toString() ?? '0.00',
      netWorth: json['netWorth']?.toString() ?? '0.00',
      monthlyIncome: json['monthlyIncome']?.toString() ?? '0.00',
      monthlyExpenses: json['monthlyExpenses']?.toString() ?? '0.00',
      monthlyNetSavings: json['monthlyNetSavings']?.toString() ?? '0.00',
      savingsRate: json['savingsRate']?.toString() ?? '0.0',
      incomeChangePercent: mom['incomeChangePercent']?.toString() ?? '0.0',
      expenseChangePercent: mom['expenseChangePercent']?.toString() ?? '0.0',
      savingsChangePercent: mom['savingsChangePercent']?.toString() ?? '0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAssets': totalAssets,
      'totalLiabilities': totalLiabilities,
      'netWorth': netWorth,
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'monthlyNetSavings': monthlyNetSavings,
      'savingsRate': savingsRate,
      'monthOverMonth': {
        'incomeChangePercent': incomeChangePercent,
        'expenseChangePercent': expenseChangePercent,
        'savingsChangePercent': savingsChangePercent,
      },
    };
  }
}

class DashboardAccountItem {
  final int id;
  final String displayName;
  final String type;
  final String? subtype;
  final String currencyCode;
  final String currentBalance;
  final bool isDefault;
  final String status;
  final bool isArchived;
  final String? assetPercentage;
  final String? creditLimit;
  final String? outstandingDebt;
  final String? availableCredit;
  final String? utilizationPercentage;
  final String? billingStatus;

  const DashboardAccountItem({
    required this.id,
    required this.displayName,
    required this.type,
    this.subtype,
    this.currencyCode = 'INR',
    required this.currentBalance,
    this.isDefault = false,
    this.status = 'active',
    this.isArchived = false,
    this.assetPercentage,
    this.creditLimit,
    this.outstandingDebt,
    this.availableCredit,
    this.utilizationPercentage,
    this.billingStatus,
  });

  factory DashboardAccountItem.fromJson(Map<String, dynamic> json) {
    return DashboardAccountItem(
      id: json['id'] as int? ?? 0,
      displayName: json['displayName'] as String? ?? '',
      type: json['type'] as String? ?? 'bank',
      subtype: json['subtype'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      currentBalance: json['currentBalance']?.toString() ?? '0.00',
      isDefault: json['isDefault'] == true || json['isDefault'] == 1,
      status: json['status'] as String? ?? 'active',
      isArchived: json['isArchived'] == true || json['status'] == 'archived',
      assetPercentage: json['assetPercentage']?.toString(),
      creditLimit: json['creditLimit']?.toString(),
      outstandingDebt: json['outstandingDebt']?.toString(),
      availableCredit: json['availableCredit']?.toString(),
      utilizationPercentage: json['utilizationPercentage']?.toString(),
      billingStatus: json['billingStatus'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'type': type,
      'subtype': subtype,
      'currencyCode': currencyCode,
      'currentBalance': currentBalance,
      'isDefault': isDefault,
      'status': status,
      'isArchived': isArchived,
      'assetPercentage': assetPercentage,
      'creditLimit': creditLimit,
      'outstandingDebt': outstandingDebt,
      'availableCredit': availableCredit,
      'utilizationPercentage': utilizationPercentage,
      'billingStatus': billingStatus,
    };
  }
}

class SpendingMerchant {
  final String merchant;
  final String total;
  final int count;
  final String percentage;

  const SpendingMerchant({
    required this.merchant,
    required this.total,
    required this.count,
    required this.percentage,
  });

  factory SpendingMerchant.fromJson(Map<String, dynamic> json) {
    return SpendingMerchant(
      merchant: json['merchant'] as String? ?? '',
      total: json['total']?.toString() ?? '0.00',
      count: json['count'] as int? ?? 0,
      percentage: json['percentage']?.toString() ?? '0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'total': total,
      'count': count,
      'percentage': percentage,
    };
  }
}

class DailyTrend {
  final String date;
  final String amount;
  final int count;

  const DailyTrend({
    required this.date,
    required this.amount,
    required this.count,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    return DailyTrend(
      date: json['date'] as String? ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'amount': amount,
      'count': count,
    };
  }
}

class FinancialInsight {
  final String type;
  final String message;

  const FinancialInsight({
    required this.type,
    required this.message,
  });

  factory FinancialInsight.fromJson(Map<String, dynamic> json) {
    return FinancialInsight(
      type: json['type'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'message': message,
    };
  }
}

class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int smsImportedToday;
  final int totalSmsImported;

  // Rich Dashboard 2.0 fields
  final FinancialOverview? overview;
  final List<DashboardAccountItem> accounts;
  final List<CategorySummary> categories;
  final List<CategorySummary> topCategories;
  final List<SpendingMerchant> topMerchants;
  final List<DailyTrend> dailyTrends;
  final List<FinancialInsight> insights;
  final String? selectedMonth;
  final String? periodType;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.smsImportedToday,
    required this.totalSmsImported,
    this.overview,
    this.accounts = const [],
    this.categories = const [],
    this.topCategories = const [],
    this.topMerchants = const [],
    this.dailyTrends = const [],
    this.insights = const [],
    this.selectedMonth,
    this.periodType,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final rawIncome = json['totalIncome'];
    final rawExpense = json['totalExpense'];
    final rawBalance = json['balance'];

    final overviewJson = json['overview'] as Map<String, dynamic>?;
    final overviewObj = overviewJson != null ? FinancialOverview.fromJson(overviewJson) : null;

    final accountsJson = json['accounts'] as Map<String, dynamic>?;
    final accountItems = (accountsJson?['items'] as List<dynamic>?)
            ?.map((a) => DashboardAccountItem.fromJson(a as Map<String, dynamic>))
            .toList() ??
        const [];

    final spendingJson = json['spending'] as Map<String, dynamic>?;
    final catList = (spendingJson?['byCategory'] as List<dynamic>?)
            ?.map((c) => CategorySummary.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const [];
    final topCatList = (spendingJson?['topCategories'] as List<dynamic>?)
            ?.map((c) => CategorySummary.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const [];
    final merchantList = (spendingJson?['topMerchants'] as List<dynamic>?)
            ?.map((m) => SpendingMerchant.fromJson(m as Map<String, dynamic>))
            .toList() ??
        const [];
    final trendsList = (spendingJson?['dailyTrends'] as List<dynamic>?)
            ?.map((d) => DailyTrend.fromJson(d as Map<String, dynamic>))
            .toList() ??
        const [];

    final insightsList = (json['insights'] as List<dynamic>?)
            ?.map((i) => FinancialInsight.fromJson(i as Map<String, dynamic>))
            .toList() ??
        const [];

    final periodJson = json['period'] as Map<String, dynamic>?;

    return DashboardSummary(
      totalIncome: (rawIncome is num) ? rawIncome.toDouble() : (double.tryParse(overviewObj?.monthlyIncome ?? '0') ?? 0.0),
      totalExpense: (rawExpense is num) ? rawExpense.toDouble() : (double.tryParse(overviewObj?.monthlyExpenses ?? '0') ?? 0.0),
      balance: (rawBalance is num) ? rawBalance.toDouble() : (double.tryParse(overviewObj?.monthlyNetSavings ?? '0') ?? 0.0),
      smsImportedToday: json['smsImportedToday'] as int? ?? 0,
      totalSmsImported: json['totalSmsImported'] as int? ?? 0,
      overview: overviewObj,
      accounts: accountItems,
      categories: catList,
      topCategories: topCatList,
      topMerchants: merchantList,
      dailyTrends: trendsList,
      insights: insightsList,
      selectedMonth: periodJson?['selectedMonth'] as String?,
      periodType: periodJson?['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
      'smsImportedToday': smsImportedToday,
      'totalSmsImported': totalSmsImported,
      'overview': overview?.toJson(),
      'accounts': {
        'items': accounts.map((a) => a.toJson()).toList(),
      },
      'spending': {
        'byCategory': categories.map((c) => c.toJson()).toList(),
        'topCategories': topCategories.map((c) => c.toJson()).toList(),
        'topMerchants': topMerchants.map((m) => m.toJson()).toList(),
        'dailyTrends': dailyTrends.map((d) => d.toJson()).toList(),
      },
      'insights': insights.map((i) => i.toJson()).toList(),
      'period': {
        'selectedMonth': selectedMonth,
        'type': periodType,
      },
    };
  }
}

class MonthlySummary {
  final String month; // e.g. "2026-08"
  final double income;
  final double expense;
  final String? incomeString;
  final String? expenseString;
  final String? netSavingsString;

  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expense,
    this.incomeString,
    this.expenseString,
    this.netSavingsString,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json['month'] as String? ?? '',
      income: double.tryParse(json['income'].toString()) ?? 0.0,
      expense: double.tryParse(json['expense'].toString()) ?? 0.0,
      incomeString: json['income']?.toString(),
      expenseString: json['expense']?.toString(),
      netSavingsString: json['netSavings']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'income': income,
      'expense': expense,
      if (incomeString != null) 'incomeString': incomeString,
      if (expenseString != null) 'expenseString': expenseString,
      if (netSavingsString != null) 'netSavingsString': netSavingsString,
    };
  }
}

class CategorySummary {
  final int? id;
  final String name;
  final double total;
  final String? totalString;
  final String? percentage;
  final String? icon;
  final String? color;

  const CategorySummary({
    this.id,
    required this.name,
    required this.total,
    this.totalString,
    this.percentage,
    this.icon,
    this.color,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total'];
    return CategorySummary(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Uncategorized',
      total: double.tryParse(rawTotal.toString()) ?? 0.0,
      totalString: rawTotal?.toString(),
      percentage: json['percentage']?.toString(),
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'total': total,
      if (totalString != null) 'totalString': totalString,
      if (percentage != null) 'percentage': percentage,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
    };
  }
}
