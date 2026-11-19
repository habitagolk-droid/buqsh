import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:six_cash/core/theme/buqsh_design.dart';
import 'package:six_cash/features/auth/controllers/auth_controller.dart';
import 'package:six_cash/features/home/controllers/menu_controller.dart';
import 'package:six_cash/features/language/controllers/localization_controller.dart';
import 'package:six_cash/features/setting/controllers/profile_screen_controller.dart';
import 'package:six_cash/features/auth/domain/models/user_short_data_model.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/app_constants.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/images.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/common/widgets/custom_country_code_widget.dart';
import 'package:six_cash/common/widgets/custom_password_field_widget.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/features/auth/widgets/qr_code_popup_widget.dart';
import 'package:six_cash/helper/tween_helper.dart';
import 'package:six_cash/common/widgets/hero_dialogue_route_widget.dart';

/// Unified login screen with inline Customer / Cashier toggle.
/// Selecting "Cashier" no longer navigates to a separate page;
/// instead the form fields animate in-place.
class LoginScreen extends StatefulWidget {
  final String? phoneNumber;
  final String? countryCode;

  const LoginScreen({Key? key, this.phoneNumber, this.countryCode})
    : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  // ─── Customer fields ─────────────────────────────────────────
  TextEditingController phoneController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  FocusNode phoneFocus = FocusNode();
  FocusNode passFocus = FocusNode();

  // ─── Cashier fields ──────────────────────────────────────────
  final TextEditingController _cashierUsernameController =
      TextEditingController();
  final TextEditingController _cashierPasswordController =
      TextEditingController();
  final FocusNode _cashierUsernameFocus = FocusNode();
  final FocusNode _cashierPasswordFocus = FocusNode();
  bool _cashierShowPassword = false;

  // ─── Shared state ────────────────────────────────────────────
  final String _heroQrTag = 'hero-qr-tag';
  String? _countryCode;
  UserShortDataModel? userData;

  /// false = customer, true = cashier
  bool _isCashierMode = false;

  void setCountryCode(String code) {
    _countryCode = code;
  }

  void setInitialCountryCode(String? code) {
    _countryCode = code;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    userData = Get.find<AuthController>().getUserData();
    if (widget.phoneNumber != userData?.phone) {
      Get.find<AuthController>().removeUserData();
      userData = null;
    }

    if (!_isCashierMode) {
      Get.find<AuthController>().authenticateWithBiometric(true, null, fromUserInteraction: false);
    }

    setInitialCountryCode(widget.countryCode);
    phoneController.text = widget.phoneNumber!;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Biometric authentication on app resume intentionally disabled
    // (no operation)
    
    }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    phoneController.dispose();
    passwordController.dispose();
    phoneFocus.dispose();
    passFocus.dispose();
    _cashierUsernameController.dispose();
    _cashierPasswordController.dispose();
    _cashierUsernameFocus.dispose();
    _cashierPasswordFocus.dispose();
    super.dispose();
  }

  // ─── Toggle handler ──────────────────────────────────────────
  void _switchMode(bool cashier) {
    if (_isCashierMode == cashier) return;
    setState(() => _isCashierMode = cashier);

    // Restore cashier session if switching into cashier mode
    if (cashier && Get.isRegistered<CashierAuthController>()) {
      Get.find<CashierAuthController>().restoreSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationController = Get.find<LocalizationController>();
    final languageName =
        AppConstants
            .languages[localizationController.selectedIndex]
            .languageName ??
        '';

    return Scaffold(
      backgroundColor: BqColors.brand,
      body: GetBuilder<AuthController>(
        builder: (authController) => AbsorbPointer(
          absorbing: authController.isLoading,
          child: Container(
              decoration: const BoxDecoration(gradient: BqGradients.proHeader),
            child: SafeArea(
              child: Column(
                children: [
                  // ────────── Header (logo + language) ──────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    child: Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            Images.logo,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                style: rubikMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                              ),
                              Text(
                                'BUQSH',
                                style: rubikRegular.copyWith(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: AppConstants.languages.length > 1
                                ? () => Get.toNamed(
                                    RouteHelper.getChoseLanguageRoute(),
                                  )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.language,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    languageName,
                                    style: rubikRegular.copyWith(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ────────── Card body ──────────
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(BqRadius.large),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── Welcome text + QR ──
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              'welcome_back'.tr,
                                              textAlign: TextAlign.center,
                                              style: rubikMedium.copyWith(
                                                color:
                                                    ColorResources.getPrimaryTextColor(),
                                                fontSize:
                                                    Dimensions.fontSizeLarge,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              userData?.name?.isNotEmpty == true
                                                  ? userData!.name!
                                                  : 'user'.tr,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: rubikMedium.copyWith(
                                                color:
                                                    ColorResources.getPrimaryTextColor(),
                                                fontSize: 22,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'please_authenticate_to_login'.tr,
                                              textAlign: TextAlign.center,
                                              style: rubikRegular.copyWith(
                                                color:
                                                    ColorResources.getGreyColor(),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (userData?.qrCode != null)
                                        IconButton(
                                          tooltip: 'qr_code'.tr,
                                          onPressed: () =>
                                              Navigator.of(context).push(
                                                HeroDialogRouteWidget(
                                                  builder: (_) =>
                                                      const QrCodePopupWidget(),
                                                ),
                                              ),
                                          icon: Hero(
                                            tag: _heroQrTag,
                                            createRectTween: (begin, end) =>
                                                TweenHelper(
                                                  begin: begin,
                                                  end: end,
                                                ),
                                            child: SizedBox(
                                              width: 38,
                                              height: 38,
                                              child: SvgPicture.string(
                                                userData!.qrCode!,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 22),

                                  // ── Toggle: Customer / Cashier ──
                                  _buildToggleBar(),
                                  const SizedBox(height: 22),

                                  // ── Dynamic form fields ──
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    switchInCurve: Curves.easeInOut,
                                    switchOutCurve: Curves.easeInOut,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SizeTransition(
                                          sizeFactor: animation,
                                          alignment: Alignment.topCenter,
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _isCashierMode
                                        ? _buildCashierFields()
                                        : _buildCustomerFields(authController),
                                  ),

                                  const SizedBox(height: 18),

                                  // ── Biometric divider ──
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color:
                                              ColorResources.getGreyBaseGray4(),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'biometric_login'.tr,
                                          style: rubikRegular.copyWith(
                                            color:
                                                ColorResources.getGreyColor(),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color:
                                              ColorResources.getGreyBaseGray4(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // ── Biometric button ──
                                  Center(
                                    child: OutlinedButton.icon(
                                      onPressed: () => authController
                                          .authenticateWithBiometric(
                                            true,
                                            null,
                                          ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            ColorResources.getPrimaryTextColor(),
                                        side: BorderSide(
                                          color:
                                              ColorResources.getPrimaryColor()
                                                  .withValues(alpha: 0.55),
                                        ),
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 26,
                                          vertical: 12,
                                        ),
                                      ),
                                      icon: Image.asset(
                                        Images.fingerprint,
                                        width: 22,
                                        height: 22,
                                        color:
                                            ColorResources.getPrimaryIconColor(),
                                      ),
                                      label: Text(
                                        'biometric_login'.tr,
                                        style: rubikMedium,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Security footer ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        size: 15,
                                        color: ColorResources.getGreyColor(),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'secure_data'.tr,
                                        style: rubikRegular.copyWith(
                                          color: ColorResources.getGreyColor(),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Toggle bar (Customer ↔ Cashier)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildToggleBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ColorResources.getLightGray(),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: ColorResources.getGreyBaseGray4().withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // ── Customer tab ──
          Expanded(
            child: _buildModeOption(
              icon: Icons.person_outline,
              title: 'customer_login'.tr,
              subtitle: 'تطبيق المستخدم',
              selected: !_isCashierMode,
              onTap: () => _switchMode(false),
            ),
          ),
          // ── Cashier tab ──
          Expanded(
            child: _buildModeOption(
              icon: Icons.storefront_outlined,
              title: 'cashier_login'.tr,
              subtitle: 'تطبيق التاجر والكاشير',
              selected: _isCashierMode,
              onTap: () => _switchMode(true),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Customer form fields
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCustomerFields(AuthController authController) {
    return Column(
      key: const ValueKey('customer_fields'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldFrame(
          context,
          Row(
            children: [
              Icon(
                Icons.phone_iphone_outlined,
                color: ColorResources.getPrimaryIconColor(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  focusNode: phoneFocus,
                  onSubmitted: (_) => FocusScope.of(
                    context,
                  ).requestFocus(passFocus),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  style: rubikRegular.copyWith(
                    color: ColorResources.getTextColor(),
                  ),
                  decoration: InputDecoration(
                    hintText: 'account'.tr,
                    hintStyle: rubikRegular.copyWith(
                      color: ColorResources.getGreyColor(),
                    ),
                    border: InputBorder.none,
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 74,
                    ),
                    prefixIcon: CustomCountryCodeWidget(
                      initSelect: widget.countryCode,
                      onChanged: (countryCode) => setCountryCode(
                        countryCode.dialCode!,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '4_digit_pin'.tr,
          style: rubikMedium.copyWith(
            color: ColorResources.getPrimaryTextColor(),
            fontSize: Dimensions.fontSizeDefault,
          ),
        ),
        const SizedBox(height: 8),
        CustomPasswordFieldWidget(
          hint: '＊＊＊＊',
          controller: passwordController,
          focusNode: passFocus,
          isShowSuffixIcon: true,
          isPassword: true,
          isIcon: false,
          prefixIcon: Icons.lock_outline,
          textInputAction: TextInputAction.done,
          textAlign: TextAlign.start,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () => Get.toNamed(
              RouteHelper.getForgetPassRoute(
                countryCode: _countryCode,
                phoneNumber: phoneController.text.trim(),
              ),
            ),
            child: Text(
              '${'forget_pin'.tr}?',
              style: rubikRegular.copyWith(
                color: ColorResources.getPrimaryTextColor(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => _loginCustomer(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorResources.getSecondaryHeaderColor(),
              foregroundColor: ColorResources.getPrimaryTextColor(),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: authController.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward, size: 24),
            label: Text(
              'login'.tr,
              style: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Cashier form fields (embedded, no navigation)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCashierFields() {
    return GetBuilder<CashierAuthController>(
      builder: (cashierController) {
        final errorMessage = cashierController.errorMessage;
        return AbsorbPointer(
          absorbing: cashierController.isLoading,
          child: Column(
            key: const ValueKey('cashier_fields'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Username / phone field ──
              _buildFieldFrame(
                context,
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: ColorResources.getPrimaryIconColor(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cashierUsernameController,
                        focusNode: _cashierUsernameFocus,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        onSubmitted: (_) => FocusScope.of(context)
                            .requestFocus(_cashierPasswordFocus),
                        style: rubikRegular.copyWith(
                          color: ColorResources.getTextColor(),
                        ),
                        decoration: InputDecoration(
                          hintText: 'cashier_username'.tr,
                          hintStyle: rubikRegular.copyWith(
                            color: ColorResources.getGreyColor(),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── PIN / Password field ──
              Text(
                'رمز PIN',
                style: rubikMedium.copyWith(
                  color: ColorResources.getPrimaryTextColor(),
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              const SizedBox(height: 8),
              _buildFieldFrame(
                context,
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: ColorResources.getPrimaryIconColor(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cashierPasswordController,
                        focusNode: _cashierPasswordFocus,
                        obscureText: !_cashierShowPassword,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        autofillHints: const [AutofillHints.password],
                        onSubmitted: (_) => _loginCashier(cashierController),
                        style: rubikRegular.copyWith(
                          color: ColorResources.getTextColor(),
                          fontSize: 17,
                          letterSpacing: 2,
                        ),
                        decoration: InputDecoration(
                          hintText: 'أدخل رمز PIN المكون من 4 أرقام',
                          hintStyle: rubikRegular.copyWith(
                            color: ColorResources.getGreyColor(),
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _cashierShowPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .color,
                              size: 18,
                            ),
                            onPressed: () => setState(
                              () => _cashierShowPassword =
                                  !_cashierShowPassword,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Error message ──
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorMessage,
                    style: rubikRegular.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              // ── Forget PIN (cashier) ──
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () {
                    // Placeholder: cashier forget-PIN flow
                    showCustomSnackBarHelper(
                      'تواصل مع المسؤول لإعادة تعيين رمز PIN',
                      isError: false,
                    );
                  },
                  child: Text(
                    'نسيت رمز PIN؟',
                    style: rubikRegular.copyWith(
                      color: ColorResources.getPrimaryTextColor(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Login button ──
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: cashierController.isLoading
                      ? null
                      : () => _loginCashier(cashierController),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorResources.getSecondaryHeaderColor(),
                    foregroundColor: ColorResources.getPrimaryTextColor(),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: cashierController.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward, size: 24),
                  label: Text(
                    'login'.tr,
                    style: rubikMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Shared helpers
  // ═══════════════════════════════════════════════════════════════
  Widget _buildModeOption({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected
          ? ColorResources.getSecondaryHeaderColor()
          : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: ColorResources.getPrimaryTextColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: rubikMedium.copyWith(
                        color: ColorResources.getPrimaryTextColor(),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: rubikRegular.copyWith(
                    color: ColorResources.getGreyColor(),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldFrame(BuildContext context, Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: ColorResources.getGreyBaseGray4().withValues(alpha: 0.65),
        ),
      ),
      child: child,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  Login actions
  // ═══════════════════════════════════════════════════════════════
  Future<void> _loginCustomer(BuildContext context) async {
    Get.find<MenuItemController>().resetNavBarTabIndex();
    String? code = _countryCode;
    String phone = phoneController.text.trim();
    String password = passwordController.text.trim();
    if (phone.isEmpty) {
      showCustomSnackBarHelper(
        'please_give_your_phone_number'.tr,
        isError: true,
      );
    } else if (password.isEmpty) {
      showCustomSnackBarHelper('please_enter_your_valid_pin'.tr, isError: true);
    } else if (password.length != 4) {
      showCustomSnackBarHelper('pin_should_be_4_digit'.tr, isError: true);
    } else {
      try {
        await Get.find<AuthController>().setUserData(
          UserShortDataModel(phone: phone, countryCode: _countryCode),
        );

        Get.find<AuthController>()
            .login(code: code!, phone: phone, password: password)
            .then((value) async {
              if (value.isOk) {
                try {
                  await Get.find<AuthController>().authRepo.writeSecureData(AppConstants.biometricPin, password);
                  await Get.find<ProfileController>().getProfileData(
                    reload: true,
                  );
                } catch (e) {
                  debugPrint('Profile fetch error after login: $e');
                }
              }
            });
      } catch (e) {
        showCustomSnackBarHelper(
          'please_input_your_valid_number'.tr,
          isError: true,
        );
      }
    }
  }

  Future<void> _loginCashier(CashierAuthController controller) async {
    final username = _cashierUsernameController.text.trim();
    final password = _cashierPasswordController.text;
    if (username.isEmpty || password.isEmpty) {
      showCustomSnackBarHelper(
        'cashier_login_failed'.tr,
        isError: true,
      );
      return;
    }
    await controller.login(username: username, password: password);
  }
}
