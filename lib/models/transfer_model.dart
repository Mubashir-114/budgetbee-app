class TransferModel {
  final int id;
  final int sourceAccountId;
  final int destinationAccountId;
  final String? sourceAccountName;
  final String? destinationAccountName;
  final String amount;
  final String currencyCode;
  final String transferDate;
  final String? note;
  final String? createdAt;

  const TransferModel({
    required this.id,
    required this.sourceAccountId,
    required this.destinationAccountId,
    this.sourceAccountName,
    this.destinationAccountName,
    required this.amount,
    required this.currencyCode,
    required this.transferDate,
    this.note,
    this.createdAt,
  });

  factory TransferModel.fromJson(Map<String, dynamic> json) {
    return TransferModel(
      id: json['id'] as int,
      sourceAccountId: json['sourceAccountId'] as int,
      destinationAccountId: json['destinationAccountId'] as int,
      sourceAccountName: json['sourceAccountName'] as String?,
      destinationAccountName: json['destinationAccountName'] as String?,
      amount: json['amount'] as String? ?? '0.00',
      currencyCode: json['currencyCode'] as String? ?? 'INR',
      transferDate: json['transferDate'] as String? ?? '',
      note: json['note'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'sourceAccountName': sourceAccountName,
      'destinationAccountName': destinationAccountName,
      'amount': amount,
      'currencyCode': currencyCode,
      'transferDate': transferDate,
      'note': note,
      'createdAt': createdAt,
    };
  }
}

class TransferListResponse {
  final List<TransferModel> transfers;
  final int total;
  final int page;
  final int limit;

  const TransferListResponse({
    required this.transfers,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory TransferListResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['transfers'] as List<dynamic>?) ?? [];
    return TransferListResponse(
      transfers: list
          .map((item) => TransferModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
