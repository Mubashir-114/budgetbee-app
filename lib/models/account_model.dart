/// Account model — mirrors the backend [toAccountJson] serialization exactly.
///
/// Financial values (openingAmount, creditLimit) are kept as [String] to
/// preserve exact decimal representation. Never convert to [double] for
/// arithmetic or display without explicit formatting.
class AccountModel {
  final int id;
  final String type; // "bank" | "cash" | "wallet" | "credit_card"
  final String subtype; // "savings" | "current" | "salary" | "cash" | "stored_value" | "credit_card"
  final String displayName;
  final String? institutionName;
  final String? maskedLast4;
  final String currencyCode; // "INR" in Phase 3A
  /// Exact decimal string — e.g. "12500.00". Never parse to double.
  final String openingAmount;
  /// Null for non-credit-card accounts.
  final String? creditLimit;
  final bool isDefault;
  final String status; // "active" | "archived"
  final String? createdAt;
  final String? updatedAt;
  final int? statementClosingDay;
  final int? paymentDueDay;

  const AccountModel({
    required this.id,
    required this.type,
    required this.subtype,
    required this.displayName,
    this.institutionName,
    this.maskedLast4,
    required this.currencyCode,
    required this.openingAmount,
    this.creditLimit,
    required this.isDefault,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.statementClosingDay,
    this.paymentDueDay,
  });

  bool get isAsset => type != 'credit_card';
  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int,
      type: json['type'] as String,
      subtype: json['subtype'] as String,
      displayName: json['displayName'] as String,
      institutionName: json['institutionName'] as String?,
      maskedLast4: json['maskedLast4'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      openingAmount: json['openingAmount'] as String? ?? '0.00',
      creditLimit: json['creditLimit'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      statementClosingDay: json['statementClosingDay'] as int?,
      paymentDueDay: json['paymentDueDay'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'subtype': subtype,
      'displayName': displayName,
      'institutionName': institutionName,
      'maskedLast4': maskedLast4,
      'currencyCode': currencyCode,
      'openingAmount': openingAmount,
      'creditLimit': creditLimit,
      'isDefault': isDefault,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'statementClosingDay': statementClosingDay,
      'paymentDueDay': paymentDueDay,
    };
  }

  AccountModel copyWith({
    int? id,
    String? type,
    String? subtype,
    String? displayName,
    String? institutionName,
    String? maskedLast4,
    String? currencyCode,
    String? openingAmount,
    String? creditLimit,
    bool? isDefault,
    String? status,
    String? createdAt,
    String? updatedAt,
    int? statementClosingDay,
    int? paymentDueDay,
  }) {
    return AccountModel(
      id: id ?? this.id,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      displayName: displayName ?? this.displayName,
      institutionName: institutionName ?? this.institutionName,
      maskedLast4: maskedLast4 ?? this.maskedLast4,
      currencyCode: currencyCode ?? this.currencyCode,
      openingAmount: openingAmount ?? this.openingAmount,
      creditLimit: creditLimit ?? this.creditLimit,
      isDefault: isDefault ?? this.isDefault,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      statementClosingDay: statementClosingDay ?? this.statementClosingDay,
      paymentDueDay: paymentDueDay ?? this.paymentDueDay,
    );
  }
}

/// Paginated list response — mirrors backend [getAccounts] data envelope.
class AccountListResponse {
  final List<AccountModel> accounts;
  final int total;
  final int page;
  final int limit;

  const AccountListResponse({
    required this.accounts,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory AccountListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['accounts'] as List<dynamic>?) ?? [];
    return AccountListResponse(
      accounts: list
          .map((item) => AccountModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
