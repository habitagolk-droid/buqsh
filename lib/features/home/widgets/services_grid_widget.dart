import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:six_cash/common/widgets/custom_ink_well_widget.dart';
import 'package:six_cash/features/pos/screens/cashier_return_change_screen.dart';
import 'package:six_cash/features/pos/screens/pos_payment_screen.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/features/home/widgets/layered_service_icon.dart';

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

  static const Color _colorPrimaryDark = Color(0xFF0C4A40);
  static const Color _colorSecondary = Color(0xFF278D5B);
  static const Color _colorAccent = Color(0xFFD4E157);
  static const Color _colorMint = Color(0xFF50D0A0);
  static const Color _colorIconCircleBg = Color(0xFFE0F5EC);
  static const Color _colorScreenBg = Color(0xFFF8F9FA);
  static const Color _colorCardBg = Color(0xFFFFFFFF);

  bool _hasAccentDetail(IconData icon) =>
      icon == Icons.swap_horiz_outlined ||
      icon == Icons.send_outlined ||
      icon == Icons.add_circle_outline ||
      icon == Icons.arrow_circle_down_outlined ||
      icon == Icons.point_of_sale_outlined ||
      icon == Icons.receipt_long_outlined;

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
        onTap: () => Get.toNamed(RouteHelper.sendMoney),
      ),
      // 3. svc_topup
      _ServiceItem(
        key: 'svc_topup',
        icon: Icons.add_circle_outline,
        onTap: () => Get.toNamed(RouteHelper.addMoney),
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
        key: 'cashier_return_purchases',
        icon: Icons.assignment_return_outlined,
        onTap: () => _showRefundDialog(context),
      ),
      _ServiceItem(
        key: 'cashier_change_calculator',
        icon: Icons.calculate_outlined,
        onTap: () => Get.to(() => const CashierReturnChangeScreen()),
      ),
      _ServiceItem(
        key: 'cashier_topup_payment',
        icon: Icons.payment_outlined,
        onTap: () => Get.toNamed(RouteHelper.posPayment),
      ),
      _ServiceItem(
        key: 'cashier_reports',
        icon: Icons.bar_chart_outlined,
        onTap: () => Get.toNamed(RouteHelper.history),
      ),
      _ServiceItem(
        key: 'cashier_favorites',
        icon: Icons.favorite_border_rounded,
        onTap: () => Get.to(() => const PosPaymentScreen(showFavoritesOnOpen: true)),
      ),
    ];
  }

  Future<void> _showRefundDialog(BuildContext context) async {
    final receiptController = TextEditingController();
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('cashier_return_purchases'.tr, style: rubikBold),
        content: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: receiptController,
              decoration: InputDecoration(labelText: 'receipt_number'.tr),
            ),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'cashier_refund_amount'.tr),
            ),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(labelText: 'cashier_refund_reason'.tr),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40)),
            onPressed: () async {
              final receipt = receiptController.text.trim();
              final amount = double.tryParse(amountController.text.trim());
              final reason = reasonController.text.trim();
              if (receipt.isEmpty || amount == null || amount <= 0 || reason.isEmpty) {
                showCustomSnackBarHelper('please_fill_all_fields'.tr, isError: true);
                return;
              }
              Navigator.of(ctx).pop();
              await _confirmAndSubmitRefund(
                context,
                receiptNumber: receipt,
                amount: amount,
                reason: reason,
              );
            },
            child: Text('execute_transaction'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    receiptController.dispose();
    amountController.dispose();
    reasonController.dispose();
  }

  Future<void> _confirmAndSubmitRefund(
    BuildContext context, {
    required String receiptNumber,
    required double amount,
    required String reason,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('cashier_return_purchases'.tr, style: rubikBold),
        content: Text(
          '${'receipt_number'.tr}: $receiptNumber\n${'cashier_refund_amount'.tr}: $amount\n${'cashier_refund_reason'.tr}: $reason\n\n${'authenticate_to_confirm_transaction'.tr}',
          style: rubikRegular,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('cancel'.tr)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('execute_transaction'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    bool authenticated;
    try {
      authenticated = await LocalAuthentication().authenticate(
        localizedReason: 'authenticate_to_confirm_transaction'.tr,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } catch (_) {
      authenticated = false;
    }
    if (!authenticated) {
      showCustomSnackBarHelper('transaction_authentication_cancelled'.tr, isError: true);
      return;
    }

    final response = await Get.find<CashierAuthController>().authRepo.submitRefund(
      receiptNumber: receiptNumber,
      amount: amount,
      reason: reason,
    );
    final body = response.body;
    String? serverMessage;
    if (body is Map) {
      serverMessage = (body['message'] ?? body['error'])?.toString();
      final errors = body['errors'];
      if ((serverMessage == null || serverMessage.isEmpty) && errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        serverMessage = first is List && first.isNotEmpty ? first.first.toString() : first.toString();
      }
    }
    final succeeded = response.statusCode != null &&
        response.statusCode! >= 200 && response.statusCode! < 300;
    showCustomSnackBarHelper(
      serverMessage ?? (succeeded ? 'cashier_refund_success'.tr : 'cashier_refund_failed'.tr),
      isError: !succeeded,
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

    return Container(
      color: _colorScreenBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final service = services[index];
            const cardRadius = 16.0;
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _colorCardBg,
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F003840),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: CustomInkWellWidget(
                    onTap: service.onTap,
                    radius: cardRadius,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isCashier
                                ? Container(
                                    width: 48,
                                    height: 48,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _colorIconCircleBg,
                                    ),
                                    child: Icon(
                                      service.icon,
                                      size: 28,
                                      color: _colorSecondary,
                                    ),
                                  )
                                : LayeredServiceIcon(kind: index, small: true),
                            const SizedBox(height: 8),
                            Text(
                              service.key.tr,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _colorSecondary,
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
                        color: _colorMint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'new'.tr,
                        style: rubikSemiBold.copyWith(
                          fontSize: 8,
                          color: _colorPrimaryDark,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
