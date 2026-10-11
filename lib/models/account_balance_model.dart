class AccountBalanceModel {
  final int accountId;
  final String displayName;
  final String type;
  final String subtype;
  final String currencyCode;
  final String openingAmount;
  final String currentBalance;
  final String totalIncome;
  final String totalExpense;
  final String transfersIn;
  final String transfersOut;
  final String totalAdjustments;
  final String? creditLimit;
  final String? availableCredit;

  const AccountBalanceModel({
    required this.accountId,
    required this.displayName,
    required this.type,
    required this.subtype,
    required this.currencyCode,
    required this.openingAmount,
    required this.currentBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.transfersIn,
    required this.transfersOut,
    required this.totalAdjustments,
    this.creditLimit,
    this.availableCredit,
  });

  bool get isCreditCard => type == 'credit_card';

  factory AccountBalanceModel.fromJson(Map<String, dynamic> json) {
    return AccountBalanceModel(
      accountId: json['accountId'] as int,
      displayName: json['displayName'] as String? ?? '',
      type: json['type'] as String? ?? 'bank',
      subtype: json['subtype'] as String? ?? 'savings',
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      openingAmount: json['openingAmount'] as String? ?? '0.00',
      currentBalance: json['currentBalance'] as String? ?? '0.00',
      totalIncome: json['totalIncome'] as String? ?? '0.00',
      totalExpense: json['totalExpense'] as String? ?? '0.00',
      transfersIn: json['transfersIn'] as String? ?? '0.00',
      transfersOut: json['transfersOut'] as String? ?? '0.00',
      totalAdjustments: json['totalAdjustments'] as String? ?? '0.00',
      creditLimit: json['creditLimit'] as String?,
      availableCredit: json['availableCredit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'displayName': displayName,
      'type': type,
      'subtype': subtype,
      'currencyCode': currencyCode,
      'openingAmount': openingAmount,
      'currentBalance': currentBalance,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'transfersIn': transfersIn,
      'transfersOut': transfersOut,
      'totalAdjustments': totalAdjustments,
      'creditLimit': creditLimit,
      'availableCredit': availableCredit,
    };
  }
}
