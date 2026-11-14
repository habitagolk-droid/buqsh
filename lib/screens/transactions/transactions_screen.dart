import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme_config.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  static final List<TransactionModel> _demoTransactions = [
    TransactionModel(
      id: 'TRX-2014',
      type: 'إرسال',
      amount: 250.00,
      currency: 'SAR',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      senderName: 'أحمد علي',
      receiverName: 'محمود',
    ),
    TransactionModel(
      id: 'TRX-2015',
      type: 'إيداع',
      amount: 1200.00,
      currency: 'SAR',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      senderName: 'الرصيد',
      receiverName: 'Mhros Lutf',
    ),
    TransactionModel(
      id: 'TRX-2016',
      type: 'شراء',
      amount: 150.00,
      currency: 'YER',
      status: 'pending',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      senderName: 'متجر',
      receiverName: 'محل الهدية',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('المعاملات'),
        centerTitle: true,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          final items = provider.transactions.isEmpty ? _demoTransactions : provider.transactions;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final isIncome = item.type.toLowerCase().contains('إيداع') || item.type.toLowerCase().contains('deposit');
              final sign = isIncome ? '+' : '-';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.type,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${item.senderName} → ${item.receiverName}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.createdAt.toLocal().toString().split(' ')[0],
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$sign ${item.amount.toStringAsFixed(2)} ${item.currency}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isIncome ? AppTheme.success : AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.status,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
