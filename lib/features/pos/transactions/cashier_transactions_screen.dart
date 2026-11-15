import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/transactions/cashier_transaction.dart';
import 'package:six_cash/features/pos/transactions/cashier_transactions_controller.dart';
import 'package:six_cash/util/styles.dart';

class CashierTransactionsScreen extends StatefulWidget {
  const CashierTransactionsScreen({super.key});

  @override
  State<CashierTransactionsScreen> createState() =>
      _CashierTransactionsScreenState();
}

class _CashierTransactionsScreenState extends State<CashierTransactionsScreen> {
  static const _primary = Color(0xFF086048);
  String? _selectedType;

  String _amount(CashierTransaction transaction) {
    final value = transaction.amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (match) => '${match[1]},',
        );
    final currency = transaction.currencyCode.trim();
    return currency.isEmpty ? value : '$value $currency';
  }

  String _date(String value) {
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    final date = '${parsed.year.toString().padLeft(4, '0')}-'
        '${parsed.month.toString().padLeft(2, '0')}-'
        '${parsed.day.toString().padLeft(2, '0')}';
    final time = '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';
    return '$date · $time';
  }

  String _typeLabel(String value) {
    if (value.trim().isEmpty) return 'عملية';
    final words = value.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    return words[0].toUpperCase() + words.substring(1);
  }

  Color _statusColor(String status) {
    final value = status.toLowerCase();
    if (['success', 'completed', 'approved', 'successful', 'paid'].contains(value)) {
      return const Color(0xFF238636);
    }
    if (['pending', 'processing', 'in_progress'].contains(value)) {
      return const Color(0xFFB7791F);
    }
    if (['failed', 'rejected', 'cancelled', 'canceled', 'declined'].contains(value)) {
      return const Color(0xFFC62828);
    }
    return Colors.blueGrey;
  }

  void _showDetails(BuildContext context, CashierTransaction transaction) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_typeLabel(transaction.transactionType),
                  style: rubikBold.copyWith(fontSize: 20)),
              const SizedBox(height: 16),
              _detailRow('المبلغ', _amount(transaction)),
              _detailRow('الحالة', transaction.status),
              _detailRow('التاريخ', _date(transaction.createdAt)),
              _detailRow('رقم الحركة', transaction.id),
              _detailRow('رقم الإيصال', transaction.receiptNumber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: rubikRegular.copyWith(color: Colors.black54))),
            const SizedBox(width: 16),
            Flexible(child: Text(value.isEmpty ? '—' : value, textAlign: TextAlign.end, style: rubikMedium)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<CashierAuthController>();
    return GetBuilder<CashierTransactionsController>(
      init: CashierTransactionsController(authRepo: authController.authRepo),
      builder: (controller) {
        final types = controller.transactions
            .map((transaction) => transaction.transactionType)
            .where((type) => type.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        final visibleTransactions = _selectedType == null
            ? controller.transactions
            : controller.transactions
                .where((transaction) => transaction.transactionType == _selectedType)
                .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          appBar: AppBar(
            title: Text('history'.tr, style: rubikBold),
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'تحديث',
                onPressed: controller.isLoading
                    ? null
                    : () => controller.fetchTransactions(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => controller.fetchTransactions(forceRefresh: true),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (types.isNotEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 62,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('الكل', null),
                          for (final type in types) _filterChip(_typeLabel(type), type),
                        ],
                      ),
                    ),
                  ),
                if (controller.isLoading && controller.transactions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (controller.errorMessage != null && controller.transactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _messageState(
                      icon: Icons.cloud_off_outlined,
                      message: controller.errorMessage!,
                      action: TextButton.icon(
                        onPressed: () => controller.fetchTransactions(forceRefresh: true),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text('retry'.tr),
                      ),
                    ),
                  )
                else if (visibleTransactions.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _messageState(
                      icon: Icons.receipt_long_outlined,
                      message: 'لا توجد حركات لعرضها',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    sliver: SliverList.separated(
                      itemCount: visibleTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (context, index) => _transactionCard(
                        context,
                        visibleTransactions[index],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String? value) {
    final selected = _selectedType == value;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedType = value),
        selectedColor: _primary.withValues(alpha: 0.14),
        labelStyle: rubikMedium.copyWith(color: selected ? _primary : Colors.black87),
        side: BorderSide(color: selected ? _primary : Colors.black12),
      ),
    );
  }

  Widget _messageState({required IconData icon, required String message, Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: rubikRegular),
            if (action != null) ...[const SizedBox(height: 8), action],
          ],
        ),
      ),
    );
  }

  Widget _transactionCard(BuildContext context, CashierTransaction transaction) {
    final statusColor = _statusColor(transaction.status);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(context, transaction),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.swap_horiz_rounded, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_typeLabel(transaction.transactionType),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikBold),
                    const SizedBox(height: 4),
                    Text(
                      transaction.receiptNumber.isEmpty
                          ? 'رقم الحركة: ${transaction.id}'
                          : 'الإيصال: ${transaction.receiptNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: rubikRegular.copyWith(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(_date(transaction.createdAt),
                        style: rubikRegular.copyWith(fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_amount(transaction),
                      style: rubikBold.copyWith(fontSize: 14, color: _primary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      transaction.status.isEmpty ? '—' : transaction.status,
                      style: rubikMedium.copyWith(fontSize: 10, color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
