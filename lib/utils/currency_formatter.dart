/// مُنسِّق العملات لـ YER و USD و SAR
class CurrencyFormatter {
  static String format(double amount, {required String currency}) {
    final String symbol;
    final int decimals;

    switch (currency.toUpperCase()) {
      case 'USD':
        symbol = '\$';
        decimals = 2;
        break;
      case 'SAR':
        symbol = 'ر.س';
        decimals = 2;
        break;
      case 'YER':
        symbol = 'ر.ي';
        decimals = 0;
        break;
      default:
        symbol = currency;
        decimals = 2;
    }

    // Format with thousands separators
    final parts = amount.toStringAsFixed(decimals).split('.');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';

    final buffer = StringBuffer();
    int counter = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      if (counter > 0 && counter % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
      counter++;
    }

    final formatted = buffer.toString().split('').reversed.join('');
    return '$formatted$decPart $symbol';
  }
}
