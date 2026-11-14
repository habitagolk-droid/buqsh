class ExchangeRateService {
  ExchangeRateService._();
  static final ExchangeRateService instance = ExchangeRateService._();

  static const String baseCurrency = 'YER';

  // أسعار الصرف بالنسبة للعملة الأساسية (YER)
  // 1 USD = 530 YER (50,030 USD = 26,515,900 YER)
  // 1 SAR = 140 YER
  // 1 YER = 1 YER
  static final Map<String, double> _ratesToBase = {
    'YER': 1.0,
    'USD': 530.0,
    'SAR': 140.0,
  };

  /// استرجاع سعر الصرف بالنسبة للعملة الأساسية (YER)
  double getRateToBase(String currency) {
    return _ratesToBase[currency.toUpperCase()] ?? 1.0;
  }

  /// تحديث سعر الصرف للعملة (اختياري عند الجلب من API)
  void updateRate(String currency, double rate) {
    if (rate > 0) {
      _ratesToBase[currency.toUpperCase()] = rate;
    }
  }

  /// حساب ما يعادل المبلغ بالعملة الأساسية (YER)
  double toBaseEquivalent(double amount, String currency) {
    final rate = getRateToBase(currency);
    return double.parse((amount * rate).toStringAsFixed(2));
  }

  /// استرجاع سعر الصرف بين عملتين
  double getExchangeRate(String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return 1.0;
    final rateFrom = getRateToBase(from);
    final rateTo = getRateToBase(to);
    if (rateTo == 0) return 0.0;
    return double.parse((rateFrom / rateTo).toStringAsFixed(6));
  }

  /// حساب رسوم التحويل المقدرة (مثلاً 0.5%)
  double calculateFee(double amount, {double feePercentage = 0.005}) {
    return double.parse((amount * feePercentage).toStringAsFixed(2));
  }

  /// معاينة التحويل بين محفظتين
  Map<String, dynamic> previewExchange({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    double feePercentage = 0.005,
  }) {
    final rate = getExchangeRate(fromCurrency, toCurrency);
    final fee = calculateFee(amount, feePercentage: feePercentage);
    final amountAfterFee = (amount - fee) > 0 ? (amount - fee) : 0.0;
    final convertedAmount = double.parse((amountAfterFee * rate).toStringAsFixed(2));

    return {
      'fromCurrency': fromCurrency,
      'toCurrency': toCurrency,
      'amount': amount,
      'fee': fee,
      'rate': rate,
      'netConvertedAmount': convertedAmount,
    };
  }
}
