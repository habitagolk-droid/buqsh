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
        json['cashierWallet'] ??
        json['wallets'] ??
        json['wallet'];

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
    if (body is List) {
      return CashierWalletsModel(
        cashierWallets: body
            .whereType<Map>()
            .map((item) => WalletModel.fromJson(Map<String, dynamic>.from(item)))
            .toList(),
        merchantWallets: const [],
      );
    }
    if (body is Map<String, dynamic>) {
      if (body.containsKey('cashier_wallets') ||
          body.containsKey('cashier_wallet') ||
          body.containsKey('cashierWallets') ||
          body.containsKey('cashierWallet') ||
          body.containsKey('wallets') ||
          body.containsKey('wallet') ||
          body.containsKey('merchant_wallets')) {
        return CashierWalletsModel.fromJson(body);
      }
      final wrapped = body['content'] ?? body['data'];
      if (wrapped is Map || wrapped is List) {
        return CashierWalletsModel.fromResponse(wrapped);
      }
      return CashierWalletsModel.fromJson(body);
    }
    return CashierWalletsModel(cashierWallets: [], merchantWallets: []);
  }
}
