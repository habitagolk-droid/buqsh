import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';
import 'package:six_cash/features/wallet/widgets/multi_wallet_cards_widget.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class CashierWalletsScreen extends StatelessWidget {
  const CashierWalletsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF5),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'wallets'.tr,
          style: rubikBold.copyWith(fontSize: Dimensions.fontSizeLarge),
        ),
        actions: [
          IconButton(
            tooltip: 'retry'.tr,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => Get.find<CashierWalletController>()
                .fetchCashierWallets(),
          ),
        ],
      ),
      body: GetBuilder<CashierWalletController>(
        builder: (controller) => RefreshIndicator(
          color: Theme.of(context).primaryColor,
          onRefresh: () => controller.fetchCashierWallets(showLoading: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              top: Dimensions.paddingSizeDefault,
              bottom: Dimensions.paddingSizeExtraLarge,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault,
                ),
                child: Text(
                  'available_balance'.tr,
                  style: rubikBold.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              const MultiWalletCardsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
