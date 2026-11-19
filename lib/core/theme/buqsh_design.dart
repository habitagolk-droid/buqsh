import 'package:flutter/material.dart';

/// Frozen UI4Code tokens shared by BUQSH's five visual families.
/// Components should choose the family token they need instead of flattening
/// every surface into one global color.
abstract final class BqColors {
  static const brand = Color(0xFF0C4A40);
  static const brandDeep = Color(0xFF08332C);
  static const green = Color(0xFF278D5B);
  static const accent = Color(0xFFD4E157);
  static const accentDark = Color(0xFFAFCF3A);
  static const bg = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const title = Color(0xFF003E47);
  static const ink = Color(0xFF10201D);
  static const muted = Color(0xFF6B7D7D);
  static const line = Color(0xFFE5ECEA);
  static const error = Color(0xFFC92A2A);
  static const success = Color(0xFF1F7A33);
  static const warning = Color(0xFFF9E7A7);
  static const scrim = Color(0x8C031E1B);
  static const customerSoft = Color(0xFFEDF4F1);
  static const input = Color(0xFFF4F6F5);
  static const receiptSoft = Color(0xFFF8FAF9);
  static const yerEnd = Color(0xFF1A7A65);
  static const sarStart = Color(0xFF0B3B54);
  static const usdStart = Color(0xFF1C4D2A);
}

abstract final class BqSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 18.0;
  static const xxl = 24.0;
  static const screen = EdgeInsets.fromLTRB(14, 18, 14, 28);
}

abstract final class BqRadius {
  static const card = 18.0;
  static const sheet = 26.0;
  static const hero = 22.0;
  static const large = 32.0;
  static const pill = 99.0;
}

abstract final class BqGradients {
  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BqColors.brand, Color(0xFF0E5A4F), Color(0xFF14705F)],
  );
  static const proHeader = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BqColors.brand, Color(0xFF126350), BqColors.green],
  );
  static const yerWallet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BqColors.brand, BqColors.yerEnd],
  );
  static const sarWallet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BqColors.sarStart, Color(0xFF14705F)],
  );
  static const usdWallet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [BqColors.usdStart, BqColors.green],
  );
}

abstract final class BqShadows {
  static const card = [
    BoxShadow(color: Color(0x240C4A40), blurRadius: 18, offset: Offset(0, 8)),
  ];
  static const navigation = [
    BoxShadow(color: Color(0x24000000), blurRadius: 34, offset: Offset(0, 14)),
  ];
}

class BqWalletGradient {
  const BqWalletGradient._();

  static LinearGradient forCurrency(String code) {
    switch (code.toUpperCase()) {
      case 'SAR':
        return BqGradients.sarWallet;
      case 'USD':
        return BqGradients.usdWallet;
      case 'YER':
      default:
        return BqGradients.yerWallet;
    }
  }
}
