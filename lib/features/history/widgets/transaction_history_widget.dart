import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/history/domain/models/transaction_model.dart';
import 'package:six_cash/features/history/utils/transaction_formatting.dart';
import 'package:six_cash/features/home/widgets/layered_service_icon.dart';
import 'package:six_cash/util/app_constants.dart';
import 'package:six_cash/util/styles.dart';

const Color _historyPrimary = Color(0xFF0C4A40);
const Color _historySecondary = Color(0xFF278D5B);
const Color _historyGrey = Color(0xFF9AA2AD);

class TransactionHistoryWidget extends StatelessWidget {
  final Transactions? transactions;
  const TransactionHistoryWidget({Key? key, this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final item = transactions;
    if (item == null) return const SizedBox.shrink();
    final isCredit = (item.credit ?? 0) > 0;
    final type = item.transactionType ?? '';
    String? name;
    if (type == AppConstants.sendMoney || type == AppConstants.withdraw) {
      name = item.receiver?.name ?? item.receiver?.phone;
    } else if (type == AppConstants.receivedMoney || type == AppConstants.addMoney || type == AppConstants.cashIn) {
      name = item.sender?.name ?? item.sender?.phone;
    } else {
      name = item.userInfo?.name ?? item.userInfo?.phone;
    }
    final date = formatTransactionDate(item.createdAt);
    return Container(
      height: 72,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Color(0xFFF1F3F4), shape: BoxShape.circle),
            child: LayeredServiceIcon(kind: isCredit ? 0 : 1, small: true),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(getTransactionTitle(type), maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikBold.copyWith(fontSize: 14, color: const Color(0xFF1E1E1E))),
                const SizedBox(height: 2),
                Text(name?.isNotEmpty == true ? '${name!}  •  $date' : date, maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikRegular.copyWith(fontSize: 12, color: _historyGrey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isCredit ? '+' : '-'} ${item.formatAmount()}', textDirection: TextDirection.ltr, style: rubikBold.copyWith(fontSize: 16, color: isCredit ? _historySecondary : _historyPrimary)),
              const SizedBox(height: 3),
              Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1), decoration: BoxDecoration(color: (isCredit ? _historySecondary : _historyPrimary).withOpacity(.10), borderRadius: BorderRadius.circular(20)), child: Text(isCredit ? 'وارد' : 'صادر', style: rubikMedium.copyWith(fontSize: 10, color: isCredit ? _historySecondary : _historyPrimary))),
            ],
          ),
        ],
      ),
    );
  }
}
