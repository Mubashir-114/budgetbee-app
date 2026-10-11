import 'transfer_model.dart';

/// Billing cycle dates and status for a credit card.
///
/// Notice: All dates are calculated estimates based on configured closing and
/// due days, not issuer-confirmed statements.
class CreditCardBillingModel {
  final int? statementClosingDay;
  final int? paymentDueDay;
  final String? closingDate;
  final String? dueDate;
  final int? daysUntilDue;
  final bool isDue;
  final bool isOverdue;
  final String status; // "unconfigured" | "paid_in_full" | "overdue" | "due" | "current"
  final bool isEstimated;

  const CreditCardBillingModel({
    this.statementClosingDay,
    this.paymentDueDay,
    this.closingDate,
    this.dueDate,
    this.daysUntilDue,
    this.isDue = false,
    this.isOverdue = false,
    this.status = 'unconfigured',
    this.isEstimated = true,
  });

  factory CreditCardBillingModel.fromJson(Map<String, dynamic> json) {
    return CreditCardBillingModel(
      statementClosingDay: json['statementClosingDay'] as int?,
      paymentDueDay: json['paymentDueDay'] as int?,
      closingDate: json['closingDate'] as String?,
      dueDate: json['dueDate'] as String?,
      daysUntilDue: json['daysUntilDue'] as int?,
      isDue: json['isDue'] as bool? ?? false,
      isOverdue: json['isOverdue'] as bool? ?? false,
      status: json['status'] as String? ?? 'unconfigured',
      isEstimated: json['isEstimated'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statementClosingDay': statementClosingDay,
      'paymentDueDay': paymentDueDay,
      'closingDate': closingDate,
      'dueDate': dueDate,
      'daysUntilDue': daysUntilDue,
      'isDue': isDue,
      'isOverdue': isOverdue,
      'status': status,
      'isEstimated': isEstimated,
    };
  }
}

/// Detailed credit card financial status and configuration.
///
/// Financial amounts are kept as exact decimal strings. Never convert to double.
class CreditCardDetailsModel {
  final int accountId;
  final String displayName;
  final String? institutionName;
  final String? maskedLast4;
  final String currencyCode;
  final String creditLimit;
  final String outstandingDebt;
  final String availableCredit;
  final String creditBalance;
  final String utilizationPercentage;
  final int? statementClosingDay;
  final int? paymentDueDay;
  final CreditCardBillingModel billingInfo;
  final String status;

  const CreditCardDetailsModel({
    required this.accountId,
    required this.displayName,
    this.institutionName,
    this.maskedLast4,
    required this.currencyCode,
    required this.creditLimit,
    required this.outstandingDebt,
    required this.availableCredit,
    required this.creditBalance,
    required this.utilizationPercentage,
    this.statementClosingDay,
    this.paymentDueDay,
    required this.billingInfo,
    required this.status,
  });

  factory CreditCardDetailsModel.fromJson(Map<String, dynamic> json) {
    return CreditCardDetailsModel(
      accountId: json['accountId'] as int,
      displayName: json['displayName'] as String? ?? '',
      institutionName: json['institutionName'] as String?,
      maskedLast4: json['maskedLast4'] as String?,
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      creditLimit: json['creditLimit'] as String? ?? '0.00',
      outstandingDebt: json['outstandingDebt'] as String? ?? '0.00',
      availableCredit: json['availableCredit'] as String? ?? '0.00',
      creditBalance: json['creditBalance'] as String? ?? '0.00',
      utilizationPercentage: json['utilizationPercentage'] as String? ?? '0.00',
      statementClosingDay: json['statementClosingDay'] as int?,
      paymentDueDay: json['paymentDueDay'] as int?,
      billingInfo: json['billingInfo'] != null
          ? CreditCardBillingModel.fromJson(
              json['billingInfo'] as Map<String, dynamic>)
          : const CreditCardBillingModel(),
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'displayName': displayName,
      'institutionName': institutionName,
      'maskedLast4': maskedLast4,
      'currencyCode': currencyCode,
      'creditLimit': creditLimit,
      'outstandingDebt': outstandingDebt,
      'availableCredit': availableCredit,
      'creditBalance': creditBalance,
      'utilizationPercentage': utilizationPercentage,
      'statementClosingDay': statementClosingDay,
      'paymentDueDay': paymentDueDay,
      'billingInfo': billingInfo.toJson(),
      'status': status,
    };
  }
}

/// Result returned from an atomic credit card repayment.
class CreditCardRepaymentResult {
  final TransferModel payment;
  final bool created;
  final String sourceBalance;
  final String cardDebt;
  final String availableCredit;

  const CreditCardRepaymentResult({
    required this.payment,
    required this.created,
    required this.sourceBalance,
    required this.cardDebt,
    required this.availableCredit,
  });

  factory CreditCardRepaymentResult.fromJson(Map<String, dynamic> json) {
    return CreditCardRepaymentResult(
      payment: TransferModel.fromJson(json['payment'] as Map<String, dynamic>),
      created: json['created'] as bool? ?? true,
      sourceBalance: json['sourceBalance'] as String? ?? '0.00',
      cardDebt: json['cardDebt'] as String? ?? '0.00',
      availableCredit: json['availableCredit'] as String? ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment': payment.toJson(),
      'created': created,
      'sourceBalance': sourceBalance,
      'cardDebt': cardDebt,
      'availableCredit': availableCredit,
    };
  }
}

/// Paginated credit card repayment history response.
class CreditCardPaymentListResponse {
  final List<TransferModel> payments;
  final int total;
  final int page;
  final int limit;

  const CreditCardPaymentListResponse({
    required this.payments,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory CreditCardPaymentListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['payments'] as List<dynamic>?) ?? [];
    return CreditCardPaymentListResponse(
      payments: list
          .map((item) => TransferModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payments': payments.map((p) => p.toJson()).toList(),
      'total': total,
      'page': page,
      'limit': limit,
    };
  }
}
