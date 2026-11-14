class ExchangeRatesModel {
  final String baseCurrency;
  final Map<String, double> rates;

  ExchangeRatesModel({
    required this.baseCurrency,
    required this.rates,
  });

  factory ExchangeRatesModel.fromJson(Map<String, dynamic> json) {
    String base = (json['base'] ??
            json['base_currency'] ??
            json['baseCurrency'] ??
            'YER')
        .toString()
        .toUpperCase();

    Map<String, double> ratesMap = {};

    dynamic rawRates = json['rates'] ?? json['data'] ?? json;
    if (rawRates is Map) {
      rawRates.forEach((k, v) {
        ratesMap[k.toString().toUpperCase()] = _toDouble(v);
      });
    } else if (rawRates is List) {
      for (var item in rawRates) {
        if (item is Map) {
          String code = (item['currency'] ??
                  item['currency_code'] ??
                  item['code'] ??
                  '')
              .toString()
              .toUpperCase();
          double rate = _toDouble(item['rate'] ?? item['exchange_rate'] ?? 1.0);
          if (code.isNotEmpty) {
            ratesMap[code] = rate;
          }
        }
      }
    }

    if (!ratesMap.containsKey(base)) {
      ratesMap[base] = 1.0;
    }

    return ExchangeRatesModel(
      baseCurrency: base,
      rates: ratesMap,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 1.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 1.0;
    return 1.0;
  }

  double getRateToBase(String currency) {
    return rates[currency.toUpperCase()] ?? 1.0;
  }

  double getExchangeRate(String from, String to) {
    if (from.toUpperCase() == to.toUpperCase()) return 1.0;
    final rateFrom = getRateToBase(from);
    final rateTo = getRateToBase(to);
    if (rateTo == 0) return 0.0;
    return double.parse((rateFrom / rateTo).toStringAsFixed(6));
  }
}
