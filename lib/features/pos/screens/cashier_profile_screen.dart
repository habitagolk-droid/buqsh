import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/util/styles.dart';

class CashierProfileScreen extends StatelessWidget {
  const CashierProfileScreen({super.key});

  static const _green = Color(0xFF086048);
  static const _background = Color(0xFFF2FAF5);

  String _formatBalance(double? value) {
    if (value == null) return '—';
    return value.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+\.)'),
          (match) => '${match[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text('profile'.tr, style: rubikBold),
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      body: GetBuilder<CashierAuthController>(
        builder: (auth) {
          final info = auth.sessionInfo;
          if (auth.isSessionInfoLoading && info == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (info == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auth.sessionInfoError ?? 'cashier_session_no_details'.tr,
                      textAlign: TextAlign.center,
                      style: rubikRegular,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: auth.retrySessionInfo,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          final name = info.cashierName?.trim().isNotEmpty == true
              ? info.cashierName!.trim()
              : 'cashier'.tr;
          final code = info.cashierCode?.trim().isNotEmpty == true
              ? info.cashierCode!.trim()
              : '—';

          return RefreshIndicator(
            onRefresh: () async {
              await auth.retrySessionInfo();
              if (Get.isRegistered<CashierWalletController>()) {
                await Get.find<CashierWalletController>()
                    .fetchCashierWallets(forceRefresh: true);
              }
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person_rounded,
                            color: Colors.white, size: 34),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('cashier'.tr,
                                style: rubikRegular.copyWith(
                                    color: Colors.white70, fontSize: 15)),
                            const SizedBox(height: 5),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: rubikBold.copyWith(
                                  color: Colors.white, fontSize: 21),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _infoCard(
                  icon: Icons.badge_outlined,
                  label: 'cashier_code'.tr,
                  value: code,
                ),
                const SizedBox(height: 12),
                GetBuilder<CashierWalletController>(
                  init: Get.find<CashierWalletController>(),
                  builder: (walletController) {
                    final selected = walletController.selectedCashierWallet ??
                        (walletController.displayWallets.isNotEmpty
                            ? walletController.displayWallets.first
                            : null);
                    return _infoCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'available_balance'.tr,
                      value: selected == null
                          ? (walletController.isLoading ? '…' : '—')
                          : '${_formatBalance(selected.currentBalance)} ${selected.currencyCode}',
                      trailing: walletController.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : null,
                    );
                  },
                ),
                if (auth.isSessionInfoLoading)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.09),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: _green),
        ),
        title: Text(label,
            style: rubikRegular.copyWith(color: Colors.black54, fontSize: 13)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value,
              style: rubikSemiBold.copyWith(color: _green, fontSize: 17)),
        ),
        trailing: trailing,
      ),
    );
  }
}
