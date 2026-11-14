import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/wallet/domain/models/exchange_rates_model.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/features/wallet/domain/reposotories/wallet_repo.dart';

class WalletController extends GetxController implements GetxService {
  final WalletRepo walletRepo;

  WalletController({required this.walletRepo});

  List<WalletModel> _wallets = [];
  List<WalletModel> get wallets => _wallets;

  WalletModel? _selectedWallet;
  WalletModel? get selectedWallet => _selectedWallet;

  ExchangeRatesModel? _exchangeRates;
  ExchangeRatesModel? get exchangeRates => _exchangeRates;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isTransferring = false;
  bool get isTransferring => _isTransferring;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// جلب المحافظ الثلاث من الخادم
  Future<void> getWallets({bool reload = false, bool isUpdate = false}) async {
    if (reload || _wallets.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      if (isUpdate) {
        update();
      }
    }

    try {
      Response response = await walletRepo.getWalletsList();
      if (response.statusCode == 200 && response.body != null) {
        List<WalletModel> fetched = [];
        dynamic body = response.body;
        dynamic listData;

        if (body is List) {
          listData = body;
        } else if (body is Map) {
          if (body['data'] is List) {
            listData = body['data'];
          } else if (body['data'] is Map && body['data']['wallets'] is List) {
            listData = body['data']['wallets'];
          } else if (body['wallets'] is List) {
            listData = body['wallets'];
          }
        }

        if (listData is List) {
          for (var item in listData) {
            if (item is Map<String, dynamic>) {
              fetched.add(WalletModel.fromJson(item));
            } else if (item is Map) {
              fetched.add(
                  WalletModel.fromJson(Map<String, dynamic>.from(item)));
            }
          }
        }

        if (fetched.isNotEmpty) {
          _wallets = fetched;
          _errorMessage = null;

          // مزامنة المحفظة المختارة
          if (_selectedWallet != null) {
            int idx = _wallets.indexWhere((w) =>
                w.id == _selectedWallet!.id ||
                w.currencyCode == _selectedWallet!.currencyCode);
            if (idx != -1) {
              _selectedWallet = _wallets[idx];
            } else {
              _selectedWallet = _wallets.firstWhere((w) => w.isDefault,
                  orElse: () => _wallets.first);
            }
          } else {
            _selectedWallet = _wallets.firstWhere((w) => w.isDefault,
                orElse: () => _wallets.first);
          }
        } else {
          if (_wallets.isEmpty) {
            _errorMessage = 'failed_to_fetch_wallets'.tr;
          }
        }
      } else {
        String errorMsg = 'failed_to_fetch_wallets'.tr;
        if (response.body is Map && response.body['message'] != null) {
          errorMsg = response.body['message'].toString();
        } else if (response.statusText != null &&
            response.statusText!.isNotEmpty) {
          errorMsg = response.statusText!;
        }
        if (_wallets.isEmpty) {
          _errorMessage = errorMsg;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching wallets: $e');
      }
      if (_wallets.isEmpty) {
        _errorMessage = 'failed_to_fetch_wallets'.tr;
      }
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// تغيير المحفظة المختارة
  void selectWallet(WalletModel wallet) {
    _selectedWallet = wallet;
    update();
  }

  /// اختيار المحفظة بالرمز
  void selectWalletByCurrency(String currencyCode) {
    int idx = _wallets.indexWhere(
        (w) => w.currencyCode.toUpperCase() == currencyCode.toUpperCase());
    if (idx != -1) {
      _selectedWallet = _wallets[idx];
      update();
    }
  }

  /// جلب أسعار الصرف الحقيقية من الخادم
  Future<void> getExchangeRates() async {
    try {
      Response response = await walletRepo.getExchangeRates();
      if (response.statusCode == 200 && response.body != null) {
        dynamic body = response.body;
        if (body is Map<String, dynamic>) {
          _exchangeRates = ExchangeRatesModel.fromJson(body);
        } else if (body is Map) {
          _exchangeRates =
              ExchangeRatesModel.fromJson(Map<String, dynamic>.from(body));
        }
        update();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching rates: $e');
      }
    }
  }

  /// تعيين المحفظة الافتراضية
  Future<bool> setDefaultWallet(int walletId) async {
    try {
      Response response =
          await walletRepo.setDefaultWallet(walletId: walletId);
      if (response.statusCode == 200) {
        _wallets = _wallets.map((w) {
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

        if (_selectedWallet?.id == walletId) {
          _selectedWallet =
              _wallets.firstWhere((w) => w.id == walletId);
        }
        update();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting default wallet: $e');
      }
    }
    return false;
  }

  bool _isSuccessful(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  /// تنفيذ التحويل بين المحافظ بعد استجابة الخادم المؤكدة فقط
  Future<Response> transferBetweenWallets({
    int? fromWalletId,
    int? toWalletId,
    String? fromCurrency,
    String? toCurrency,
    required double amount,
    String? note,
  }) async {
    _isTransferring = true;
    update();

    try {
      Response response = await walletRepo.transferBetweenWallets(
        fromWalletId: fromWalletId,
        toWalletId: toWalletId,
        fromCurrency: fromCurrency,
        toCurrency: toCurrency,
        amount: amount,
        note: note,
      );

      if (_isSuccessful(response.statusCode)) {
        // إعادة تحميل الرصيد من الخادم فقط بعد تأكيد العملية
        await getWallets(reload: true);
      }
      return response;
    } finally {
      _isTransferring = false;
      update();
    }
  }
}
