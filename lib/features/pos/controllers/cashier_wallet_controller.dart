import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_repo.dart';
import 'package:six_cash/features/pos/models/cashier_wallets_model.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';

class CashierWalletController extends GetxController {
  final CashierAuthRepo authRepo;

  CashierWalletController({required this.authRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _hasLoaded = false;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CashierWalletsModel? _walletsData;
  CashierWalletsModel? get walletsData => _walletsData;

  WalletModel? _selectedCashierWallet;
  WalletModel? get selectedCashierWallet => _selectedCashierWallet;

  void selectCashierWallet(WalletModel wallet) {
    _selectedCashierWallet = wallet;
    update();
  }

  List<WalletModel> get cashierWallets => _walletsData?.cashierWallets ?? [];
  List<WalletModel> get merchantWallets => _walletsData?.merchantWallets ?? [];
  List<WalletModel> get displayWallets {
    // لا تعرض رصيد التاجر على أنه رصيد الكاشير. هذه الشاشة خاصة بحساب
    // الكاشير، لذا لا نستخدم محافظ التاجر كبديل للعملات المفقودة.
    if (_walletsData == null) return const [];
    final byCurrency = {
      for (final wallet in cashierWallets) wallet.currencyCode: wallet,
    };
    const definitions = <String, (String, String)>{
      'YER': ('﷼', 'الريال اليمني'),
      'SAR': ('ر.س', 'الريال السعودي'),
      'USD': ('\$', 'الدولار الأمريكي'),
    };
    for (final entry in definitions.entries) {
      byCurrency.putIfAbsent(
        entry.key,
        () => WalletModel(
          id: 0,
          currencyCode: entry.key,
          currencySymbol: entry.value.$1,
          currencyName: entry.value.$2,
          currentBalance: 0,
          baseEquivalent: 0,
          isDefault: false,
          pendingBalance: 0,
        ),
      );
    }
    const order = ['YER', 'SAR', 'USD'];
    return order.map((code) => byCurrency[code]!).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    fetchCashierWallets();
  }

  /// استدعاء GET /api/v1/cashier/wallets مع إرسال توكن الكاشير
  Future<void> fetchCashierWallets({
    bool showLoading = true,
    bool forceRefresh = false,
  }) async {
    if (_isLoading || (_hasLoaded && !forceRefresh)) return;
    _isLoading = true;
    _errorMessage = null;
    if (showLoading) {
      update();
    }

    try {
      final token = await authRepo.getToken();
      if (token == null || token.trim().isEmpty) {
        _errorMessage = 'لم يتم العثور على توكن الكاشير، يرجى تسجيل الدخول مجدداً';
        _isLoading = false;
        update();
        return;
      }

      final response = await authRepo.getCashierWallets(token);

      if (response.statusCode == 200 && response.body != null) {
        _walletsData = CashierWalletsModel.fromResponse(response.body);
        final wallets = displayWallets;
        if (wallets.isNotEmpty) {
          final selectedCode = _selectedCashierWallet?.currencyCode;
          _selectedCashierWallet = wallets.firstWhere(
            (wallet) => wallet.currencyCode == selectedCode,
            orElse: () => wallets.firstWhere(
              (wallet) => wallet.isDefault,
              orElse: () => wallets.first,
            ),
          );
        }
        _errorMessage = null;
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        _errorMessage = 'انتهت صلاحية جلسة الكاشير أو غير مصرح لك (403)';
      } else {
        _errorMessage = 'تعذر تحميل المحافظ (${response.statusCode})';
      }
    } catch (e) {
      debugPrint('Error fetching cashier wallets: $e');
      _errorMessage = 'حدث خطأ أثناء جلب بيانات المحافظ';
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      update();
    }
  }
}
