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
