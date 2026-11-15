import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/features/pos/screens/cashier_wallets_screen.dart';
import 'package:six_cash/features/pos/screens/cashier_pos_sale_screen.dart';
import 'package:six_cash/features/pos/screens/pos_payment_screen.dart';
import 'package:six_cash/features/home/screens/nav_bar_screen.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/images.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';

class CashierHomeScreen extends StatefulWidget {
  const CashierHomeScreen({Key? key}) : super(key: key);

  @override
  State<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends State<CashierHomeScreen> {
  int _currentIndex = 0;
  int _currentNavIndex = 0;

  static const Color kPrimaryColor = Color(0xFF004D40);
  static const Color kLimeColor = Color(0xFFD4E157);
  static const Color kBgColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
  }

  void _onTabSelect(int index) {
    setState(() => _currentNavIndex = index);
    switch (index) {
      case 0:
        setState(() => _currentIndex = 0);
        break;
      case 1:
        Get.toNamed(RouteHelper.notification);
        break;
      case 2:
        Get.toNamed(RouteHelper.history);
        break;
      case 3:
        Get.toNamed(RouteHelper.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const NavBarScreen();
  }

  // ═══════════════════════════════════════════════════════════════
  //  1. تبويب الرئيسية (Dashboard / POS Home)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHomeTab() {
    return GetBuilder<CashierAuthController>(
      builder: (controller) {
        if (controller.isLoading && !controller.isSessionReady) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        return RefreshIndicator(
          color: kPrimaryColor,
          onRefresh: () async {
            await controller.retrySessionInfo();
            await controller.fetchCurrentShift();
            if (Get.isRegistered<CashierWalletController>()) {
              await Get.find<CashierWalletController>().fetchCashierWallets(
                showLoading: false,
              );
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(controller),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildTerminalCard(controller),
                      const SizedBox(height: 14),
                      _buildQuickShiftCard(controller),
                      const SizedBox(height: 18),
                      _buildServicesSectionTitle(),
                      const SizedBox(height: 12),
                      _buildQuickActionsGrid(),
                      const SizedBox(height: 16),
                      _buildStartSaleBigButton(),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(CashierAuthController controller) {
    final info = controller.sessionInfo;
    final cashierName = info?.cashierName ?? 'كاشير معتمد';
    final cashierCode = info?.cashierCode ?? 'CSH-001';

    return Container(
      color: kPrimaryColor,
      child: Container(
        padding: const EdgeInsets.only(
          top: 50,
          left: 18,
          right: 18,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
        ),
        child: Row(
          children: [
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نقطة البيع (POS) 👋',
                    style: rubikRegular.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    cashierName,
                    style: rubikBold.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'كود الكاشير: $cashierCode',
                      style: rubikRegular.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: Dimensions.fontSizeExtraSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                InkWell(
                  onTap: () => controller.retrySessionInfo(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: controller.isSessionInfoLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _confirmLogout(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalCard(CashierAuthController controller) {
    final info = controller.sessionInfo;
    final terminalName = info?.terminalName ?? 'جهاز نقطة البيع';
    final merchantName = info?.merchantName ?? 'بقش للمدفوعات الرقمية';
    final branchName = info?.branchName ?? 'الفرع الرئيسي';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.devices_rounded,
                  color: kPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      terminalName,
                      style: rubikBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: kPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$merchantName • $branchName',
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'متصل',
                      style: rubikMedium.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shiftOpenedAt(Map<String, dynamic>? shift) {
    return shift?['opened_at']?.toString() ??
        shift?['created_at']?.toString() ??
        shift?['shift_number']?.toString() ??
        '—';
  }

  Widget _buildQuickShiftCard(CashierAuthController controller) {
    final shift = controller.currentShift;
    final isOpen = shift != null;
    final openedAt = _shiftOpenedAt(shift);
    final salesCount =
        int.tryParse(
          '${shift?['transactions_count'] ?? shift?['orders_count'] ?? 0}',
        ) ??
        0;
    final totalSales =
        double.tryParse(
          '${shift?['total_sales'] ?? shift?['sales'] ?? shift?['total_amount'] ?? 0}',
        ) ??
        0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
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
              Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    color: kPrimaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'الوردية الحالية',
                    style: rubikBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOpen
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.isShiftLoading
                      ? 'جاري التحديث'
                      : isOpen
                      ? 'مفتوحة'
                      : controller.shiftError ?? 'لا توجد وردية مفتوحة حالياً',
                  style: rubikBold.copyWith(
                    color: isOpen
                        ? const Color(0xFF2E7D32)
                        : Colors.orange[800],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildShiftMetric('بداية الوردية', openedAt),
              _buildShiftMetric('عدد المبيعات', '$salesCount عملية'),
              _buildShiftMetric(
                'المحصل',
                CurrencyFormatter.format(totalSales, currency: 'YER'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftMetric(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: rubikRegular.copyWith(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: rubikBold.copyWith(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildServicesSectionTitle() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        'إجراءات الكاشير السريعة',
        style: rubikBold.copyWith(
          fontSize: Dimensions.fontSizeLarge,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionTile(
          title: 'cashier_return_purchases'.tr,
          subtitle: 'cashier_refund_short'.tr,
          icon: Icons.assignment_return_rounded,
          color: kPrimaryColor,
          onTap: _showRefundDialog,
        ),
        _buildActionTile(
          title: 'cashier_change_calculator'.tr,
          subtitle: 'cashier_change_title'.tr,
          icon: Icons.calculate_rounded,
          color: const Color(0xFF00695C),
          onTap: _showChangeCalculator,
        ),
        _buildActionTile(
          title: 'cashier_topup_payment'.tr,
          subtitle: 'svc_pos'.tr,
          icon: Icons.payment_rounded,
          color: const Color(0xFF1B5E20),
          onTap: () => Get.toNamed(RouteHelper.posPayment),
        ),
        _buildActionTile(
          title: 'cashier_reports'.tr,
          subtitle: 'سجل المبيعات والعمليات',
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF00695C),
          onTap: () => setState(() => _currentIndex = 2),
        ),
        _buildActionTile(
          title: 'cashier_favorites'.tr,
          subtitle: 'favorite_terminals'.tr,
          icon: Icons.favorite_rounded,
          color: const Color(0xFF1B5E20),
          onTap: () => Get.to(
            () => const PosPaymentScreen(showFavoritesOnOpen: true),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0x0F003840),
              blurRadius: 6,
              spreadRadius: 0.5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: rubikBold.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: rubikRegular.copyWith(
                fontSize: 9,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _onShiftManagementTap() {
    final controller = Get.find<CashierAuthController>();
    if (controller.isShiftLoading) return;
    if (controller.shiftError != null) {
      controller.fetchCurrentShift();
      return;
    }
    if (controller.currentShift == null) {
      _confirmOpenShift(controller);
    } else {
      _confirmCloseShift(controller);
    }
  }

  Future<void> _showRefundDialog() async {
    final receiptController = TextEditingController();
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('cashier_return_purchases'.tr, style: rubikBold),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: receiptController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'receipt_number'.tr,
                  prefixIcon: const Icon(Icons.receipt_long_rounded),
                ),
              ),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: 'cashier_refund_amount'.tr),
              ),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'cashier_refund_reason'.tr),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            onPressed: () {
              final receipt = receiptController.text.trim();
              final amount = double.tryParse(amountController.text.trim());
              final reason = reasonController.text.trim();
              if (receipt.isEmpty || amount == null || amount <= 0 || reason.isEmpty) {
                showCustomSnackBarHelper('please_fill_all_fields'.tr, isError: true);
                return;
              }
              Navigator.of(dialogContext).pop();
              _confirmRefundExecution(receiptNumber: receipt, amount: amount, reason: reason);
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

  Future<void> _confirmRefundExecution({
    required String receiptNumber,
    required double amount,
    required String reason,
  }) async {
    var verifying = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('cashier_return_purchases'.tr, style: rubikBold),
          content: Text(
            '${'receipt_number'.tr}: $receiptNumber\n${'amount'.tr}: ${CurrencyFormatter.format(amount, currency: 'YER')}\n${'cashier_refund_reason'.tr}: $reason\n\n${'authenticate_to_confirm_transaction'.tr}',
            style: rubikRegular,
          ),
          actions: [
            TextButton(
              onPressed: verifying ? null : () => Navigator.of(dialogContext).pop(),
              child: Text('cancel'.tr),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
              onPressed: verifying ? null : () async {
                setDialogState(() => verifying = true);
                final authenticated = await _authenticateRefund();
                if (!dialogContext.mounted) return;
                if (!authenticated) {
                  Navigator.of(dialogContext).pop();
                  showCustomSnackBarHelper('transaction_authentication_cancelled'.tr, isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop();
                final response = await Get.find<CashierAuthController>().authRepo.submitRefund(
                  receiptNumber: receiptNumber,
                  amount: amount,
                  reason: reason,
                );
                final message = _refundResponseMessage(response);
                showCustomSnackBarHelper(
                  message ?? (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300
                      ? 'cashier_refund_success'.tr
                      : 'cashier_refund_failed'.tr),
                  isError: response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300,
                );
              },
              child: verifying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('execute_transaction'.tr, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _authenticateRefund() async {
    try {
      final auth = LocalAuthentication();
      return await auth.authenticate(
        localizedReason: 'authenticate_to_confirm_transaction'.tr,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  String? _refundResponseMessage(dynamic response) {
    final body = response.body;
    if (body is Map) {
      final message = body['message'] ?? body['error'];
      if (message != null && message.toString().trim().isNotEmpty) return message.toString();
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    if (body is String && body.trim().isNotEmpty) return body.trim();
    return response.statusText?.toString();
  }

  Future<void> _showChangeCalculator() async {
    final totalController = TextEditingController();
    final paidController = TextEditingController();
    final receiptController = TextEditingController();
    final changeController = TextEditingController();
    String? validationError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void recalculate(String _) {
            final total = double.tryParse(totalController.text.trim());
            final paid = double.tryParse(paidController.text.trim());
            if (total == null || paid == null) {
              changeController.text = '';
              validationError = null;
            } else if (paid < total) {
              changeController.text = '';
              validationError = 'cashier_invalid_change_amount'.tr;
            } else {
              changeController.text = (paid - total).toStringAsFixed(2);
              validationError = null;
            }
            setDialogState(() {});
          }

          final amount = double.tryParse(changeController.text.trim()) ?? 0;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Text('cashier_change_title'.tr, style: rubikBold),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: receiptController,
                  decoration: InputDecoration(labelText: 'receipt_number'.tr),
                ),
                TextField(
                  controller: totalController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: recalculate,
                  decoration: InputDecoration(labelText: 'cashier_total_amount'.tr),
                ),
                TextField(
                  controller: paidController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: recalculate,
                  decoration: InputDecoration(labelText: 'cashier_paid_amount'.tr),
                ),
                TextField(
                  controller: changeController,
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'cashier_change_result'.tr),
                ),
                if (validationError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(validationError!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('cancel'.tr)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                onPressed: amount <= 0 || validationError != null
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        final receipt = receiptController.text.trim();
                        if (receipt.isEmpty) {
                          showCustomSnackBarHelper('please_fill_all_fields'.tr, isError: true);
                          return;
                        }
                        _confirmRefundExecution(
                          receiptNumber: receipt,
                          amount: amount,
                          reason: 'إرجاع الباقي للعميل',
                        );
                      },
                child: Text('execute_transaction'.tr, style: const TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
    totalController.dispose();
    paidController.dispose();
    receiptController.dispose();
    changeController.dispose();
  }

  Widget _buildStartSaleBigButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => Get.toNamed(RouteHelper.cashierPosSale),
        icon: const Icon(
          Icons.point_of_sale_rounded,
          color: Colors.white,
          size: 24,
        ),
        label: Text(
          'بدء عملية بيع جديدة (POS)',
          style: rubikBold.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  2. تبويب سجل العمليات (Transactions)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTransactionsTab() {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'سجل عمليات الكاشير',
          style: rubikBold.copyWith(color: Colors.white),
        ),
      ),
      body: GetBuilder<CashierAuthController>(
        builder: (controller) {
          final salesCount =
              controller.sessionInfo?.shiftTransactionsCount ?? 0;
          final totalSales = controller.sessionInfo?.shiftTotalSales ?? 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00251A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const Text(
                      'إجمالي مبيعات الوردية الحالية',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(totalSales, currency: 'YER'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'العمليات المنفذة: $salesCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'العمليات الأخيرة',
                style: rubikBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.grey[400],
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      salesCount > 0
                          ? 'تم تنفيذ $salesCount عملية بيع خلال هذه الوردية'
                          : 'لا توجد عمليات بيع مسجلة في هذه الوردية بعد',
                      style: rubikMedium.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Get.toNamed(RouteHelper.cashierPosSale),
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'إجراء عملية بيع الآن',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  3. تبويب الوردية (Shift Management)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildShiftTab() {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'إدارة الوردية',
          style: rubikBold.copyWith(color: Colors.white),
        ),
      ),
      body: GetBuilder<CashierAuthController>(
        builder: (controller) {
          final info = controller.sessionInfo;
          final shift = controller.currentShift;
          final isOpen = shift != null;
          final openedAt = _shiftOpenedAt(shift);
          final salesCount =
              int.tryParse(
                '${shift?['transactions_count'] ?? shift?['orders_count'] ?? 0}',
              ) ??
              0;
          final totalSales =
              double.tryParse(
                '${shift?['total_sales'] ?? shift?['sales'] ?? shift?['total_amount'] ?? 0}',
              ) ??
              0;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'حالة الوردية',
                            style: rubikBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              controller.isShiftLoading
                                  ? 'جاري التحديث'
                                  : isOpen
                                  ? 'مفتوحة'
                                  : controller.shiftError ??
                                        'لا توجد وردية مفتوحة حالياً',
                              style: rubikBold.copyWith(
                                color: isOpen
                                    ? const Color(0xFF2E7D32)
                                    : Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      _buildShiftRow(
                        'اسم الكاشير',
                        info?.cashierName ?? 'أحمد الكاشير',
                      ),
                      _buildShiftRow(
                        'كود الكاشير',
                        info?.cashierCode ?? 'CSH-001',
                      ),
                      _buildShiftRow(
                        'اسم الجهاز',
                        info?.terminalName ?? 'جهاز POS الرئيسي',
                      ),
                      _buildShiftRow(
                        'الفرع',
                        info?.branchName ?? 'الفرع الرئيسي',
                      ),
                      _buildShiftRow(
                        'رقم الوردية',
                        shift?['shift_number']?.toString() ?? '—',
                      ),
                      _buildShiftRow('بداية الوردية', openedAt),
                      _buildShiftRow('عدد العمليات', '$salesCount عملية'),
                      _buildShiftRow(
                        'إجمالي المقبوضات',
                        CurrencyFormatter.format(totalSales, currency: 'YER'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isOpen)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.lock_clock_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'إغلاق الوردية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: controller.isShiftLoading
                        ? null
                        : () => _confirmCloseShift(controller),
                  )
                else
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(
                      Icons.lock_open_rounded,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'فتح وردية',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: controller.isShiftLoading
                        ? null
                        : () => _confirmOpenShift(controller),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: controller.isShiftLoading
                      ? null
                      : controller.fetchCurrentShift,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث حالة الوردية'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShiftRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: rubikRegular.copyWith(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: rubikBold.copyWith(fontSize: 14, color: kPrimaryColor),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmOpenShift(CashierAuthController controller) async {
    final terminalNumber = controller.sessionInfo?.terminalNumber;
    if (terminalNumber == null || terminalNumber.trim().isEmpty) {
      showCustomSnackBarHelper('رقم نقطة البيع غير متوفر', isError: true);
      return;
    }

    final openingBalance = await _requestShiftBalance(
      title: 'فتح وردية',
      label: 'الرصيد الافتتاحي',
    );
    if (openingBalance == null) return;
    await controller.openShift(
      terminalNumber: terminalNumber,
      openingBalance: openingBalance,
    );
  }

  Future<void> _confirmCloseShift(CashierAuthController controller) async {
    final closingBalance = await _requestShiftBalance(
      title: 'إغلاق الوردية',
      label: 'الرصيد الختامي',
    );
    if (closingBalance == null) return;
    await controller.closeShift(closingBalance: closingBalance);
  }

  Future<double?> _requestShiftBalance({
    required String title,
    required String label,
  }) async {
    final balanceController = TextEditingController(text: '0');
    final balance = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: balanceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final rawValue = balanceController.text.trim();
              final value = double.tryParse(rawValue);
              if (value == null || value < 0) {
                showCustomSnackBarHelper('أدخل مبلغاً صحيحاً', isError: true);
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    balanceController.dispose();
    return balance;
  }

  // ═══════════════════════════════════════════════════════════════
  //  4. القائمة الجانبية المعزولة تماماً للكاشير (UI Isolation)
  //  تحتوي فقط على: (الرئيسية، محفظة الكاشير، سجل العمليات، الوردية، تسجيل الخروج)
  //  ولا تحتوي على أي عناصر تخص التاجر (إدارة المتجر، التقارير العامة، إلخ)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCashierOnlyDrawer(BuildContext context) {
    final authCtrl = Get.find<CashierAuthController>();
    final info = authCtrl.sessionInfo;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // هيدر القائمة الجانبية
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
              color: kPrimaryColor,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info?.cashierName ?? 'الكاشير',
                    style: rubikBold.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'كود: ${info?.cashierCode ?? 'CSH-001'} • ${info?.branchName ?? 'الفرع'}',
                    style: rubikRegular.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // العناصر المسموحة للكاشير حصراً
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    title: 'الرئيسية',
                  ),
                  _buildDrawerItem(
                    index: 1,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'محفظة الكاشير',
                  ),
                  _buildDrawerItem(
                    index: 2,
                    icon: Icons.receipt_long_rounded,
                    title: 'سجل العمليات',
                  ),
                  _buildDrawerItem(
                    index: 3,
                    icon: Icons.history_toggle_off_rounded,
                    title: 'الوردية',
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      'تسجيل الخروج',
                      style: rubikBold.copyWith(color: Colors.redAccent),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _confirmLogout(context);
                    },
                  ),
                ],
              ),
            ),

            // فوتر الإصدار
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'نظام بقش لنقاط البيع v4.3',
                style: rubikRegular.copyWith(
                  color: Colors.grey[400],
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey[600]),
      title: Text(
        title,
        style: isSelected
            ? rubikBold.copyWith(color: kPrimaryColor)
            : rubikRegular.copyWith(color: Colors.black87),
      ),
      selected: isSelected,
      selectedTileColor: kPrimaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.of(context).pop();
        setState(() => _currentIndex = index);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  5. الفوتر وشريط التنقل السفلي المعزول (UI Isolation)
  //  يحتوي فقط على: (الرئيسية، محفظة الكاشير، سجل العمليات، الوردية، تسجيل الخروج)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shadowColor: ColorResources.getBlackAndWhite().withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        shape: const AutomaticNotchedShape(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          CircleBorder(),
        ),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(child: _buildBottomNavItem(index: 0, label: 'home'.tr, icon: Icons.home_rounded)),
              Expanded(child: _buildBottomNavItem(index: 1, label: 'notification'.tr, icon: Icons.notifications_rounded)),
              const SizedBox(width: 72),
              Expanded(child: _buildBottomNavItem(index: 2, label: 'history'.tr, icon: Icons.history_rounded)),
              Expanded(child: _buildBottomNavItem(index: 3, label: 'profile'.tr, icon: Icons.person_rounded)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _currentNavIndex == index;
    return InkWell(
      onTap: () => _onTabSelect(index),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isSelected ? kPrimaryColor : const Color(0xFF8E8E93)),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: isSelected
                  ? rubikBold.copyWith(fontSize: 10, color: kPrimaryColor)
                  : rubikRegular.copyWith(fontSize: 10, color: const Color(0xFF8E8E93)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFloatingActionButton() {
    return Container(
      height: 62,
      width: 62,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            ColorResources.gradientColor,
            ColorResources.gradientColor.withValues(alpha: 0.5),
            ColorResources.secondaryColor.withValues(alpha: 0.3),
            ColorResources.gradientColor.withValues(alpha: 0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: kLimeColor,
        elevation: 2,
        onPressed: () => Get.toNamed(RouteHelper.cashierPosSale),
        child: const Icon(
          Icons.point_of_sale_rounded,
          color: kPrimaryColor,
          size: 28,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'تسجيل خروج الكاشير',
          style: rubikBold.copyWith(color: kPrimaryColor),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في تسجيل خروج الكاشير؟ سيتم مسح جلسة العمل وتأمين المحفظة.',
          style: rubikRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Get.find<CashierAuthController>().logout();
            },
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
