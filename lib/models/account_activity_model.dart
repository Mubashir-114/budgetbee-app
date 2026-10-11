class AccountActivityModel {
  final String id;
  final String activityType; // "transaction" | "transfer" | "adjustment"
  final String type; // "income" | "expense" | "transfer_in" | "transfer_out" | "adjustment_credit" | "adjustment_debit"
  final String title;
  final String amount;
  final String date;
  final String? note;
  final String? category;
  final String? createdAt;

  const AccountActivityModel({
    required this.id,
    required this.activityType,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    this.note,
    this.category,
    this.createdAt,
  });

  bool get isIncomeOrInflow =>
      type == 'income' || type == 'transfer_in' || type == 'adjustment_credit';

  factory AccountActivityModel.fromJson(Map<String, dynamic> json) {
    return AccountActivityModel(
      id: json['id'] as String? ?? '',
      activityType: json['activityType'] as String? ?? 'transaction',
      type: json['type'] as String? ?? 'expense',
      title: json['title'] as String? ?? '',
      amount: json['amount'] as String? ?? '0.00',
      date: json['date'] as String? ?? '',
      note: json['note'] as String?,
      category: json['category'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType,
      'type': type,
      'title': title,
      'amount': amount,
      'date': date,
      'note': note,
      'category': category,
      'createdAt': createdAt,
    };
  }
}

class AccountActivityListResponse {
  final List<AccountActivityModel> activities;
  final int total;
  final int page;
  final int limit;

  const AccountActivityListResponse({
    required this.activities,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory AccountActivityListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['activities'] as List<dynamic>?) ?? [];
    return AccountActivityListResponse(
      activities: list
          .map((item) => AccountActivityModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
