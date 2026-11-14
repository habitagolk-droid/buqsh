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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CashierWalletsModel? _walletsData;
  CashierWalletsModel? get walletsData => _walletsData;

  List<WalletModel> get cashierWallets => _walletsData?.cashierWallets ?? [];
  List<WalletModel> get merchantWallets => _walletsData?.merchantWallets ?? [];

  @override
  void onInit() {
    super.onInit();
    fetchCashierWallets();
  }

  /// استدعاء GET /api/v1/cashier/wallets مع إرسال توكن الكاشير
  Future<void> fetchCashierWallets({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
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
      update();
    }
  }
}
