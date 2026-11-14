import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/features/pos/screens/cashier_wallets_screen.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';

class CashierHomeScreen extends StatefulWidget {
  const CashierHomeScreen({Key? key}) : super(key: key);

  @override
  State<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends State<CashierHomeScreen> {
  int _currentIndex = 0;

  static const Color _primary = ColorResources.primaryColor;
  static const Color _background = Color(0xFFF3F2F7);
  static const Color _accent = ColorResources.errorColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = Get.find<CashierAuthController>();
      if (!controller.isSessionReady) await controller.restoreSession();
      if (!mounted || !controller.isSessionReady) return;
      await controller.fetchCurrentShift();
      if (Get.isRegistered<CashierWalletController>()) {
        await Get.find<CashierWalletController>().fetchCashierWallets(
          showLoading: false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: GetBuilder<CashierAuthController>(
          builder: (controller) {
            if (controller.isLoading && !controller.isSessionReady) {
              return const Center(
                child: CircularProgressIndicator(color: _primary),
              );
            }
            return RefreshIndicator(
              color: _accent,
              onRefresh: () async {
                await controller.retrySessionInfo();
                await controller.fetchCurrentShift();
                if (Get.isRegistered<CashierWalletController>()) {
                  await Get.find<CashierWalletController>()
                      .fetchCashierWallets(showLoading: false);
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(controller)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSyncNotice(controller),
                        const SizedBox(height: 20),
                        _buildWalletCard(controller),
                        const SizedBox(height: 28),
                        _buildQuickActions(),
                        const SizedBox(height: 26),
                        _buildSectionHeader('العمليات'),
                        const SizedBox(height: 12),
                        _buildRecentActivity(controller),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(CashierAuthController controller) {
    final info = controller.sessionInfo;
    final name = info?.cashierName?.trim().isNotEmpty == true
        ? info!.cashierName
        : 'كاشير بقش';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.point_of_sale_rounded,
                color: _accent, size: 31),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('مساء الخير',
                  style: rubikBold.copyWith(fontSize: 24, color: _primary)),
              const SizedBox(height: 2),
              Text(name!,
                  style: rubikRegular.copyWith(fontSize: 19, color: _primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncNotice(CashierAuthController controller) {
    return Material(
      color: const Color(0xFFF4DDE3),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: controller.isSessionInfoLoading
            ? null
            : () => controller.retrySessionInfo(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: controller.isSessionInfoLoading
                    ? null
                    : () => controller.retrySessionInfo(),
                icon: const Icon(Icons.close, color: _accent, size: 24),
              ),
              Expanded(
                child: Text(
                  controller.sessionInfoError ??
                      'اضغط هنا لمزامنة البيانات المفضلة بين أجهزتك',
                  textAlign: TextAlign.center,
                  style: rubikBold.copyWith(fontSize: 14, color: _accent),
                ),
              ),
              controller.isSessionInfoLoading
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _accent,
                      ),
                    )
                  : const Icon(Icons.sync_rounded, color: _accent, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard(CashierAuthController controller) {
    final info = controller.sessionInfo;
    final walletController = Get.isRegistered<CashierWalletController>()
        ? Get.find<CashierWalletController>()
        : null;
    final wallet = walletController?.wallets.firstWhereOrNull(
      (item) => item.currencyCode.toUpperCase() == 'YER',
    );
    final balance = wallet?.currentBalance;
    final terminalName = info?.terminalName ?? 'نقطة بقش';
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -42,
            bottom: -96,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 22),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded,
                      color: Colors.white, size: 42),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('حساب',
                          style: rubikRegular.copyWith(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 17)),
                      Text(info?.branchName ?? 'نقطة البيع',
                          style: rubikBold.copyWith(
                              color: Colors.white, fontSize: 21),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(terminalName,
                  textAlign: TextAlign.end,
                  style: rubikBold.copyWith(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                balance == null
                    ? '••••••'
                    : CurrencyFormatter.format(balance, currency: 'YER'),
                textAlign: TextAlign.end,
                style: rubikBold.copyWith(
                    color: Colors.white, fontSize: 27, letterSpacing: 2),
              ),
              const Spacer(),
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: IconButton(
                  tooltip: 'تحديث الرصيد',
                  onPressed: walletController == null
                      ? null
                      : () => walletController.fetchCashierWallets(),
                  icon: const Icon(Icons.visibility_off_outlined,
                      color: Colors.white, size: 26),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = <_CashierAction>[
      _CashierAction('إتمام عملية بيع', Icons.point_of_sale_rounded,
          () => Get.toNamed(RouteHelper.cashierPosSale)),
      _CashierAction('المحفظة', Icons.account_balance_wallet_outlined,
          () => Get.toNamed(RouteHelper.cashierWallets)),
      _CashierAction('سجل العمليات', Icons.receipt_long_outlined,
          () => setState(() => _currentIndex = 1)),
      _CashierAction('إدارة الوردية', Icons.access_time_rounded,
          () => _showShiftSheet()),
      _CashierAction('المفضلة', Icons.favorite_border,
          () => showCustomSnackBarHelper('قريباً', isError: false)),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((action) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 64) / 2,
          height: 132,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: action.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon,
                      color: action.label == 'المفضلة' ? _accent : _primary,
                      size: 34),
                  const SizedBox(height: 12),
                  Text(action.label,
                      textAlign: TextAlign.center,
                      style: rubikRegular.copyWith(
                          fontSize: 17, color: _primary)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader(String text) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Text(text,
            style: rubikBold.copyWith(fontSize: 27, color: _primary)),
      );

  Widget _buildRecentActivity(CashierAuthController controller) {
    final shift = controller.currentShift;
    final count = shift?['transactions_count'] ?? shift?['orders_count'] ?? 0;
    final total = double.tryParse(
          '${shift?['total_sales'] ?? shift?['sales'] ?? shift?['total_amount'] ?? 0}',
        ) ??
        0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: _primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مبيعات الوردية',
                    style: rubikBold.copyWith(color: _primary)),
                const SizedBox(height: 5),
                Text('$count عملية • ${CurrencyFormatter.format(total, currency: 'YER')}',
                    style: rubikRegular.copyWith(color: Colors.grey[600])),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: Colors.grey[500]),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 18),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem('الملف', Icons.person_outline, 3),
            _navItem('التقارير', Icons.format_list_bulleted, 1),
            const SizedBox(width: 64),
            _navItem('الخدمات', Icons.shopping_bag_outlined, 2),
            _navItem('الرئيسية', Icons.home_rounded, 0),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String label, IconData icon, int index) {
    final selected = _currentIndex == index;
    return InkWell(
      onTap: () {
        if (index == 3) {
          _confirmLogout(context);
        } else {
          setState(() => _currentIndex = index == 2 ? 0 : index);
          if (index == 2) Get.toNamed(RouteHelper.cashierPosSale);
        }
      },
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: selected ? _accent : Colors.grey[500]),
            const SizedBox(height: 3),
            Text(label,
                style: rubikRegular.copyWith(
                    fontSize: 11, color: selected ? _accent : Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab() {
    return SizedBox(
      width: 68,
      height: 68,
      child: FloatingActionButton(
        heroTag: 'cashier-home-sale',
        backgroundColor: const Color(0xFF28282A),
        elevation: 5,
        onPressed: () => Get.toNamed(RouteHelper.cashierPosSale),
        child: const Icon(Icons.point_of_sale_rounded,
            color: Colors.white, size: 31),
      ),
    );
  }

  void _showShiftSheet() {
    final controller = Get.find<CashierAuthController>();
    final shift = controller.currentShift;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('الوردية الحالية',
                  textAlign: TextAlign.center,
                  style: rubikBold.copyWith(fontSize: 22, color: _primary)),
              const SizedBox(height: 18),
              _shiftLine('الكاشير', controller.sessionInfo?.cashierName ?? '—'),
              _shiftLine('الجهاز', controller.sessionInfo?.terminalName ?? '—'),
              _shiftLine('الحالة', shift == null ? 'لا توجد وردية مفتوحة' : 'مفتوحة'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  controller.fetchCurrentShift();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('تحديث بيانات الوردية'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shiftLine(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: rubikRegular.copyWith(color: Colors.grey[600])),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: rubikBold.copyWith(color: _primary)),
            ),
          ],
        ),
      );

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل خروج الكاشير'),
        content: const Text('هل تريد تسجيل الخروج من حساب الكاشير؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Get.find<CashierAuthController>().logout();
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }
}

class _CashierAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CashierAction(this.label, this.icon, this.onTap);
}
