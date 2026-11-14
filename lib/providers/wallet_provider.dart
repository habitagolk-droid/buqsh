import 'package:flutter/foundation.dart';

import '../models/wallet_model.dart';
import '../services/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  WalletProvider({WalletService? walletService})
      : _service = walletService ?? WalletService() {
    _wallets = <WalletModel>[];
    fetchWallets();
  }

  final WalletService _service;
  late List<WalletModel> _wallets;
  bool _loading = false;
  String? _error;

  List<WalletModel> get wallets => _wallets;
  bool get loading => _loading;
  String? get error => _error;

  WalletModel? get defaultWallet =>
      _wallets.where((wallet) => wallet.isDefault).firstOrNull;

  /// إجمالي الرصيد المحول للعملة الأساسية (YER)
  double get totalBaseBalance {
    return _wallets.fold(
      0.0,
      (sum, wallet) => sum + wallet.baseEquivalent,
    );
  }

  WalletModel? getWalletByCode(String code) {
    return _wallets.where(
      (w) => w.currencyCode.toUpperCase() == code.toUpperCase(),
    ).firstOrNull;
  }

  Future<void> fetchWallets() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _wallets = await _service.getWallets();
    } catch (e) {
      _error = 'تعذر جلب بيانات المحافظ: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> setDefaultWallet(int walletId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _wallets = await _service.setDefaultWallet(walletId);
      return true;
    } catch (e) {
      _error = 'فشل في تغيير المحفظة الافتراضية: $e';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> transferBetweenWallets({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _wallets = await _service.transferBetweenWallets(
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        amount: amount,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setWallets(List<WalletModel> wallets) {
    _wallets = wallets;
    _error = null;
    notifyListeners();
  }

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }
}
