class WalletModel {
  final int id;
  final String currencyCode;
  final String currencySymbol;
  final String currencyName;
  final double currentBalance;
  final double baseEquivalent;
  final bool isDefault;
  final double pendingBalance;

  WalletModel({
    required this.id,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyName,
    required this.currentBalance,
    required this.baseEquivalent,
    required this.isDefault,
    required this.pendingBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    String code = (json['currency_code'] ??
            json['currencyCode'] ??
            json['currency'] ??
            'YER')
        .toString()
        .toUpperCase();

    String symbol = json['currency_symbol'] ??
        json['currencySymbol'] ??
        json['symbol'] ??
        _defaultSymbol(code);

    String name = json['currency_name'] ??
        json['currencyName'] ??
        json['name'] ??
        _defaultName(code);

    double balance = _toDouble(
        json['current_balance'] ?? json['currentBalance'] ?? json['balance']);

    double baseEq = _toDouble(json['base_equivalent'] ??
        json['baseEquivalent'] ??
        json['equivalent'] ??
        balance);

    double pending = _toDouble(
        json['pending_balance'] ?? json['pendingBalance'] ?? 0);

    bool def = json['is_default'] == 1 ||
        json['is_default'] == true ||
        json['isDefault'] == 1 ||
        json['isDefault'] == true;

    return WalletModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse('${json['id']}') ?? 0,
      currencyCode: code,
      currencySymbol: symbol,
      currencyName: name,
      currentBalance: balance,
      baseEquivalent: baseEq,
      isDefault: def,
      pendingBalance: pending,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static String _defaultSymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'SAR':
        return 'ر.س';
      case 'YER':
      default:
        return '﷼';
    }
  }

  static String _defaultName(String code) {
    switch (code) {
      case 'USD':
        return 'الدولار الأمريكي';
      case 'SAR':
        return 'الريال السعودي';
      case 'YER':
      default:
        return 'الريال اليمني';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'currency_name': currencyName,
      'current_balance': currentBalance,
      'base_equivalent': baseEquivalent,
      'is_default': isDefault ? 1 : 0,
      'pending_balance': pendingBalance,
    };
  }
}
