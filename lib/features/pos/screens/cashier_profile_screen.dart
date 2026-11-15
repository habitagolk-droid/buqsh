import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/util/styles.dart';

class CashierProfileScreen extends StatelessWidget {
  const CashierProfileScreen({super.key});

  static const _primary = Color(0xFF086048);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF5),
      appBar: AppBar(
        title: Text('profile'.tr, style: rubikBold),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: GetBuilder<CashierAuthController>(
        builder: (controller) {
          final info = controller.sessionInfo;
          if (controller.isSessionInfoLoading && info == null) {
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
                      controller.sessionInfoError ?? 'cashier_session_no_details'.tr,
                      textAlign: TextAlign.center,
                      style: rubikRegular,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: controller.retrySessionInfo,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('retry'.tr),
                    ),
                  ],
                ),
              ),
            );
          }

          final displayName = info.cashierName ?? 'cashier'.tr;
          final summary = <(String, String, IconData)>[
            if (info.cashierCode?.isNotEmpty == true)
              ('cashier_id'.tr, info.cashierCode!, Icons.badge_outlined),
            if (info.terminalName?.isNotEmpty == true)
              ('terminal_name'.tr, info.terminalName!, Icons.point_of_sale_outlined),
            if (info.merchantName?.isNotEmpty == true)
              ('merchant_name'.tr, info.merchantName!, Icons.store_outlined),
            if (info.branchName?.isNotEmpty == true)
              ('branch'.tr, info.branchName!, Icons.location_on_outlined),
          ];
          final extraFields = info.displayFields
              .where((field) => field.value != displayName)
              .toList();

          return RefreshIndicator(
            onRefresh: controller.retrySessionInfo,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('cashier'.tr,
                                style: rubikRegular.copyWith(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: rubikBold.copyWith(color: Colors.white, fontSize: 20),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (summary.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < summary.length; i++) ...[
                          ListTile(
                            leading: Icon(summary[i].$3, color: _primary),
                            title: Text(summary[i].$1, style: rubikRegular),
                            subtitle: Text(summary[i].$2, style: rubikMedium),
                          ),
                          if (i != summary.length - 1)
                            const Divider(height: 1, indent: 64),
                        ],
                      ],
                    ),
                  ),
                if (extraFields.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('بيانات الجلسة', style: rubikBold.copyWith(fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < extraFields.length; i++) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(extraFields[i].key, style: rubikRegular),
                            trailing: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * 0.48,
                              ),
                              child: Text(
                                extraFields[i].value,
                                textAlign: TextAlign.end,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: rubikMedium,
                              ),
                            ),
                          ),
                          if (i != extraFields.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ],
                if (controller.isSessionInfoLoading)
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
}
