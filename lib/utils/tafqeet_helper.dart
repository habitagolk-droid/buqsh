/// فئة مساعدة لتحويل المبالغ المالية إلى كلمات باللغة العربية (التفقيط)
class TafqeetHelper {
  static const List<String> _ones = [
    '',
    'واحد',
    'اثنان',
    'ثلاثة',
    'أربعة',
    'خمسة',
    'ستة',
    'سبعة',
    'ثمانية',
    'تسعة',
    'عشرة',
    'أحد عشر',
    'اثنا عشر',
    'ثلاثة عشر',
    'أربعة عشر',
    'خمسة عشر',
    'ستة عشر',
    'سبعة عشر',
    'ثمانية عشر',
    'تسعة عشر',
  ];

  static const List<String> _tens = [
    '',
    '',
    'عشرون',
    'ثلاثون',
    'أربعون',
    'خمسون',
    'ستون',
    'سبعون',
    'ثمانون',
    'تسعون',
  ];

  static const List<String> _hundreds = [
    '',
    'مائة',
    'مائتان',
    'ثلاثمائة',
    'أربعمائة',
    'خمسمائة',
    'ستمائة',
    'سبعمائة',
    'ثمانمائة',
    'تسعمائة',
  ];

  /// تحويل رقم أقل من 1000 إلى كلمات
  static String _convertThreeDigits(int number) {
    if (number == 0) return '';

    final List<String> parts = [];

    int h = number ~/ 100;
    int remainder = number % 100;

    if (h > 0) {
      parts.add(_hundreds[h]);
    }

    if (remainder > 0) {
      if (remainder < 20) {
        parts.add(_ones[remainder]);
      } else {
        int t = remainder ~/ 10;
        int o = remainder % 10;
        if (o > 0) {
          parts.add('${_ones[o]} و${_tens[t]}');
        } else {
          parts.add(_tens[t]);
        }
      }
    }

    return parts.join(' و');
  }

  /// تحويل العدد الصحيح بالكامل
  static String convertNumber(int number) {
    if (number == 0) return 'صفر';
    if (number < 0) return 'سالب ${convertNumber(number.abs())}';

    final List<String> parts = [];

    // مليارات
    int billions = number ~/ 1000000000;
    int remBillions = number % 1000000000;
    if (billions > 0) {
      if (billions == 1) {
        parts.add('مليار');
      } else if (billions == 2) {
        parts.add('ملياران');
      } else if (billions >= 3 && billions <= 10) {
        parts.add('${_convertThreeDigits(billions)} مليارات');
      } else {
        parts.add('${_convertThreeDigits(billions)} ملياراً');
      }
    }

    // ملايين
    int millions = remBillions ~/ 1000000;
    int remMillions = remBillions % 1000000;
    if (millions > 0) {
      if (millions == 1) {
        parts.add('مليون');
      } else if (millions == 2) {
        parts.add('مليونان');
      } else if (millions >= 3 && millions <= 10) {
        parts.add('${_convertThreeDigits(millions)} ملايين');
      } else {
        parts.add('${_convertThreeDigits(millions)} مليوناً');
      }
    }

    // آلاف
    int thousands = remMillions ~/ 1000;
    int remainder = remMillions % 1000;
    if (thousands > 0) {
      if (thousands == 1) {
        parts.add('ألف');
      } else if (thousands == 2) {
        parts.add('ألفان');
      } else if (thousands >= 3 && thousands <= 10) {
        parts.add('${_convertThreeDigits(thousands)} آلاف');
      } else {
        parts.add('${_convertThreeDigits(thousands)} ألفاً');
      }
    }

    // المتبقي (أقل من ألف)
    if (remainder > 0) {
      parts.add(_convertThreeDigits(remainder));
    }

    return parts.join(' و');
  }

  /// إرجاع اسم العملة بالعربية
  static String _currencyName(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return 'دولار أمريكي';
      case 'SAR':
        return 'ريال سعودي';
      case 'YER':
      default:
        return 'ريال يمني';
    }
  }

  /// تحويل المبلغ مع اسم العملة وتذييل "فقط لا غير"
  static String convert(double amount, {String currencyCode = 'YER'}) {
    if (amount <= 0) return '';

    int intPart = amount.floor();
    int decPart = ((amount - intPart) * 100).round();

    String result = convertNumber(intPart);
    String currency = _currencyName(currencyCode);

    result = '$result $currency';

    if (decPart > 0) {
      String subCurrency = currencyCode.toUpperCase() == 'USD' ? 'سنت' : 'فلس';
      result = '$result و${convertNumber(decPart)} $subCurrency';
    }

    return '$result فقط لا غير';
  }
}
