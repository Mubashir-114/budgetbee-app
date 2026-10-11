class AccountAdjustmentModel {
  final int id;
  final int accountId;
  final String amount;
  final String reason;
  final String adjustmentDate;
  final String? createdAt;

  const AccountAdjustmentModel({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.reason,
    required this.adjustmentDate,
    this.createdAt,
  });

  bool get isPositive => !amount.startsWith('-');

  factory AccountAdjustmentModel.fromJson(Map<String, dynamic> json) {
    return AccountAdjustmentModel(
      id: json['id'] as int,
      accountId: json['accountId'] as int,
      amount: json['amount'] as String? ?? '0.00',
      reason: json['reason'] as String? ?? '',
      adjustmentDate: json['adjustmentDate'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'amount': amount,
      'reason': reason,
      'adjustmentDate': adjustmentDate,
      'createdAt': createdAt,
    };
  }
}
