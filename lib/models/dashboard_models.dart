class DashboardSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  const DashboardSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalIncome: (json["totalIncome"] as num).toDouble(),
      totalExpense: (json["totalExpense"] as num).toDouble(),
      balance: (json["balance"] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "totalIncome": totalIncome,
      "totalExpense": totalExpense,
      "balance": balance,
    };
  }
}

class MonthlySummary {
  final String month; // e.g. "2026-08"
  final double income;
  final double expense;

  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expense,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      month: json["month"] as String,
      income: double.tryParse(json["income"].toString()) ?? 0.0,
      expense: double.tryParse(json["expense"].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "month": month,
      "income": income,
      "expense": expense,
    };
  }
}

class CategorySummary {
  final String name;
  final double total;

  const CategorySummary({
    required this.name,
    required this.total,
  });

  factory CategorySummary.fromJson(Map<String, dynamic> json) {
    return CategorySummary(
      name: json["name"] as String,
      total: double.tryParse(json["total"].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "total": total,
    };
  }
}
