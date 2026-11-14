import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/history/domain/models/transaction_model.dart';
import 'package:six_cash/features/language/controllers/localization_controller.dart';
import 'package:six_cash/features/history/utils/transaction_formatting.dart';
import 'package:six_cash/util/app_constants.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class TransactionHistoryWidget extends StatelessWidget {
  final Transactions? transactions;

  const TransactionHistoryWidget({Key? key, this.transactions})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactions == null) return const SizedBox.shrink();

    final item = transactions;
    final bool isCredit = (item?.credit ?? 0) > 0;

    String? userPhone;
    String? userName;

    try {
      final type = item?.transactionType ?? '';
      if (type == AppConstants.sendMoney) {
        userPhone = item?.receiver?.phone;
        userName = item?.receiver?.name;
      } else if (type == AppConstants.receivedMoney) {
        userPhone = item?.sender?.phone;
        userName = item?.sender?.name;
      } else if (type == AppConstants.addMoney || type == 'add_money_bonus') {
        userPhone = item?.sender?.phone;
        userName = item?.sender?.name;
      } else if (type == AppConstants.cashIn) {
        userPhone = item?.sender?.phone;
        userName = item?.sender?.name;
      } else if (type == AppConstants.withdraw) {
        userPhone = item?.receiver?.phone;
        userName = item?.receiver?.name;
      } else {
        userPhone = item?.userInfo?.phone;
        userName = item?.userInfo?.name;
      }
    } catch (_) {
      userName = 'no_user'.tr;
    }

    userPhone = formatTransactionPhone(userPhone);
    final formattedDate = formatTransactionDate(item?.createdAt);

    final isLtr = Get.isRegistered<LocalizationController>()
        ? Get.find<LocalizationController>().isLtr
        : false;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      child: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  // أيقونة سهم (أخضر للوارد، أحمر للصادر)
                  Container(
                    height: 44,
                    width: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCredit
                          ? Colors.green.withOpacity(0.12)
                          : Colors.redAccent.withOpacity(0.12),
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? Colors.green : Colors.redAccent,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  // تفاصيل المعاملة (النوع، الاسم، الهاتف، المعرّف)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getTransactionTitle(item?.transactionType),
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                        if (userName != null && userName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                        if (userPhone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            userPhone,
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: ColorResources.getGreyColor(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          'TrxID: ${item?.transactionId ?? ''}',
                          style: rubikRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: ColorResources.getGreyColor().withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  // المبلغ بالعملة الصحيحة ($، ر.س، يل)
                  Text(
                    '${isCredit ? '+' : '-'} ${item?.formatAmount() ?? ''}',
                    style: rubikSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: isCredit ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: ColorResources.getGreyColor().withOpacity(0.15),
              ),
            ],
          ),

          // التاريخ والوقت في الزاوية السفلية
          if (formattedDate.isNotEmpty)
            Positioned(
              bottom: 4,
              right: isLtr ? 4 : null,
              left: isLtr ? null : 4,
              child: Text(
                formattedDate,
                style: rubikRegular.copyWith(
                  fontSize: 10,
                  color: ColorResources.getHintColor(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
