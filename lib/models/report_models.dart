class ReportSummary {
  final double totalIncome;
  final double totalExpense;
  final double netBalance;
  final double savingsRate;
  final int totalTransactions;

  const ReportSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.savingsRate,
    required this.totalTransactions,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalIncome: (json["totalIncome"] as num).toDouble(),
      totalExpense: (json["totalExpense"] as num).toDouble(),
      netBalance: (json["netBalance"] as num).toDouble(),
      savingsRate: (json["savingsRate"] as num).toDouble(),
      totalTransactions: json["totalTransactions"] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "totalIncome": totalIncome,
      "totalExpense": totalExpense,
      "netBalance": netBalance,
      "savingsRate": savingsRate,
      "totalTransactions": totalTransactions,
    };
  }
}

class MonthlyReport {
  final int year;
  final int month;
  final String monthName;
  final double income;
  final double expense;
  final double balance;

  const MonthlyReport({
    required this.year,
    required this.month,
    required this.monthName,
    required this.income,
    required this.expense,
    required this.balance,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      year: json["year"] as int,
      month: json["month"] as int,
      monthName: json["monthName"] as String,
      income: (json["income"] as num).toDouble(),
      expense: (json["expense"] as num).toDouble(),
      balance: (json["balance"] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "year": year,
      "month": month,
      "monthName": monthName,
      "income": income,
      "expense": expense,
      "balance": balance,
    };
  }
}

class CategoryReport {
  final int categoryId;
  final String category;
  final double budget;
  final double spent;
  final double remaining;
  final double percentage;

  const CategoryReport({
    required this.categoryId,
    required this.category,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
  });

  factory CategoryReport.fromJson(Map<String, dynamic> json) {
    return CategoryReport(
      categoryId: json["categoryId"] as int,
      category: json["category"] as String,
      budget: (json["budget"] as num).toDouble(),
      spent: (json["spent"] as num).toDouble(),
      remaining: (json["remaining"] as num).toDouble(),
      percentage: (json["percentage"] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "categoryId": categoryId,
      "category": category,
      "budget": budget,
      "spent": spent,
      "remaining": remaining,
      "percentage": percentage,
    };
  }
}

class TrendsReport {
  final int year;
  final int month;
  final String monthName;
  final double income;
  final double expense;

  const TrendsReport({
    required this.year,
    required this.month,
    required this.monthName,
    required this.income,
    required this.expense,
  });

  factory TrendsReport.fromJson(Map<String, dynamic> json) {
    return TrendsReport(
      year: json["year"] as int,
      month: json["month"] as int,
      monthName: json["monthName"] as String,
      income: (json["income"] as num).toDouble(),
      expense: (json["expense"] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "year": year,
      "month": month,
      "monthName": monthName,
      "income": income,
      "expense": expense,
    };
  }
}

class CashflowReport {
  final int id;
  final String title;
  final String category;
  final double amount;
  final String type; // "income" or "expense"
  final String date; // YYYY-MM-DD
  final double runningBalance;

  const CashflowReport({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.type,
    required this.date,
    required this.runningBalance,
  });

  factory CashflowReport.fromJson(Map<String, dynamic> json) {
    return CashflowReport(
      id: json["id"] as int,
      title: json["title"] as String,
      category: json["category"] as String,
      amount: (json["amount"] as num).toDouble(),
      type: json["type"] as String,
      date: json["date"] as String,
      runningBalance: (json["runningBalance"] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "category": category,
      "amount": amount,
      "type": type,
      "date": date,
      "runningBalance": runningBalance,
    };
  }
}
