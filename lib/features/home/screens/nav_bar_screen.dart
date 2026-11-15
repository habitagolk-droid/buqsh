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
import 'package:six_cash/features/pos/screens/cashier_return_change_screen.dart';
import 'package:six_cash/features/pos/screens/cashier_profile_screen.dart';
import 'package:six_cash/features/pos/screens/pos_payment_screen.dart';
import 'package:six_cash/features/pos/transactions/cashier_transactions_screen.dart';
import 'package:six_cash/features/splash/screens/splash_screen.dart';
import 'package:six_cash/helper/dialog_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/app_constants.dart';
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
                  child: isCashier &&
                          (menuController.currentTabIndex == 1 ||
                              menuController.currentTabIndex == 2)
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
                              icon: isCashier
                                  ? (menuController.currentTabIndex == 2
                                      ? Images.clockIconBold
                                      : Images.clockIcon)
                                  : (menuController.currentTabIndex == 2
                                      ? Images.notificationIconBold
                                      : Images.notificationIcon),
                              name: isCashier ? 'history'.tr : 'notification'.tr,
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
    final primary = Theme.of(context).primaryColor;

    Widget section(String title) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 6),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              title,
              style: rubikSemiBold.copyWith(
                color: primary,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        );

    Widget item({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool destructive = false,
    }) =>
        ListTile(
          leading: Icon(
            icon,
            color: destructive ? Colors.redAccent : primary,
            size: 22,
          ),
          title: Text(
            title,
            style: rubikMedium.copyWith(
              color: destructive
                  ? Colors.redAccent
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).hintColor,
            size: 20,
          ),
          onTap: onTap,
          contentPadding: const EdgeInsetsDirectional.only(start: 20, end: 12),
          visualDensity: const VisualDensity(vertical: -1),
        );

    void openRoute(String route) {
      Navigator.pop(context);
      Get.toNamed(route);
    }

    void selectTab(VoidCallback select) {
      Navigator.pop(context);
      select();
    }

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    child: const Icon(Icons.person_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    info?.cashierName?.isNotEmpty == true
                        ? info!.cashierName!
                        : 'cashier'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: rubikBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeLarge),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'cashier'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: rubikRegular.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeSmall),
                  ),
                  if (info?.cashierCode?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${'cashier_code'.tr}: ${info!.cashierCode}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: rubikRegular.copyWith(color: Colors.white70, fontSize: Dimensions.fontSizeExtraSmall),
                    ),
                  ],
                ],
              ),
            ),
            section('account'.tr),
            item(
              icon: Icons.home_rounded,
              title: 'home'.tr,
              onTap: () => selectTab(menu.selectHomePage),
            ),
            item(
              icon: Icons.account_balance_wallet_rounded,
              title: 'wallets'.tr,
              onTap: () => openRoute(RouteHelper.cashierWallets),
            ),
            item(
              icon: Icons.history_rounded,
              title: 'cashier_reports'.tr,
              onTap: () => selectTab(menu.selectHistoryPage),
            ),
            item(
              icon: Icons.person_rounded,
              title: 'profile'.tr,
              onTap: () => selectTab(menu.selectProfilePage),
            ),
            const Divider(indent: 16, endIndent: 16, height: 8),
            section('cashier_dashboard'.tr),
            item(
              icon: Icons.point_of_sale_rounded,
              title: 'cashier_start_sale'.tr,
              onTap: () => openRoute(RouteHelper.cashierPosSale),
            ),
            item(
              icon: Icons.calculate_outlined,
              title: 'cashier_change_calculator'.tr,
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const CashierReturnChangeScreen());
              },
            ),
            item(
              icon: Icons.payment_rounded,
              title: 'cashier_topup_payment'.tr,
              onTap: () => openRoute(RouteHelper.posPayment),
            ),
            item(
              icon: Icons.favorite_border_rounded,
              title: 'cashier_favorites'.tr,
              onTap: () {
                Navigator.pop(context);
                Get.to(() => const PosPaymentScreen(showFavoritesOnOpen: true));
              },
            ),
            const Divider(indent: 16, endIndent: 16, height: 8),
            section('support'.tr),
            if (AppConstants.languages.length > 1)
              item(
                icon: Icons.language_rounded,
                title: 'change_language'.tr,
                onTap: () => openRoute(RouteHelper.choseLanguageScreen),
              ),
            item(
              icon: Icons.support_agent_rounded,
              title: '24_support'.tr,
              onTap: () => openRoute(RouteHelper.support),
            ),
            item(
              icon: Icons.help_outline_rounded,
              title: 'faq'.tr,
              onTap: () => openRoute(RouteHelper.faq),
            ),
            const Divider(indent: 16, endIndent: 16, height: 8),
            section('policies'.tr),
            item(
              icon: Icons.info_outline_rounded,
              title: 'about_us'.tr,
              onTap: () => openRoute(RouteHelper.aboutUs),
            ),
            item(
              icon: Icons.description_outlined,
              title: 'terms'.tr,
              onTap: () => openRoute(RouteHelper.terms),
            ),
            item(
              icon: Icons.privacy_tip_outlined,
              title: 'privacy_policy'.tr,
              onTap: () => openRoute(RouteHelper.privacy),
            ),
            const Divider(indent: 16, endIndent: 16, height: 8),
            item(
              icon: Icons.logout_rounded,
              title: 'logout'.tr,
              destructive: true,
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
                        child: Text('logout'.tr,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
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
