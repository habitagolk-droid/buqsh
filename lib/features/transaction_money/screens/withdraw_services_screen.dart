import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/transaction_money/screens/transaction_balance_input_screen.dart';
import 'package:six_cash/helper/transaction_type.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';

import 'package:six_cash/features/requested_money/screens/requested_money_list_screen.dart';
import 'package:six_cash/features/transaction_money/screens/transaction_money_screen.dart';

class WithdrawServicesScreen extends StatelessWidget {
  const WithdrawServicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbarWidget(title: 'withdraw_services_title'.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          children: [
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // البطاقة الأولى: طلب سحب نقدي
            _ServiceCard(
              icon: Icons.money_outlined,
              title: 'withdraw_request_title'.tr,
              description: 'withdraw_request_desc'.tr,
              onTap: () => Get.to(() => const TransactionBalanceInputScreen(
                    transactionType: TransactionType.withdrawRequest,
                  )),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // البطاقة الثانية: طلب أموال جديد
            _ServiceCard(
              icon: Icons.request_page_outlined,
              title: 'request_money_title'.tr,
              description: 'request_money_desc'.tr,
              onTap: () => Get.to(() => const TransactionMoneyScreen(
                    transactionType: TransactionType.requestMoney,
                  )),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // البطاقة الثالثة: قائمة الطلبات الواردة
            _ServiceCard(
              icon: Icons.move_to_inbox_outlined,
              title: 'requests'.tr,
              description: 'طلبات الأموال الواردة إليك من المستخدمين',
              onTap: () => Get.to(() => const RequestedMoneyListScreen(
                    requestType: RequestType.request,
                  )),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // البطاقة الرابعة: قائمة طلباتي المرسلة
            _ServiceCard(
              icon: Icons.outbox_outlined,
              title: 'send_requests'.tr,
              description: 'طلبات الأموال التي أرسلتها للآخرين',
              onTap: () => Get.to(() => const RequestedMoneyListScreen(
                    requestType: RequestType.sendRequest,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ColorResources.primaryColor.withOpacity(0.08),
              ),
              child: Icon(
                icon,
                size: 28,
                color: ColorResources.primaryColor,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: rubikMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ColorResources.getGreyColor(),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: ColorResources.getGreyColor(),
            ),
          ],
        ),
      ),
    );
  }
}
