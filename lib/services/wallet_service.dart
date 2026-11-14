import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/wallet_model.dart';
import 'exchange_rate_service.dart';

class WalletService {
  WalletService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const String _walletsStorageKey = 'buqsh_wallets_data';
  static const String _defaultWalletIdKey = 'buqsh_default_wallet_id';

  // القائمة الأولية الموثقة للعملات الثلاث
  static final List<WalletModel> _initialWallets = [
    WalletModel(
      id: 8,
      currencyCode: 'YER',
      currencySymbol: '﷼',
      currencyName: 'الريال اليمني',
      currentBalance: 0.0,
      baseEquivalent: 0.0,
      isDefault: true,
      pendingBalance: 0.0,
    ),
    WalletModel(
      id: 9,
      currencyCode: 'USD',
      currencySymbol: '\$',
      currencyName: 'الدولار الأمريكي',
      currentBalance: 50030.0,
      baseEquivalent: 26515900.0, // 50030 * 530 = 26,515,900
      isDefault: false,
      pendingBalance: 0.0,
    ),
    WalletModel(
      id: 10,
      currencyCode: 'SAR',
      currencySymbol: 'ر.س',
      currencyName: 'الريال السعودي',
      currentBalance: 0.0,
      baseEquivalent: 0.0,
      isDefault: false,
      pendingBalance: 0.0,
    ),
  ];

  /// جلب المحافظ الثلاث مع استرجاع الحالة المحفوظة وحساب baseEquivalent بدقة
  Future<List<WalletModel>> getWallets() async {
    try {
      final jsonString = await _storage.read(key: _walletsStorageKey);
      List<WalletModel> list;
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString) as List;
        list = decoded
            .map((e) => WalletModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } else {
        list = List.from(_initialWallets);
      }

      // قراءة المحفظة الافتراضية المحفوظة
      final savedDefaultIdStr = await _storage.read(key: _defaultWalletIdKey);
      final defaultId = savedDefaultIdStr != null
          ? int.tryParse(savedDefaultIdStr)
          : null;

      final updatedList = list.map((w) {
        final isDef = defaultId != null ? w.id == defaultId : w.isDefault;
        final baseEq = ExchangeRateService.instance.toBaseEquivalent(
          w.currentBalance,
          w.currencyCode,
        );
        return WalletModel(
          id: w.id,
          currencyCode: w.currencyCode,
          currencySymbol: w.currencySymbol,
          currencyName: w.currencyName,
          currentBalance: w.currentBalance,
          baseEquivalent: baseEq,
          isDefault: isDef,
          pendingBalance: w.pendingBalance,
        );
      }).toList();

      return updatedList;
    } catch (_) {
      return List.from(_initialWallets);
    }
  }

  /// تعيين المحفظة الافتراضية وحفظها
  Future<List<WalletModel>> setDefaultWallet(int walletId) async {
    final wallets = await getWallets();
    final updated = wallets.map((w) {
      return WalletModel(
        id: w.id,
        currencyCode: w.currencyCode,
        currencySymbol: w.currencySymbol,
        currencyName: w.currencyName,
        currentBalance: w.currentBalance,
        baseEquivalent: w.baseEquivalent,
        isDefault: w.id == walletId,
        pendingBalance: w.pendingBalance,
      );
    }).toList();

    await _saveWallets(updated);
    await _storage.write(key: _defaultWalletIdKey, value: walletId.toString());
    return updated;
  }

  /// التحويل بين المحافظ مع التحقق وتحديث الأرصدة وسعر الصرف
  Future<List<WalletModel>> transferBetweenWallets({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('المبلغ يجب أن يكون أكبر من الصفر');
    }
    if (fromCurrency.toUpperCase() == toCurrency.toUpperCase()) {
      throw ArgumentError('لا يمكن التحويل لنفس العملة');
    }

    final wallets = await getWallets();
    final fromWallet = wallets.firstWhere(
      (w) => w.currencyCode.toUpperCase() == fromCurrency.toUpperCase(),
      orElse: () => throw Exception('محفظة المصدر غير موجودة'),
    );
    final toWallet = wallets.firstWhere(
      (w) => w.currencyCode.toUpperCase() == toCurrency.toUpperCase(),
      orElse: () => throw Exception('محفظة الهدف غير موجودة'),
    );

    if (fromWallet.currentBalance < amount) {
      throw Exception('الرصيد غير كافٍ في محفظة ${fromWallet.currencyName}');
    }

    // حساب التحويل والرسوم
    final exchange = ExchangeRateService.instance.previewExchange(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      amount: amount,
    );
    final netReceived = exchange['netConvertedAmount'] as double;

    final updated = wallets.map((w) {
      if (w.id == fromWallet.id) {
        final newBalance = double.parse(
          (w.currentBalance - amount).toStringAsFixed(2),
        );
        return WalletModel(
          id: w.id,
          currencyCode: w.currencyCode,
          currencySymbol: w.currencySymbol,
          currencyName: w.currencyName,
          currentBalance: newBalance,
          baseEquivalent: ExchangeRateService.instance.toBaseEquivalent(
            newBalance,
            w.currencyCode,
          ),
          isDefault: w.isDefault,
          pendingBalance: w.pendingBalance,
        );
      } else if (w.id == toWallet.id) {
        final newBalance = double.parse(
          (w.currentBalance + netReceived).toStringAsFixed(2),
        );
        return WalletModel(
          id: w.id,
          currencyCode: w.currencyCode,
          currencySymbol: w.currencySymbol,
          currencyName: w.currencyName,
          currentBalance: newBalance,
          baseEquivalent: ExchangeRateService.instance.toBaseEquivalent(
            newBalance,
            w.currencyCode,
          ),
          isDefault: w.isDefault,
          pendingBalance: w.pendingBalance,
        );
      }
      return w;
    }).toList();

    await _saveWallets(updated);
    return updated;
  }

  Future<void> _saveWallets(List<WalletModel> wallets) async {
    try {
      final jsonList = wallets.map((w) => w.toJson()).toList();
      await _storage.write(
        key: _walletsStorageKey,
        value: jsonEncode(jsonList),
      );
    } catch (_) {
      // Ignored in non-secure or fallback environments
    }
  }
}
