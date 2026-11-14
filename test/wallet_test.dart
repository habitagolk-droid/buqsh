import 'package:flutter_test/flutter_test.dart';
import 'package:six_cash/models/wallet_model.dart';
import 'package:six_cash/providers/wallet_provider.dart';
import 'package:six_cash/services/exchange_rate_service.dart';

void main() {
  group('WalletModel Tests', () {
    test('WalletModel JSON serialization and deserialization', () {
      final model = WalletModel(
        id: 9,
        currencyCode: 'USD',
        currencySymbol: '\$',
        currencyName: 'US Dollar',
        currentBalance: 50030.0,
        baseEquivalent: 26515900.0,
        isDefault: false,
        pendingBalance: 0.0,
      );

      final json = model.toJson();
      expect(json['currency_code'], 'USD');
      expect(json['current_balance'], 50030.0);
      expect(json['base_equivalent'], 26515900.0);
      expect(json['is_default'], 0);

      final fromJson = WalletModel.fromJson(json);
      expect(fromJson.id, 9);
      expect(fromJson.currencyCode, 'USD');
      expect(fromJson.currentBalance, 50030.0);
      expect(fromJson.baseEquivalent, 26515900.0);
      expect(fromJson.isDefault, false);
    });
  });

  group('ExchangeRateService Tests', () {
    final service = ExchangeRateService.instance;

    test('USD to YER base equivalent exact match (50,030 USD == 26,515,900 YER)', () {
      final baseEquivalent = service.toBaseEquivalent(50030.0, 'USD');
      expect(baseEquivalent, 26515900.0);
    });

    test('SAR to YER base equivalent calculation', () {
      final baseEquivalent = service.toBaseEquivalent(100.0, 'SAR');
      expect(baseEquivalent, 14000.0);
    });

    test('Exchange rate between USD and SAR', () {
      final rate = service.getExchangeRate('USD', 'SAR');
      // 530 / 140 = 3.785714
      expect(rate, closeTo(3.785714, 0.001));
    });

    test('Fee calculation and preview exchange', () {
      final preview = service.previewExchange(
        fromCurrency: 'USD',
        toCurrency: 'YER',
        amount: 1000.0,
        feePercentage: 0.005,
      );

      expect(preview['fee'], 5.0); // 0.5% of 1000 = 5
      // Net amount = (1000 - 5) * 530 = 995 * 530 = 527,350
      expect(preview['netConvertedAmount'], 527350.0);
    });
  });

  group('WalletService & WalletProvider Logic Tests', () {
    test('Default wallet identification and total balance calculation', () {
      final provider = WalletProvider();
      final initialWallets = [
        WalletModel(
          id: 8,
          currencyCode: 'YER',
          currencySymbol: '﷼',
          currencyName: 'الريال اليمني',
          currentBalance: 1000.0,
          baseEquivalent: 1000.0,
          isDefault: true,
          pendingBalance: 0.0,
        ),
        WalletModel(
          id: 9,
          currencyCode: 'USD',
          currencySymbol: '\$',
          currencyName: 'الدولار الأمريكي',
          currentBalance: 100.0,
          baseEquivalent: 53000.0,
          isDefault: false,
          pendingBalance: 0.0,
        ),
      ];

      provider.setWallets(initialWallets);

      expect(provider.defaultWallet?.currencyCode, 'YER');
      expect(provider.totalBaseBalance, 54000.0);
      expect(provider.getWalletByCode('USD')?.currentBalance, 100.0);
    });
  });
}
