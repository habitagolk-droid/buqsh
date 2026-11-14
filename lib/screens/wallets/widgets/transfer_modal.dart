import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/theme_config.dart';
import '../../../providers/wallet_provider.dart';
import '../../../services/exchange_rate_service.dart';
import '../../../utils/currency_formatter.dart';

class TransferModal extends StatefulWidget {
  const TransferModal({
    super.key,
    this.initialFromCurrency,
  });

  final String? initialFromCurrency;

  static Future<void> show(BuildContext context, {String? initialFromCurrency}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferModal(initialFromCurrency: initialFromCurrency),
    );
  }

  @override
  State<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends State<TransferModal> {
  final TextEditingController _amountController = TextEditingController();
  late String _fromCurrency;
  late String _toCurrency;
  double _inputAmount = 0.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fromCurrency = widget.initialFromCurrency ?? 'USD';
    _toCurrency = _fromCurrency == 'YER' ? 'USD' : 'YER';
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final parsed = double.tryParse(_amountController.text) ?? 0.0;
    if (parsed != _inputAmount) {
      setState(() {
        _inputAmount = parsed;
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  Future<void> _executeTransfer(WalletProvider provider) async {
    if (_inputAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح للتحويل')),
      );
      return;
    }

    final fromWallet = provider.getWalletByCode(_fromCurrency);
    if (fromWallet == null || fromWallet.currentBalance < _inputAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرصيد المتوفر غير كافٍ لإتمام التحويل')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final success = await provider.transferBetweenWallets(
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      amount: _inputAmount,
    );

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('تم التحويل بنجاح من $_fromCurrency إلى $_toCurrency'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.primary,
          content: Text(provider.error ?? 'فشلت عملية التحويل'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final fromWallet = provider.getWalletByCode(_fromCurrency);
    final availableBalance = fromWallet?.currentBalance ?? 0.0;

    final exchange = ExchangeRateService.instance.previewExchange(
      fromCurrency: _fromCurrency,
      toCurrency: _toCurrency,
      amount: _inputAmount,
    );

    final rate = exchange['rate'] as double;
    final fee = exchange['fee'] as double;
    final netAmount = exchange['netConvertedAmount'] as double;

    final currencies = ['YER', 'USD', 'SAR'];

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تحويل بين المحافظ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // العملة المصدر والهدف
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('من محفظة', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _fromCurrency,
                            isExpanded: true,
                            items: currencies
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _fromCurrency = val;
                                  if (_toCurrency == val) {
                                    _toCurrency = currencies.firstWhere((c) => c != val);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: IconButton.filledTonal(
                    onPressed: _swapCurrencies,
                    icon: const Icon(Icons.swap_horiz),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('إلى محفظة', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _toCurrency,
                            isExpanded: true,
                            items: currencies
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _toCurrency = val;
                                  if (_fromCurrency == val) {
                                    _fromCurrency = currencies.firstWhere((c) => c != val);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // إدخال المبلغ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('المبلغ المراد تحويله', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'المتوفر: ${CurrencyFormatter.format(availableBalance, currency: _fromCurrency)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                suffixIcon: TextButton(
                  onPressed: () {
                    _amountController.text = availableBalance.toString();
                  },
                  child: const Text('الكل', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // تفاصيل العملية
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('سعر الصرف', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text('1 $_fromCurrency = $rate $_toCurrency',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('الرسوم المقدرة (0.5%)',
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                      Text(
                        CurrencyFormatter.format(fee, currency: _fromCurrency),
                        style: const TextStyle(fontSize: 13, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المبلغ المستلم التقديري',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        CurrencyFormatter.format(netAmount, currency: _toCurrency),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // زر التأكيد
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isSubmitting || _inputAmount <= 0
                    ? null
                    : () => _executeTransfer(provider),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'تأكيد التحويل الآن',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
