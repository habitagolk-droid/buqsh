import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../models/wallet_model.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/currency_formatter.dart';
import '../wallets/widgets/transfer_modal.dart';

class WalletDetailScreen extends StatelessWidget {
  const WalletDetailScreen({
    super.key,
    this.wallet,
    this.title,
    this.amount,
    this.currency,
    this.color,
  });

  final WalletModel? wallet;
  final String? title;
  final double? amount;
  final String? currency;
  final Color? color;

  Color _resolveColor(String code) {
    switch (code.toUpperCase()) {
      case 'YER':
        return const Color(0xFFC8102E);
      case 'USD':
        return const Color(0xFF2E7D32);
      case 'SAR':
        return const Color(0xFF00695C);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WalletProvider>();
    final currentWallet = wallet != null
        ? (provider.getWalletByCode(wallet!.currencyCode) ?? wallet!)
        : null;

    final displayTitle = currentWallet?.currencyName ?? title ?? 'تفاصيل المحفظة';
    final displayCurrency = currentWallet?.currencyCode ?? currency ?? 'YER';
    final displayAmount = currentWallet?.currentBalance ?? amount ?? 0.0;
    final displayColor = color ?? _resolveColor(displayCurrency);
    final isDefault = currentWallet?.isDefault ?? false;

    // سجل حركات تجريبي مخصص حسب العملة
    final items = [
      {
        'label': 'إيداع رصيد',
        'amount': '+ ${CurrencyFormatter.format(displayAmount * 0.15 + 100, currency: displayCurrency)}',
        'type': 'credit',
        'date': 'اليوم، 11:30 ص',
      },
      {
        'label': 'تحويل صادر',
        'amount': '- ${CurrencyFormatter.format(displayAmount * 0.05 + 50, currency: displayCurrency)}',
        'type': 'debit',
        'date': 'أمس، 04:15 م',
      },
      {
        'label': 'استلام حوالة',
        'amount': '+ ${CurrencyFormatter.format(displayAmount * 0.2 + 200, currency: displayCurrency)}',
        'type': 'credit',
        'date': '11 أكتوبر 2026',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(displayTitle),
        centerTitle: true,
        actions: [
          if (currentWallet != null && !isDefault)
            TextButton(
              onPressed: () {
                provider.setDefaultWallet(currentWallet.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.success,
                    content: Text('تم تعيين ${currentWallet.currencyName} كمحفظة افتراضية'),
                  ),
                );
              },
              child: const Text('تعيين كافتراضي', style: TextStyle(color: AppTheme.primary)),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // بطاقة الرصيد
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [displayColor, displayColor.withValues(alpha: 0.82)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: displayColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الرصيد الحالي',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'المحفظة الافتراضية',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      CurrencyFormatter.format(displayAmount, currency: displayCurrency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (displayCurrency != 'YER' && currentWallet != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ما يعادل: ${CurrencyFormatter.format(currentWallet.baseEquivalent, currency: 'YER')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // أزرار العمليات السريعة (إيداع - سحب - تحويل)
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add,
                      label: 'إيداع',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خدمة الإيداع لمحفظة $displayCurrency')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.arrow_upward,
                      label: 'سحب',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('خدمة السحب لمحفظة $displayCurrency')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.swap_horiz,
                      label: 'تحويل',
                      onTap: () {
                        TransferModal.show(
                          context,
                          initialFromCurrency: displayCurrency,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // بطاقات الإحصائيات
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'الإيرادات',
                      value: CurrencyFormatter.format(displayAmount * 0.4 + 500, currency: displayCurrency),
                      color: AppTheme.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'المصروفات',
                      value: CurrencyFormatter.format(displayAmount * 0.15 + 150, currency: displayCurrency),
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'آخر الحركات في محفظة $displayCurrency',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isCredit = item['type'] == 'credit';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                (isCredit ? AppTheme.success : AppTheme.primary)
                                    .withValues(alpha: 0.12),
                            child: Icon(
                              isCredit
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: isCredit
                                  ? AppTheme.success
                                  : AppTheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['label'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  item['date'] as String,
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            item['amount'] as String,
                            style: TextStyle(
                              color: isCredit
                                  ? AppTheme.success
                                  : AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
