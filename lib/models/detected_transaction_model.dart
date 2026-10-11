class DetectedTransactionModel {
  final int id;
  final int userId;
  final int? accountId;
  final String? accountName;
  final int? categoryId;
  final String? categoryName;
  final String classification;
  final String amount;
  final String transactionDate;
  final String merchantRaw;
  final String merchantClean;
  final String? bank;
  final String? sender;
  final String? referenceNumber;
  final String? maskedAccountHint;
  final String smsHash;
  final double confidence;
  final String? confidenceReason;
  final int? suggestedAccountId;
  final String? suggestedAccountName;
  final int? suggestedCategoryId;
  final String? suggestedCategoryName;
  final bool isAccountAmbiguous;
  final String status; // "suggested" | "detected" | "confirmed" | "rejected"
  final String? rejectionReason;
  final int? confirmedTransactionId;
  final String? createdAt;
  final String? updatedAt;

  const DetectedTransactionModel({
    required this.id,
    required this.userId,
    this.accountId,
    this.accountName,
    this.categoryId,
    this.categoryName,
    required this.classification,
    required this.amount,
    required this.transactionDate,
    required this.merchantRaw,
    required this.merchantClean,
    this.bank,
    this.sender,
    this.referenceNumber,
    this.maskedAccountHint,
    required this.smsHash,
    required this.confidence,
    this.confidenceReason,
    this.suggestedAccountId,
    this.suggestedAccountName,
    this.suggestedCategoryId,
    this.suggestedCategoryName,
    required this.isAccountAmbiguous,
    required this.status,
    this.rejectionReason,
    this.confirmedTransactionId,
    this.createdAt,
    this.updatedAt,
  });

  factory DetectedTransactionModel.fromJson(Map<String, dynamic> json) {
    return DetectedTransactionModel(
      id: json['id'] as int,
      userId: json['userId'] as int? ?? json['user_id'] as int? ?? 0,
      accountId: json['accountId'] as int? ?? json['account_id'] as int?,
      accountName: json['accountName'] as String? ?? json['account_name'] as String?,
      categoryId: json['categoryId'] as int? ?? json['category_id'] as int?,
      categoryName: json['categoryName'] as String? ?? json['category_name'] as String?,
      classification: json['classification'] as String? ?? 'expense',
      amount: json['amount']?.toString() ?? '0.00',
      transactionDate: json['transactionDate'] as String? ?? json['transaction_date'] as String? ?? '',
      merchantRaw: json['merchantRaw'] as String? ?? json['merchant_raw'] as String? ?? '',
      merchantClean: json['merchantClean'] as String? ?? json['merchant_clean'] as String? ?? '',
      bank: json['bank'] as String?,
      sender: json['sender'] as String?,
      referenceNumber: json['referenceNumber'] as String? ?? json['reference_number'] as String?,
      maskedAccountHint: json['maskedAccountHint'] as String? ?? json['masked_account_hint'] as String?,
      smsHash: json['smsHash'] as String? ?? json['sms_hash'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      confidenceReason: json['confidenceReason'] as String? ?? json['confidence_reason'] as String?,
      suggestedAccountId: json['suggestedAccountId'] as int? ?? json['suggested_account_id'] as int?,
      suggestedAccountName: json['suggestedAccountName'] as String? ?? json['suggested_account_name'] as String?,
      suggestedCategoryId: json['suggestedCategoryId'] as int? ?? json['suggested_category_id'] as int?,
      suggestedCategoryName: json['suggestedCategoryName'] as String? ?? json['suggested_category_name'] as String?,
      isAccountAmbiguous: json['isAccountAmbiguous'] as bool? ?? json['is_account_ambiguous'] == 1 || json['is_account_ambiguous'] == true,
      status: json['status'] as String? ?? 'suggested',
      rejectionReason: json['rejectionReason'] as String? ?? json['rejection_reason'] as String?,
      confirmedTransactionId: json['confirmedTransactionId'] as int? ?? json['confirmed_transaction_id'] as int?,
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
      updatedAt: json['updatedAt'] as String? ?? json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'accountId': accountId,
      'accountName': accountName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'classification': classification,
      'amount': amount,
      'transactionDate': transactionDate,
      'merchantRaw': merchantRaw,
      'merchantClean': merchantClean,
      'bank': bank,
      'sender': sender,
      'referenceNumber': referenceNumber,
      'maskedAccountHint': maskedAccountHint,
      'smsHash': smsHash,
      'confidence': confidence,
      'confidenceReason': confidenceReason,
      'suggestedAccountId': suggestedAccountId,
      'suggestedAccountName': suggestedAccountName,
      'suggestedCategoryId': suggestedCategoryId,
      'suggestedCategoryName': suggestedCategoryName,
      'isAccountAmbiguous': isAccountAmbiguous,
      'status': status,
      'rejectionReason': rejectionReason,
      'confirmedTransactionId': confirmedTransactionId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  DetectedTransactionModel copyWith({
    int? id,
    int? userId,
    int? accountId,
    String? accountName,
    int? categoryId,
    String? categoryName,
    String? classification,
    String? amount,
    String? transactionDate,
    String? merchantRaw,
    String? merchantClean,
    String? bank,
    String? sender,
    String? referenceNumber,
    String? maskedAccountHint,
    String? smsHash,
    double? confidence,
    String? confidenceReason,
    int? suggestedAccountId,
    String? suggestedAccountName,
    int? suggestedCategoryId,
    String? suggestedCategoryName,
    bool? isAccountAmbiguous,
    String? status,
    String? rejectionReason,
    int? confirmedTransactionId,
  }) {
    return DetectedTransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      classification: classification ?? this.classification,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      merchantRaw: merchantRaw ?? this.merchantRaw,
      merchantClean: merchantClean ?? this.merchantClean,
      bank: bank ?? this.bank,
      sender: sender ?? this.sender,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      maskedAccountHint: maskedAccountHint ?? this.maskedAccountHint,
      smsHash: smsHash ?? this.smsHash,
      confidence: confidence ?? this.confidence,
      confidenceReason: confidenceReason ?? this.confidenceReason,
      suggestedAccountId: suggestedAccountId ?? this.suggestedAccountId,
      suggestedAccountName: suggestedAccountName ?? this.suggestedAccountName,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      suggestedCategoryName: suggestedCategoryName ?? this.suggestedCategoryName,
      isAccountAmbiguous: isAccountAmbiguous ?? this.isAccountAmbiguous,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      confirmedTransactionId: confirmedTransactionId ?? this.confirmedTransactionId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
