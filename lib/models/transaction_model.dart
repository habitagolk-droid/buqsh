class TransactionModel {
  TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.senderName,
    required this.receiverName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['transaction_id'] ?? json['id'] ?? 'TRX-UNKNOWN',
      type: json['transaction_type'] ?? 'unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency_code'] ?? 'YER',
      status: json['status'] ?? 'completed',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      senderName: json['sender']?['name'] ?? 'Unknown',
      receiverName: json['receiver']?['name'] ?? 'Unknown',
    );
  }

  final String id;
  final String type;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final String senderName;
  final String receiverName;

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': id,
      'transaction_type': type,
      'amount': amount,
      'currency_code': currency,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'sender': {'name': senderName},
      'receiver': {'name': receiverName},
    };
  }
}
