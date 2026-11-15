class CashierTransaction {
  const CashierTransaction({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.transactionType,
    required this.status,
    required this.createdAt,
    required this.receiptNumber,
  });

  final String id;
  final double amount;
  final String currencyCode;
  final String transactionType;
  final String status;
  final String createdAt;
  final String receiptNumber;

  factory CashierTransaction.fromJson(Map<String, dynamic> json) {
    return CashierTransaction(
      id: json['id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      currencyCode: json['currency_code']?.toString() ?? '',
      transactionType: json['transaction_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      receiptNumber: json['receipt_number']?.toString() ?? '',
    );
  }
}
