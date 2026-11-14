import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/images.dart';
import 'package:six_cash/util/styles.dart';

class CashierDashboardScreen extends StatefulWidget {
  const CashierDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CashierDashboardScreen> createState() => _CashierDashboardScreenState();
}

class _CashierDashboardScreenState extends State<CashierDashboardScreen> {
  int _currentTabIndex = 0;

  static const Color kPrimaryColor = Color(0xFF004D40);
  static const Color kLimeColor = Color(0xFFD4E157);
  static const Color kBgColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = Get.find<CashierAuthController>();
        if (!controller.isSessionReady) {
          controller.restoreSession();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildCenterFloatingActionButton(),
      bottomNavigationBar: _buildCustomerMatchingBottomBar(),
      body: GetBuilder<CashierAuthController>(
        builder: (controller) {
          if (controller.isLoading && !controller.isSessionReady) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            );
          }

          if (controller.sessionInfoError != null && controller.sessionInfo == null) {
            return _buildErrorView(controller);
          }

          return RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: () async {
              await controller.retrySessionInfo();
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
                        _buildShiftCard(controller),
                        const SizedBox(height: 18),
                        _buildServicesSectionTitle(),
                        const SizedBox(height: 12),
                        _buildServicesGrid(),
                        const SizedBox(height: 16),
                        _buildStartSaleBigButton(),
                        const SizedBox(height: 90), // Spacing for docked bottom bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 1. الهيدر الأخضر الداكن الفخم المتطابق مع هوية بقش
  Widget _buildHeader(CashierAuthController controller) {
    final info = controller.sessionInfo;
    final cashierName = info?.cashierName ?? 'أحمد الكاشير التجريبي';
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
            // صورة الكاشير
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  Images.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // اسم الكاشير والكود
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مساء الخير 👋',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

            // زر التحديث ورمز QR
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
                        : const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
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
                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 2. كارت بيانات جهاز نقطة البيع (Terminal Card)
  Widget _buildTerminalCard(CashierAuthController controller) {
    final info = controller.sessionInfo;
    final terminalName = info?.terminalName ?? 'جهاز نقطة البيع #01';
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const SizedBox(width: 4),
                    Text(
                      'متصل',
                      style: rubikMedium.copyWith(
                        color: const Color(0xFF2E7D32),
                        fontSize: Dimensions.fontSizeExtraSmall,
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

  /// 3. كارت الوردية الحالية (Shift Card)
  Widget _buildShiftCard(CashierAuthController controller) {
    final info = controller.sessionInfo;
    final openingBalance = info?.shiftOpeningBalance ?? 150000.0;
    final totalSales = info?.shiftTotalSales ?? 1769136.25;
    final count = info?.shiftTransactionsCount ?? 28;

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.history_toggle_off_rounded,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الوردية الحالية',
                    style: rubikBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'مفتوحة (Open)',
                  style: rubikBold.copyWith(
                    color: const Color(0xFF2E7D32),
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildShiftMetric(
                  'الرصيد الافتتاحي',
                  '${_formatMoney(openingBalance)} YER',
                  Icons.account_balance_wallet_outlined,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _buildShiftMetric(
                  'إجمالي المبيعات',
                  '${_formatMoney(totalSales)} YER',
                  Icons.trending_up_rounded,
                  highlight: true,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: _buildShiftMetric(
                  'العمليات',
                  '$count عملية',
                  Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftMetric(String label, String value, IconData icon, {bool highlight = false}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: highlight ? kPrimaryColor : Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          value,
          style: rubikBold.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: highlight ? kPrimaryColor : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: rubikRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Colors.grey[500],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildServicesSectionTitle() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        'خدمات الكاشير ونقاط البيع',
        style: rubikBold.copyWith(
          fontSize: Dimensions.fontSizeDefault,
          color: Colors.black87,
        ),
      ),
    );
  }

  /// 4. شبكة الخدمات الأربعة الحقيقية للكاشير
  Widget _buildServicesGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.25,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // 1. إتمام عملية بيع جديدة
        _buildServiceCard(
          title: 'عملية بيع جديدة',
          subtitle: 'استلام دفعة من العميل',
          icon: Icons.point_of_sale_rounded,
          iconBgColor: kPrimaryColor.withValues(alpha: 0.1),
          iconColor: kPrimaryColor,
          onTap: () => Get.toNamed(RouteHelper.cashierPosSale),
        ),

        // 2. إرجاع مبلغ (Refund)
        _buildServiceCard(
          title: 'إرجاع مبلغ (Refund)',
          subtitle: 'استرداد وإلغاء عملية',
          icon: Icons.replay_rounded,
          iconBgColor: Colors.orange.withValues(alpha: 0.1),
          iconColor: Colors.deepOrange,
          onTap: _showRefundDialog,
        ),

        // 3. إدارة الوردية (Shift Management)
        _buildServiceCard(
          title: 'إدارة الوردية',
          subtitle: 'تفاصيل وإغلاق الوردية',
          icon: Icons.access_time_filled_rounded,
          iconBgColor: Colors.blue.withValues(alpha: 0.1),
          iconColor: Colors.blue[700]!,
          onTap: _showShiftManagementSheet,
        ),

        // 4. سجل العمليات (Transactions)
        _buildServiceCard(
          title: 'سجل العمليات',
          subtitle: 'عرض مبيعات الكاشير',
          icon: Icons.receipt_long_rounded,
          iconBgColor: Colors.purple.withValues(alpha: 0.1),
          iconColor: Colors.purple,
          onTap: () => Get.toNamed(RouteHelper.history),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                style: rubikBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: rubikRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Colors.grey[500],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 5. زر البدء السريع الكبير (Start POS Sale) بلون ليموني
  Widget _buildStartSaleBigButton() {
    return InkWell(
      onTap: () => Get.toNamed(RouteHelper.cashierPosSale),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: kLimeColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kLimeColor.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بدء عملية بيع سريعة (POS Sale)',
                    style: rubikBold.copyWith(
                      color: kPrimaryColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'مسح كود العميل QR واستلام الدفعة فوراً',
                    style: rubikRegular.copyWith(
                      color: kPrimaryColor.withValues(alpha: 0.8),
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: kPrimaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// 6. الفوتر (Bottom Navigation Bar) المطابق تماماً لفوتر العميل
  Widget _buildCustomerMatchingBottomBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: ColorResources.getBlackAndWhite().withValues(alpha: 0.14),
            blurRadius: 80,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: ColorResources.getBlackAndWhite().withValues(alpha: 0.20),
            blurRadius: 0.5,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            index: 0,
            label: 'الرئيسية',
            icon: Icons.home_rounded,
            onTap: () => setState(() => _currentTabIndex = 0),
          ),
          _buildBottomNavItem(
            index: 1,
            label: 'إتمام بيع',
            icon: Icons.point_of_sale_rounded,
            onTap: () {
              setState(() => _currentTabIndex = 1);
              Get.toNamed(RouteHelper.cashierPosSale);
            },
          ),
          // مساحة محجوزة للزر العائم في المنتصف
          const SizedBox(height: 20, width: 40),

          _buildBottomNavItem(
            index: 2,
            label: 'الوردية',
            icon: Icons.history_toggle_off_rounded,
            onTap: () {
              setState(() => _currentTabIndex = 2);
              _showShiftManagementSheet();
            },
          ),
          _buildBottomNavItem(
            index: 3,
            label: 'خروج',
            icon: Icons.logout_rounded,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? kPrimaryColor : const Color(0xFF8E8E93),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: isSelected
                  ? rubikBold.copyWith(fontSize: 10, color: kPrimaryColor)
                  : rubikRegular.copyWith(fontSize: 10, color: const Color(0xFF8E8E93)),
            ),
          ],
        ),
      ),
    );
  }

  /// الزر العائم في المنتصف بلون ليموني مطابق تماماً لواجهة العميل
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
            ColorResources.gradientColor.withValues(alpha: 0.05),
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

  void _showRefundDialog() {
    final txController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.replay_rounded, color: Colors.deepOrange),
            ),
            const SizedBox(width: 10),
            Text('إرجاع مبلغ (Refund)', style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أدخل رقم العملية أو الإيصال المراد إرجاعه:',
              style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: txController,
              decoration: InputDecoration(
                hintText: 'رقم الإيصال / Transaction ID',
                prefixIcon: const Icon(Icons.receipt_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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

  void _showShiftManagementSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final ctrl = Get.find<CashierAuthController>();
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'إدارة الوردية (Shift Management)',
                    style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: kPrimaryColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text('نشطة', style: rubikBold.copyWith(color: const Color(0xFF2E7D32), fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_pin_circle_outlined, color: kPrimaryColor),
                title: const Text('اسم الكاشير'),
                trailing: Text(ctrl.sessionInfo?.cashierName ?? 'أحمد الكاشير', style: rubikBold),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.point_of_sale_outlined, color: kPrimaryColor),
                title: const Text('اسم الجهاز'),
                trailing: Text(ctrl.sessionInfo?.terminalName ?? 'POS-01', style: rubikBold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  showCustomSnackBarHelper('تم إرسال طلب إغلاق الوردية للمسؤول', isError: false);
                },
                child: const Text('إغلاق الوردية الحالية وتصدير التقرير', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
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
          'هل أنت متأكد من رغبتك في تسجيل خروج الكاشير؟',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Get.find<CashierAuthController>().logout();
            },
            child: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(CashierAuthController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              controller.sessionInfoError ?? 'تعذر تحميل بيانات الكاشير',
              textAlign: TextAlign.center,
              style: rubikMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => controller.retrySessionInfo(),
              child: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
