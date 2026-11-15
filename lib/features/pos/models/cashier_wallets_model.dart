import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';

class CashierWalletsModel {
  final List<WalletModel> cashierWallets;
  final List<WalletModel> merchantWallets;

  CashierWalletsModel({
    required this.cashierWallets,
    required this.merchantWallets,
  });

  factory CashierWalletsModel.fromJson(Map<String, dynamic> json) {
    // استخراج محفظة الكاشير
    final rawCashier = json['cashier_wallets'] ??
        json['cashier_wallet'] ??
        json['cashierWallets'] ??
        json['cashierWallet'];

    List<WalletModel> cashierList = [];
    if (rawCashier is List) {
      cashierList = rawCashier
          .map((item) => WalletModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else if (rawCashier is Map) {
      cashierList = [
        WalletModel.fromJson(Map<String, dynamic>.from(rawCashier)),
      ];
    }

    // استخراج محفظة / أرصدة التاجر
    final rawMerchant = json['merchant_wallets'] ??
        json['merchant_wallet'] ??
        json['merchantWallets'] ??
        json['merchantWallet'] ??
        json['store_wallets'];

    List<WalletModel> merchantList = [];
    if (rawMerchant is List) {
      merchantList = rawMerchant
          .map((item) => WalletModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else if (rawMerchant is Map) {
      merchantList = [
        WalletModel.fromJson(Map<String, dynamic>.from(rawMerchant)),
      ];
    }

    return CashierWalletsModel(
      cashierWallets: cashierList,
      merchantWallets: merchantList,
    );
  }

  factory CashierWalletsModel.fromResponse(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body.containsKey('cashier_wallets') || body.containsKey('merchant_wallets')) {
        return CashierWalletsModel.fromJson(body);
      }
      if (body['content'] is Map<String, dynamic>) {
        return CashierWalletsModel.fromJson(body['content'] as Map<String, dynamic>);
      }
      if (body['data'] is Map<String, dynamic>) {
        return CashierWalletsModel.fromJson(body['data'] as Map<String, dynamic>);
      }
      return CashierWalletsModel.fromJson(body);
    }
    return CashierWalletsModel(cashierWallets: [], merchantWallets: []);
  }
}
