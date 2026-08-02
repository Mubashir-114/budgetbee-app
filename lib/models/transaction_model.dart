class TransactionModel {
  final int id;
  final int userId;
  final int categoryId;
  final String type; // "income" or "expense"
  final String title;
  final double amount;
  final String transactionDate; // "YYYY-MM-DD"
  final String? note;
  final String category; // category name from Join
  final String? createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.type,
    required this.title,
    required this.amount,
    required this.transactionDate,
    this.note,
    required this.category,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json["id"] as int,
      userId: json["user_id"] as int,
      categoryId: json["category_id"] as int,
      type: json["type"] as String,
      title: json["title"] as String,
      amount: double.tryParse(json["amount"].toString()) ?? 0.0,
      transactionDate: json["transaction_date"] as String,
      note: json["note"] as String?,
      category: json["category"] as String,
      createdAt: json["created_at"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user_id": userId,
      "category_id": categoryId,
      "type": type,
      "title": title,
      "amount": amount,
      "transaction_date": transactionDate,
      "note": note,
      "category": category,
      "created_at": createdAt,
    };
  }

  TransactionModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    String? type,
    String? title,
    double? amount,
    String? transactionDate,
    String? note,
    String? category,
    String? createdAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TransactionResponse {
  final List<TransactionModel> transactions;
  final int total;
  final int page;
  final int limit;

  const TransactionResponse({
    required this.transactions,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final list = json["transactions"] as List;
    return TransactionResponse(
      transactions: list.map((item) => TransactionModel.fromJson(item)).toList(),
      total: json["total"] as int,
      page: json["page"] as int,
      limit: json["limit"] as int,
    );
  }
}
