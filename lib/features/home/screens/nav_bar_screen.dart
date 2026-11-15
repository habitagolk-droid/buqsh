import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/widgets/custom_dialog_widget.dart';
import 'package:six_cash/features/auth/controllers/auth_controller.dart';
import 'package:six_cash/features/camera_verification/screens/camera_screen.dart';
import 'package:six_cash/features/home/controllers/menu_controller.dart';
import 'package:six_cash/features/home/widgets/bottom_item_widget.dart';
import 'package:six_cash/features/home/widgets/floating_action_button_widget.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/screens/cashier_profile_screen.dart';
import 'package:six_cash/features/pos/transactions/cashier_transactions_screen.dart';
import 'package:six_cash/features/splash/screens/splash_screen.dart';
import 'package:six_cash/helper/dialog_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/images.dart';
import 'package:six_cash/util/styles.dart';

class NavBarScreen extends StatefulWidget {
  const NavBarScreen({Key? key}) : super(key: key);

  @override
  State<NavBarScreen> createState() => _NavBarScreenState();
}

class _NavBarScreenState extends State<NavBarScreen> {
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    Get.find<MenuItemController>().selectHomePage(isUpdate: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cashierController = Get.find<CashierAuthController>();
      if (!cashierController.isSessionReady) {
        await cashierController.restoreSession();
      }
      if (!mounted) return;
      if (!cashierController.isSessionReady &&
          Get.isRegistered<AuthController>()) {
        Get.find<AuthController>().checkBiometricWithPin();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvoked: (_) => _onWillPop(context),
      child: GetBuilder<CashierAuthController>(
        builder: (cashierController) {
          final isCashier = cashierController.isSessionReady;
          return GetBuilder<MenuItemController>(
            builder: (menuController) {
              return Scaffold(
                backgroundColor: Theme.of(context)
                    .bottomNavigationBarTheme.selectedItemColor,
                drawer: isCashier ? _buildCashierDrawer(context) : null,
                body: PageStorage(
                  bucket: bucket,
                  child: isCashier && menuController.currentTabIndex == 1
                      ? const CashierTransactionsScreen()
                      : isCashier && menuController.currentTabIndex == 3
                          ? const CashierProfileScreen()
                          : menuController.screen[menuController.currentTabIndex],
                ),
                floatingActionButton: FloatingActionButtonWidget(
                  strokeWidth: 1.5,
                  radius: 50,
                  gradient: LinearGradient(
                    colors: [
                      ColorResources.gradientColor,
                      ColorResources.gradientColor.withOpacity(0.5),
                      ColorResources.secondaryColor.withOpacity(0.3),
                      ColorResources.gradientColor.withOpacity(0.05),
                      ColorResources.gradientColor.withOpacity(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  child: FloatingActionButton(
                    shape: const CircleBorder(),
                    backgroundColor: Theme.of(context).secondaryHeaderColor,
                    elevation: 1,
                    onPressed: () {
                      if (isCashier) {
                        Get.toNamed(RouteHelper.cashierPosSale);
                      } else {
                        Get.to(
                          () => const CameraScreen(
                            fromEditProfile: false,
                            isBarCodeScan: true,
                            isHome: true,
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Image.asset(Images.scannerIcon),
                    ),
                  ),
                ),
                floatingActionButtonLocation:
                    FloatingActionButtonLocation.centerDocked,
                bottomNavigationBar: SafeArea(
                  top: false,
                  child: BottomAppBar(
                    color: Theme.of(context)
                        .bottomNavigationBarTheme.backgroundColor,
                    elevation: 8,
                    shadowColor:
                        ColorResources.getBlackAndWhite().withOpacity(0.18),
                    surfaceTintColor: Colors.transparent,
                    shape: AutomaticNotchedShape(
                      const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      const CircleBorder(),
                    ),
                    notchMargin: 8,
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 60,
                      child: Row(
                        children: [
                          Expanded(
                            child: BottomItemWidget(
                              onTop: menuController.selectHomePage,
                              icon: menuController.currentTabIndex == 0
                                  ? Images.homeIconBold
                                  : Images.homeIcon,
                              name: 'home'.tr,
                              selectIndex: 0,
                            ),
                          ),
                          Expanded(
                            child: BottomItemWidget(
                              onTop: menuController.selectNotificationPage,
                              icon: menuController.currentTabIndex == 2
                                  ? Images.notificationIconBold
                                  : Images.notificationIcon,
                              name: 'notification'.tr,
                              selectIndex: 2,
                            ),
                          ),
                          const SizedBox(width: 72),
                          Expanded(
                            child: BottomItemWidget(
                              onTop: menuController.selectHistoryPage,
                              icon: menuController.currentTabIndex == 1
                                  ? Images.clockIconBold
                                  : Images.clockIcon,
                              name: 'history'.tr,
                              selectIndex: 1,
                            ),
                          ),
                          Expanded(
                            child: BottomItemWidget(
                              onTop: menuController.selectProfilePage,
                              icon: menuController.currentTabIndex == 3
                                  ? Images.profileIconBold
                                  : Images.profileIcon,
                              name: 'profile'.tr,
                              selectIndex: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCashierDrawer(BuildContext context) {
    final cashier = Get.find<CashierAuthController>();
    final menu = Get.find<MenuItemController>();
    final info = cashier.sessionInfo;

    Widget item({required IconData icon, required String title, required VoidCallback onTap}) {
      return ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title, style: rubikMedium.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      );
    }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info?.cashierName ?? 'cashier'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: rubikBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'كاشير',
                    style: rubikMedium.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (info?.cashierCode?.isNotEmpty == true) info!.cashierCode!,
                      if (info?.branchName?.isNotEmpty == true) info!.branchName!,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: rubikRegular.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeExtraSmall),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  item(
                    icon: Icons.home_rounded,
                    title: 'home'.tr,
                    onTap: () { Navigator.pop(context); menu.selectHomePage(); },
                  ),
                  item(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'wallets'.tr,
                    onTap: () { Navigator.pop(context); Get.toNamed(RouteHelper.cashierWallets); },
                  ),
                  item(
                    icon: Icons.history_rounded,
                    title: 'history'.tr,
                    onTap: () { Navigator.pop(context); menu.selectHistoryPage(); },
                  ),
                  item(
                    icon: Icons.notifications_rounded,
                    title: 'notification'.tr,
                    onTap: () { Navigator.pop(context); menu.selectNotificationPage(); },
                  ),
                  item(
                    icon: Icons.person_rounded,
                    title: 'profile'.tr,
                    onTap: () { Navigator.pop(context); menu.selectProfilePage(); },
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  item(
                    icon: Icons.logout_rounded,
                    title: 'logout'.tr,
                    onTap: () {
                      Navigator.pop(context);
                      Get.dialog(
                        AlertDialog(
                          title: Text('are_you_sure'.tr),
                          content: Text('are_you_sure_you_want_to_logout'.tr),
                          actions: [
                            TextButton(onPressed: Get.back, child: Text('cancel'.tr)),
                            TextButton(
                              onPressed: () => cashier.logout(),
                              child: Text('logout'.tr, style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onWillPop(BuildContext context) {
    DialogHelper.showAnimatedDialog(
      context,
      CustomDialogWidget(
        icon: Icons.exit_to_app_rounded,
        title: 'exit'.tr,
        description: 'do_you_want_to_exit_the_app'.tr,
        onTapFalse: () => Navigator.of(context).pop(false),
        onTapTrue: () {
          SystemNavigator.pop().then(
            (value) => Get.offAll(() => const SplashScreen()),
          );
        },
        onTapTrueText: 'yes'.tr,
        onTapFalseText: 'no'.tr,
      ),
      dismissible: false,
      isFlip: true,
    );
  }
}
