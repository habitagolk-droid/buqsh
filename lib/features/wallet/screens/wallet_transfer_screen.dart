import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';
import 'package:six_cash/features/transaction_money/screens/send_money_screen.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class WalletTransferScreen extends StatelessWidget {
  const WalletTransferScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbarWidget(title: 'wallet_transfer'.tr),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // --- الخيار 1: تحويل إلى مشترك ---
            _TransferOptionCard(
              icon: Icons.send_outlined,
              title: 'svc_send_to_subscriber'.tr,
              subtitle: 'svc_send_to_subscriber_desc'.tr,
              onTap: () => Get.to(() => const SendMoneyScreen()),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // --- الخيار 2: تحويل بين حساباتي (المصارفة) ---
            _TransferOptionCard(
              icon: Icons.swap_horiz_outlined,
              title: 'svc_exchange'.tr,
              subtitle: 'svc_exchange_desc'.tr,
              onTap: () => Get.toNamed(RouteHelper.exchange),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // --- الخيار 3: طلب استلام حوالة ---
            _TransferOptionCard(
              icon: Icons.arrow_downward_outlined,
              title: 'svc_request_remit'.tr,
              subtitle: 'svc_request_remit_desc'.tr,
              onTap: () => showCustomSnackBarHelper('coming_soon'.tr),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TransferOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                    subtitle,
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
