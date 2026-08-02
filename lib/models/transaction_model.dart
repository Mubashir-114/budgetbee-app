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
  final String source; // "manual" or "sms"
  final String? bank;
  final String? sender;
  final String? referenceNumber;
  final String? smsHash;

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
    required this.source,
    this.bank,
    this.sender,
    this.referenceNumber,
    this.smsHash,
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
      source: json["source"] as String? ?? 'manual',
      bank: json["bank"] as String?,
      sender: json["sender"] as String?,
      referenceNumber: json["reference_number"] as String?,
      smsHash: json["sms_hash"] as String?,
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
      "source": source,
      "bank": bank,
      "sender": sender,
      "reference_number": referenceNumber,
      "sms_hash": smsHash,
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
    String? source,
    String? bank,
    String? sender,
    String? referenceNumber,
    String? smsHash,
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
      source: source ?? this.source,
      bank: bank ?? this.bank,
      sender: sender ?? this.sender,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      smsHash: smsHash ?? this.smsHash,
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
