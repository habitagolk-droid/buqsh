import 'package:expandable_bottom_sheet/expandable_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/home/controllers/banner_controller.dart';
import 'package:six_cash/features/home/controllers/home_controller.dart';
import 'package:six_cash/features/notification/controllers/notification_controller.dart';
import 'package:six_cash/features/setting/controllers/profile_screen_controller.dart';
import 'package:six_cash/features/requested_money/controllers/requested_money_controller.dart';
import 'package:six_cash/features/splash/controllers/splash_controller.dart';
import 'package:six_cash/features/transaction_money/controllers/transaction_controller.dart';
import 'package:six_cash/features/history/controllers/transaction_history_controller.dart';
import 'package:six_cash/features/home/controllers/websitelink_controller.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/features/home/widgets/home_app_bar_widget.dart';
import 'package:six_cash/features/home/widgets/bottomsheet_content_widget.dart';
import 'package:six_cash/features/home/widgets/persistent_header_widget.dart';
import 'package:six_cash/features/home/widgets/theme_one_widget.dart';
import 'package:six_cash/features/home/widgets/linked_website_widget.dart';
import 'package:six_cash/features/home/widgets/theme_two_widget.dart';
import 'package:six_cash/features/home/widgets/theme_three_widget.dart';
import 'package:six_cash/features/wallet/widgets/multi_wallet_cards_widget.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/controllers/cashier_wallet_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _loadData(BuildContext context, bool reload) async {
    if (reload) {
      Get.find<SplashController>().getConfigData();
    }

    if (Get.find<CashierAuthController>().isSessionReady) {
      await Get.find<BannerController>().getBannerList(reload);
      if (Get.isRegistered<CashierWalletController>()) {
        await Get.find<CashierWalletController>().fetchCashierWallets(
          showLoading: true,
        );
      }
      await Get.find<CashierAuthController>().fetchCurrentShift();
      return;
    }

    Get.find<ProfileController>().getProfileData(reload: reload);
    Get.find<BannerController>().getBannerList(reload);
    Get.find<RequestedMoneyController>().getRequestedMoneyList(
      reload,
      isUpdate: reload,
    );
    Get.find<RequestedMoneyController>().getOwnRequestedMoneyList(
      reload,
      isUpdate: reload,
    );
    Get.find<TransactionHistoryController>().getTransactionData(
      1,
      reload: reload,
    );
    Get.find<WebsiteLinkController>().getWebsiteList(reload, isUpdate: reload);
    Get.find<NotificationController>().getNotificationList(reload);
    Get.find<TransactionMoneyController>().getPurposeList(
      reload,
      isUpdate: reload,
    );
    Get.find<TransactionMoneyController>().getWithdrawMethods(isReload: reload);
    Get.find<RequestedMoneyController>().getWithdrawHistoryList(reload: false);
    Get.find<WalletController>().getWallets(reload: reload);
  }

  @override
  void initState() {
    super.initState();
    _loadData(context, false);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CashierAuthController>(
      builder: (cashierController) => GetBuilder<HomeController>(
        builder: (controller) {
        final isCashier = cashierController.isSessionReady;
        return Scaffold(
          appBar: const HomeAppBarWidget(),
          body: ExpandableBottomSheet(
            enableToggle: true,
            background: RefreshIndicator(
              onRefresh: () async => await _loadData(context, true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: GetBuilder<SplashController>(
                  builder: (splashController) {
                    int themeIndex =
                        splashController.configModel!.themeIndex ?? 1;
                    return Column(
                      children: [
                        isCashier || themeIndex == 1
                            ? ThemeOneWidget(showWalletCards: !isCashier)
                            : themeIndex == 2
                            ? const ThemeTwoWidget()
                            : themeIndex == 3
                            ? const ThemeThreeWidget()
                            : const ThemeOneWidget(),

                        if (isCashier) const MultiWalletCardsWidget(),

                        const SizedBox(height: Dimensions.paddingSizeDefault),

                        if (!isCashier) const LinkedWebsiteWidget(),
                        const SizedBox(height: 80),
                      ],
                    );
                  },
                ),
              ),
            ),
            persistentContentHeight: 70,
            persistentHeader: const PersistentHeaderWidget(),
            expandableContent: isCashier
                ? const SizedBox.shrink()
                : const BottomSheetContentWidget(),
          ),
        );
        },
      ),
    );
  }
}
