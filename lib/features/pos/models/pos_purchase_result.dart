class PosPurchaseResult {
  final String receiptNumber;
  final double amount;
  final double commission;
  final double netAmount;
  final String currencyCode;
  final String merchantName;
  final String terminalName;
  final String status;
  final DateTime paidAt;

  PosPurchaseResult({
    required this.receiptNumber,
    required this.amount,
    required this.commission,
    required this.netAmount,
    required this.currencyCode,
    required this.merchantName,
    required this.terminalName,
    required this.status,
    required this.paidAt,
  });

  factory PosPurchaseResult.fromJson(Map<String, dynamic> json) {
    final double amt = json['amount'] != null
        ? double.tryParse(json['amount'].toString()) ?? 0.0
        : 0.0;
    final double comm = json['commission'] != null
        ? double.tryParse(json['commission'].toString()) ?? 0.0
        : 0.0;
    final double net = json['net_amount'] != null
        ? double.tryParse(json['net_amount'].toString()) ?? (amt + comm)
        : (amt + comm);

    return PosPurchaseResult(
      receiptNumber: (json['receipt_number'] ?? json['receiptNumber'] ?? json['transaction_id'] ?? '').toString(),
      amount: amt,
      commission: comm,
      netAmount: net,
      currencyCode: (json['currency_code'] ?? json['currencyCode'] ?? 'YER').toString(),
      merchantName: (json['merchant_name'] ?? json['merchantName'] ?? '').toString(),
      terminalName: (json['terminal_name'] ?? json['terminalName'] ?? '').toString(),
      status: (json['status'] ?? 'completed').toString(),
      paidAt: json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receipt_number': receiptNumber,
      'amount': amount,
      'commission': commission,
      'net_amount': netAmount,
      'currency_code': currencyCode,
      'merchant_name': merchantName,
      'terminal_name': terminalName,
      'status': status,
      'paid_at': paidAt.toIso8601String(),
    };
  }
}
