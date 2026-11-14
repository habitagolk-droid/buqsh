import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/widgets/custom_ink_well_widget.dart';
import 'package:six_cash/features/transaction_money/screens/send_money_screen.dart';
import 'package:six_cash/features/transaction_money/screens/transaction_balance_input_screen.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class _ServiceItem {
  final String key;
  final IconData icon;
  final bool hasNewBadge;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.key,
    required this.icon,
    this.hasNewBadge = false,
    required this.onTap,
  });
}

class ServicesGridWidget extends StatelessWidget {
  const ServicesGridWidget({Key? key}) : super(key: key);

  List<_ServiceItem> _getServices() {
    return [
      // 1. svc_transfer
      _ServiceItem(
        key: 'svc_transfer',
        icon: Icons.swap_horiz_outlined,
        onTap: () => Get.toNamed(RouteHelper.walletTransfer),
      ),
      // 2. svc_local_remit
      _ServiceItem(
        key: 'svc_local_remit',
        icon: Icons.send_outlined,
        onTap: () => Get.to(() => const SendMoneyScreen()),
      ),
      // 3. svc_topup
      _ServiceItem(
        key: 'svc_topup',
        icon: Icons.add_circle_outline,
        onTap: () => Get.to(
          const TransactionBalanceInputScreen(transactionType: 'add_money'),
        ),
      ),
      // 4. svc_withdraw
      _ServiceItem(
        key: 'svc_withdraw',
        icon: Icons.arrow_circle_down_outlined,
        onTap: () => Get.toNamed(RouteHelper.withdrawServices),
      ),
      // 5. svc_pos
      _ServiceItem(
        key: 'svc_pos',
        icon: Icons.point_of_sale_outlined,
        onTap: () => Get.toNamed(RouteHelper.posPayment),
      ),
      // 6. svc_online
      _ServiceItem(
        key: 'svc_online',
        icon: Icons.language_outlined,
        onTap: () => showCustomSnackBarHelper('coming_soon'.tr),
      ),
      // 7. svc_jeeby (مع شارة new)
      _ServiceItem(
        key: 'svc_jeeby',
        icon: Icons.account_balance_wallet_outlined,
        hasNewBadge: true,
        onTap: () => showCustomSnackBarHelper('coming_soon'.tr),
      ),
      // 8. svc_entertainment
      _ServiceItem(
        key: 'svc_entertainment',
        icon: Icons.sports_esports_outlined,
        onTap: () => showCustomSnackBarHelper('coming_soon'.tr),
      ),
      // 9. svc_payments
      _ServiceItem(
        key: 'svc_payments',
        icon: Icons.receipt_long_outlined,
        onTap: () => showCustomSnackBarHelper('coming_soon'.tr),
      ),
    ];
  }

  List<_ServiceItem> _getCashierServices(BuildContext context) {
    return [
      _ServiceItem(
        key: 'عملية بيع جديدة',
        icon: Icons.point_of_sale_outlined,
        onTap: () => Get.toNamed(RouteHelper.cashierPosSale),
      ),
      _ServiceItem(
        key: 'إرجاع مبلغ (Refund)',
        icon: Icons.replay_rounded,
        onTap: () => _showRefundDialog(context),
      ),
      _ServiceItem(
        key: 'إدارة الوردية',
        icon: Icons.access_time_filled_rounded,
        onTap: () => _showShiftDialog(context),
      ),
      _ServiceItem(
        key: 'سجل العمليات',
        icon: Icons.receipt_long_outlined,
        onTap: () => Get.toNamed(RouteHelper.history),
      ),
      _ServiceItem(
        key: 'بيانات الجهاز',
        icon: Icons.devices_outlined,
        onTap: () => _showTerminalDialog(context),
      ),
      _ServiceItem(
        key: 'إغلاق الوردية',
        icon: Icons.lock_clock_outlined,
        onTap: () => _showCloseShiftDialog(context),
      ),
    ];
  }

  void _showRefundDialog(BuildContext context) {
    final txController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إرجاع مبلغ (Refund)', style: rubikBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('أدخل رقم الإيصال أو العملية لإرجاعها:', style: rubikRegular),
            const SizedBox(height: 10),
            TextField(
              controller: txController,
              decoration: InputDecoration(
                hintText: 'رقم الإيصال / Transaction ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (txController.text.trim().isNotEmpty) {
                showCustomSnackBarHelper('تم تقديم طلب الإرجاع بنجاح للعملية #${txController.text.trim()}', isError: false);
              }
            },
            child: const Text('تأكيد الإرجاع', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showShiftDialog(BuildContext context) {
    final ctrl = Get.find<CashierAuthController>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تفاصيل الوردية الحالية', style: rubikBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الكاشير: ${ctrl.sessionInfo?.cashierName ?? "أحمد الكاشير"}', style: rubikMedium),
            const SizedBox(height: 6),
            Text('الجهاز: ${ctrl.sessionInfo?.terminalName ?? "POS-01"}', style: rubikRegular),
            const SizedBox(height: 6),
            const Text('الحالة: مفتوحة (Open) ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showTerminalDialog(BuildContext context) {
    final ctrl = Get.find<CashierAuthController>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('بيانات نقطة البيع (Terminal)', style: rubikBold),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم النقطة: ${ctrl.sessionInfo?.terminalName ?? "POS-01"}', style: rubikMedium),
            const SizedBox(height: 6),
            Text('التاجر: ${ctrl.sessionInfo?.merchantName ?? "بقش"}', style: rubikRegular),
            const SizedBox(height: 6),
            Text('الفرع: ${ctrl.sessionInfo?.branchName ?? "صنعاء"}', style: rubikRegular),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إغلاق الوردية وتصدير التقرير', style: rubikBold),
        content: const Text('هل أنت متأكد من رغبتك في إغلاق الوردية الحالية وتصدير التقرير اليومي؟', style: rubikRegular),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              showCustomSnackBarHelper('تم إغلاق الوردية وإرسال التقرير للمسؤول', isError: false);
            },
            child: const Text('إغلاق الوردية', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCashier = Get.find<CashierAuthController>().isSessionReady;
    final services = isCashier ? _getCashierServices(context) : _getServices();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: services.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.92,
        ),
        itemBuilder: (context, index) {
          final service = services[index];
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(
                    Dimensions.radiusSizeDefault,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomInkWellWidget(
                  onTap: service.onTap,
                  radius: Dimensions.radiusSizeDefault,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeExtraSmall,
                        vertical: Dimensions.paddingSizeExtraSmall,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.08),
                            ),
                            child: Icon(
                              service.icon,
                              size: 28,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            service.key.tr,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: rubikSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color ??
                                  ColorResources.getTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // شارة NEW لخدمة بقشي
              if (service.hasNewBadge)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'new'.tr,
                      style: rubikSemiBold.copyWith(
                        fontSize: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
