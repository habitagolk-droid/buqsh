import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/history/controllers/transaction_history_controller.dart';
import 'package:six_cash/features/history/domain/models/transaction_model.dart';
import 'package:six_cash/features/history/utils/transaction_formatting.dart';
import 'package:six_cash/features/home/widgets/services_grid_widget.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/styles.dart';

class ClientHomeDashboardWidget extends StatefulWidget {
  const ClientHomeDashboardWidget({Key? key}) : super(key: key);

  @override
  State<ClientHomeDashboardWidget> createState() =>
      _ClientHomeDashboardWidgetState();
}

class _ClientHomeDashboardWidgetState extends State<ClientHomeDashboardWidget> {
  static const _primary = Color(0xFF278D5B);
  static const _dark = Color(0xFF0A3A2A);
  static const _background = Color(0xFFF4F5F7);
  static const _soft = Color(0xFFF0F1F4);
  static const _alert = Color(0xFFE8F5E9);

  final PageController _walletPageController = PageController(
    viewportFraction: 0.88,
  );
  bool _showAlert = true;
  bool _hideBalances = false;
  int _walletIndex = 0;

  @override
  void dispose() {
    _walletPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showAlert) _buildAlertBanner(),
          _buildWalletSection(),
          _buildPromoBanner(),
          _buildSectionTitle('الخدمات'),
          const ServicesGridWidget(),
          _buildTransactionsSection(),
          const SizedBox(height: 88),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _alert,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 24, height: 24),
            onPressed: () => setState(() => _showAlert = false),
            icon: const Icon(Icons.close_rounded, size: 20, color: _primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'محفظتك جاهزة وآمنة للاستخدام',
              textAlign: TextAlign.center,
              style: rubikBold.copyWith(fontSize: 13, color: _primary),
            ),
          ),
          const Icon(Icons.notifications_none_rounded, size: 20, color: _primary),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    if (!Get.isRegistered<WalletController>()) return const SizedBox.shrink();

    return GetBuilder<WalletController>(
      builder: (controller) {
        final wallets = controller.wallets;
        if (controller.isLoading && wallets.isEmpty) {
          return const SizedBox(
            height: 230,
            child: Center(child: CircularProgressIndicator(color: _primary)),
          );
        }
        if (wallets.isEmpty) {
          return Container(
            height: 120,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, color: _primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.errorMessage ?? 'تعذر تحميل المحافظ',
                    style: rubikRegular.copyWith(color: _dark, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: () => controller.getWallets(reload: true),
                  icon: const Icon(Icons.refresh_rounded, color: _primary),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _walletPageController,
                itemCount: wallets.length,
                onPageChanged: (index) {
                  setState(() => _walletIndex = index);
                  controller.selectWallet(wallets[index]);
                },
                itemBuilder: (context, index) => _buildWalletCard(wallets[index]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                wallets.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _walletIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _walletIndex ? _primary : Colors.grey[400],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWalletCard(WalletModel wallet) {
    final balance = wallet.currentBalance
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [_primary, _dark],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x260A3A2A), blurRadius: 12, offset: Offset(0, 5)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('حساب', style: rubikRegular.copyWith(color: Colors.white, fontSize: 14)),
                Text(wallet.currencyName, style: rubikBold.copyWith(color: Colors.white, fontSize: 18)),
              ],
            ),
            const Spacer(),
            Text(
              _hideBalances ? '••••••••' : '$balance ${wallet.currencySymbol}',
              textAlign: TextAlign.right,
              style: rubikBold.copyWith(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 2),
            Text(
              wallet.currencyCode,
              textAlign: TextAlign.right,
              style: rubikRegular.copyWith(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                  onPressed: () => setState(() => _hideBalances = !_hideBalances),
                  icon: Icon(
                    _hideBalances ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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

  Widget _buildPromoBanner() {
    return InkWell(
      onTap: () => showCustomSnackBarHelper('coming_soon'.tr),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.router_outlined, size: 32, color: _dark),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('كروت الشبكات', style: rubikBold.copyWith(color: _primary, fontSize: 16)),
                Text('صارت في الجيب', style: rubikRegular.copyWith(color: _dark, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(title, textAlign: TextAlign.right, style: rubikBold.copyWith(color: _dark, fontSize: 18)),
    );
  }

  Widget _buildTransactionsSection() {
    if (!Get.isRegistered<TransactionHistoryController>()) return const SizedBox.shrink();
    return GetBuilder<TransactionHistoryController>(
      builder: (controller) {
        final items = controller.transactionList.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Get.toNamed(RouteHelper.history),
                    child: Text('عرض الكل', style: rubikMedium.copyWith(color: _primary, fontSize: 12)),
                  ),
                  Text('آخر العمليات', style: rubikBold.copyWith(color: _dark, fontSize: 18)),
                ],
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('لا توجد عمليات حديثة', textAlign: TextAlign.right, style: rubikRegular.copyWith(color: Colors.grey[600], fontSize: 13)),
              )
            else
              ...items.map(_buildTransactionCard),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(Transactions item) {
    final credit = (item.credit ?? 0) > 0;
    final amount = item.formatAmount();
    final title = getTransactionTitle(item.transactionType);
    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            '${credit ? '+' : '-'} $amount',
            style: rubikBold.copyWith(color: credit ? _primary : _dark, fontSize: 16),
          ),
          const Spacer(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: rubikBold.copyWith(color: _dark, fontSize: 14)),
                const SizedBox(height: 2),
                Text(formatTransactionDate(item.createdAt), style: rubikRegular.copyWith(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: _soft, shape: BoxShape.circle),
            child: Icon(credit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 20, color: credit ? _primary : _dark),
          ),
        ],
      ),
    );
  }
}
