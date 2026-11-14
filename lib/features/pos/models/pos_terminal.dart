class PosTerminal {
  final String terminalNumber;
  final String terminalName;
  final String city;
  final String address;
  final String currencyCode;
  final String status;

  PosTerminal({
    required this.terminalNumber,
    required this.terminalName,
    required this.city,
    required this.address,
    required this.currencyCode,
    required this.status,
  });

  factory PosTerminal.fromJson(Map<String, dynamic> json) {
    return PosTerminal(
      terminalNumber: json['terminal_number']?.toString() ?? '',
      terminalName: json['terminal_name'] is String
          ? json['terminal_name'] as String
          : 'unknown_terminal',
      city: (json['city'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      currencyCode: (json['currency_code'] ?? json['currencyCode'] ?? 'YER').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'terminal_number': terminalNumber,
      'terminal_name': terminalName,
      'city': city,
      'address': address,
      'currency_code': currencyCode,
      'status': status,
    };
  }
}
