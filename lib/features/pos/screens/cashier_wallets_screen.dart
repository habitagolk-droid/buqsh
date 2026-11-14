import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';

class CashierWalletsScreen extends StatelessWidget {
  const CashierWalletsScreen({Key? key}) : super(key: key);

  static const Color kPrimaryColor = Color(0xFF004D40);
  static const Color kLimeColor = Color(0xFFD4E157);
  static const Color kBgColor = Color(0xFFF8F9FA);

  Color _getCurrencyColor(String code) {
    switch (code.toUpperCase()) {
      case 'YER':
        return const Color(0xFFC8102E);
      case 'USD':
        return const Color(0xFF2E7D32);
      case 'SAR':
        return const Color(0xFF00695C);
      default:
        return kPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'محافظ الكاشير والمتجر',
          style: rubikBold.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () {
              Get.find<CashierWalletController>().fetchCashierWallets();
            },
          ),
        ],
      ),
      body: GetBuilder<CashierWalletController>(
        builder: (walletCtrl) {
          if (walletCtrl.isLoading && walletCtrl.cashierWallets.isEmpty && walletCtrl.merchantWallets.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            );
          }

          if (walletCtrl.errorMessage != null &&
              walletCtrl.cashierWallets.isEmpty &&
              walletCtrl.merchantWallets.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      walletCtrl.errorMessage!,
                      textAlign: TextAlign.center,
                      style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('إعادة المحاولة', style: TextStyle(color: Colors.white)),
                      onPressed: () => walletCtrl.fetchCashierWallets(),
                    ),
                  ],
                ),
              ),
            );
          }

          final cashierWallets = walletCtrl.cashierWallets;
          final merchantWallets = walletCtrl.merchantWallets;

          return RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: () async {
              await walletCtrl.fetchCashierWallets(showLoading: false);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ──────── 1. محفظتي (رصيد الكاشير) ────────
                  _buildSectionHeader(
                    title: 'محفظتي (رصيد الكاشير)',
                    subtitle: 'الأرصدة والعهد النقدية المحصلة في وردية الكاشير',
                    badgeText: 'عهدة الكاشير',
                    badgeColor: const Color(0xFFE8F5E9),
                    badgeTextColor: const Color(0xFF2E7D32),
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                  const SizedBox(height: 12),
                  if (cashierWallets.isEmpty)
                    _buildEmptyState('لا توجد محافظ كاشير مسجلة حالياً')
                  else
                    _buildWalletCardsRow(cashierWallets, isCashier: true),

                  const SizedBox(height: 28),

                  // ──────── 2. أرصدة المتجر (التاجر) ────────
                  _buildSectionHeader(
                    title: 'أرصدة المتجر (التاجر)',
                    subtitle: 'إجمالي الأرصدة الرئيسية للمتجر في الحساب المركزي',
                    badgeText: 'أرصدة المتجر',
                    badgeColor: const Color(0xFFE0F2F1),
                    badgeTextColor: kPrimaryColor,
                    icon: Icons.storefront_rounded,
                  ),
                  const SizedBox(height: 12),
                  if (merchantWallets.isEmpty)
                    _buildEmptyState('لا توجد محافظ متجر مسجلة حالياً')
                  else
                    _buildWalletCardsRow(merchantWallets, isCashier: false),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: badgeTextColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: rubikBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: kPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: rubikMedium.copyWith(
                          fontSize: 10,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: rubikRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCardsRow(List<WalletModel> wallets, {required bool isCashier}) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: wallets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final wallet = wallets[index];
          final color = _getCurrencyColor(wallet.currencyCode);
          return SizedBox(
            width: 250,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.82)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        wallet.currencyCode,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                      const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      CurrencyFormatter.format(wallet.currentBalance, currency: wallet.currencyCode),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    isCashier ? 'رصيد الصندوق • ${wallet.currencyName}' : 'رصيد المتجر • ${wallet.currencyName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          message,
          style: rubikRegular.copyWith(
            color: Colors.grey[500],
            fontSize: Dimensions.fontSizeSmall,
          ),
        ),
      ),
    );
  }
}
