import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';
import 'package:six_cash/features/camera_verification/screens/camera_screen.dart';
import 'package:six_cash/features/pos/controllers/pos_controller.dart';
import 'package:six_cash/features/pos/models/pos_terminal.dart';
import 'package:six_cash/features/pos/screens/pos_receipt_screen.dart';
import 'package:six_cash/features/pos/services/pos_api_service.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';
import 'package:six_cash/utils/tafqeet_helper.dart';

class PosPaymentScreen extends StatefulWidget {
  final String? initialTerminalNumber;

  const PosPaymentScreen({Key? key, this.initialTerminalNumber})
    : super(key: key);

  @override
  State<PosPaymentScreen> createState() => _PosPaymentScreenState();
}

class _PosPaymentScreenState extends State<PosPaymentScreen> {
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // 1: عبر بقش (نشط)، 2: عبر محافظ أخرى
  int _selectedTab = 0;

  WalletModel? _selectedWallet;
  bool _isBalanceHidden = false;

  // قائمة النقاط المفضلة السريعة
  final List<Map<String, String>> _favoriteTerminals = const [
    {
      'number': '1001',
      'name': 'favorite_terminal_supermarket',
      'city': 'sanaa',
    },
    {'number': '1002', 'name': 'favorite_terminal_pharmacy', 'city': 'aden'},
    {'number': '2005', 'name': 'favorite_terminal_center', 'city': 'taiz'},
  ];

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<PosController>()) {
      Get.put(
        PosController(posApiService: PosApiService(apiClient: Get.find())),
      );
    }

    final walletCtrl = Get.find<WalletController>();
    if (walletCtrl.wallets.isEmpty) {
      walletCtrl.getWallets();
    } else {
      _initWallet(walletCtrl.wallets);
    }

    if (widget.initialTerminalNumber != null &&
        widget.initialTerminalNumber?.isNotEmpty == true) {
      _terminalController.text = widget.initialTerminalNumber ?? '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final posCtrl = Get.find<PosController>();
        posCtrl.lookupTerminal(_terminalController.text.trim());
      });
    }
  }

  void _initWallet(List<WalletModel> wallets) {
    if (wallets.isEmpty) return;
    final sorted = _sortWallets(wallets);
    _selectedWallet ??= sorted.firstWhere(
      (w) => w.currencyCode.toUpperCase() == 'YER',
      orElse: () => sorted.first,
    );
  }

  void _syncSelectedWallet(List<WalletModel> wallets) {
    if (wallets.isEmpty) return;

    final selectedId = _selectedWallet?.id;
    for (final wallet in wallets) {
      if (wallet.id == selectedId) {
        _selectedWallet = wallet;
        return;
      }
    }

    _selectedWallet = null;
    _initWallet(wallets);
  }

  /// فرز المحافظ: الريال اليمني YER يظهر أولاً دائماً
  List<WalletModel> _sortWallets(List<WalletModel> wallets) {
    List<WalletModel> list = List<WalletModel>.from(wallets);
    list.sort((a, b) {
      if (a.currencyCode.toUpperCase() == 'YER') return -1;
      if (b.currencyCode.toUpperCase() == 'YER') return 1;
      return a.currencyCode.compareTo(b.currencyCode);
    });
    return list;
  }

  @override
  void dispose() {
    _terminalController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// مسح الباركود / رمز QR للنقطة
  Future<void> _scanBarcode() async {
    try {
      final result = await Get.to(
        () => const CameraScreen(
          fromEditProfile: false,
          isBarCodeScan: true,
          isHome: false,
        ),
      );
      if (result != null && result is String && result.trim().isNotEmpty) {
        final scanned = result.trim();
        setState(() {
          _terminalController.text = scanned;
        });
        final posCtrl = Get.find<PosController>();
        await posCtrl.lookupTerminal(scanned);
      }
    } catch (_) {
      showCustomSnackBarHelper('qr_code_scanner_not_working'.tr, isError: true);
    }
  }

  /// عرض قائمة النقاط المفضلة
  void _showFavoriteTerminals() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusSizeLarge),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'favorite_terminals'.tr,
                          style: rubikSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                ..._favoriteTerminals.map((item) {
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ColorResources.primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.storefront,
                        color: ColorResources.primaryColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      (item['name'] ?? '').tr,
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    subtitle: Text(
                      '${'terminal_number'.tr}: ${item['number']} - ${(item['city'] ?? '').tr}',
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ColorResources.getGreyColor(),
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      Navigator.pop(ctx);
                      final num = item['number'] ?? '';
                      setState(() {
                        _terminalController.text = num;
                      });
                      final posCtrl = Get.find<PosController>();
                      posCtrl.lookupTerminal(num);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  /// تنفيذ عملية الدفع
  Future<void> _handleConfirmPayment(PosController posCtrl) async {
    final terminal = posCtrl.selectedTerminal;
    if (terminal == null ||
        terminal.terminalNumber.trim() != _terminalController.text.trim()) {
      showCustomSnackBarHelper(
        'please_search_terminal_first'.tr,
        isError: true,
      );
      return;
    }

    if (_selectedWallet == null) {
      showCustomSnackBarHelper('please_select_wallet'.tr, isError: true);
      return;
    }

    final amountText = _amountController.text.trim();
    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showCustomSnackBarHelper('enter_valid_amount'.tr, isError: true);
      return;
    }

    final currentBalance = _selectedWallet?.currentBalance ?? 0.0;
    if (amount > currentBalance) {
      showCustomSnackBarHelper('insufficient_balance'.tr, isError: true);
      return;
    }

    final currency = _selectedWallet?.currencyCode ?? 'YER';

    // نافذة تأكيد الدفع
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusSizeLarge),
        ),
      ),
      builder: (_) => _PosPaymentConfirmationSheet(
        terminal: terminal,
        amount: amount,
        currencyCode: currency,
      ),
    );

    if (!mounted || confirmed != true) return;

    final success = await posCtrl.purchase(
      terminalNumber: terminal.terminalNumber,
      amount: amount,
      currencyCode: currency,
    );

    if (success && posCtrl.lastResult != null) {
      final result = posCtrl.lastResult;
      if (result != null) {
        Get.snackbar(
          'success'.tr,
          'your_payment_successfully_done'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        // تحديث المحافظ تلقائياً
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().getWallets(reload: true);
        }
        Get.to(() => PosReceiptScreen(result: result));
      }
    } else {
      showCustomSnackBarHelper(
        posCtrl.errorMessage ?? 'purchase_failed'.tr,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbarWidget(title: 'svc_pos'.tr),
      body: GetBuilder<WalletController>(
        builder: (walletCtrl) {
          final wallets = _sortWallets(walletCtrl.wallets);
          _syncSelectedWallet(wallets);

          final currentBalance = _selectedWallet?.currentBalance ?? 0.0;
          final currentCurrency = _selectedWallet?.currencyCode ?? 'YER';
          final double? enteredAmount = double.tryParse(
            _amountController.text.trim(),
          );
          final bool isOverBalance =
              enteredAmount != null && enteredAmount > currentBalance;

          return GetBuilder<PosController>(
            builder: (posCtrl) {
              final terminal = posCtrl.selectedTerminal;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    // ==========================================
                    // 1. زرين (عبر بقش - نشط، عبر محافظ أخرى)
                    // ==========================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusSizeDefault,
                        ),
                        border: Border.all(
                          color: ColorResources.getGreyColor().withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // عبر بقش (نص حرفي صارم: "عبر بقش")
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 0;
                                });
                              },
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusSizeDefault,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? ColorResources.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSizeDefault,
                                  ),
                                ),
                                child: Text(
                                  'pos_via_buqsh'.tr,
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // عبر محافظ أخرى
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTab = 1;
                                });
                              },
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusSizeDefault,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? ColorResources.primaryColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    Dimensions.radiusSizeDefault,
                                  ),
                                ),
                                child: Text(
                                  'via_other_wallets'.tr,
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ==========================================
                    // 2. Dropdown للمحفظة (YER أولاً + زر عين)
                    // ==========================================
                    Text(
                      'select_wallet'.tr,
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusSizeDefault,
                        ),
                        border: Border.all(
                          color: ColorResources.getGreyColor().withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedWallet?.id.toString(),
                                dropdownColor: Theme.of(context).cardColor,
                                icon: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: ColorResources.getGreyColor(),
                                ),
                                items: wallets.map((w) {
                                  return DropdownMenuItem<String>(
                                    value: w.id.toString(),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: ColorResources.primaryColor
                                                .withOpacity(0.08),
                                          ),
                                          child: Text(
                                            w.currencySymbol,
                                            style: rubikSemiBold.copyWith(
                                              fontSize: 13,
                                              color:
                                                  ColorResources.primaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                w.currencyCode,
                                                style: rubikMedium.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                ),
                                              ),
                                              Text(
                                                w.currencyName,
                                                style: rubikRegular.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeExtraSmall,
                                                  color:
                                                      ColorResources.getGreyColor(),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _isBalanceHidden
                                              ? '*****'
                                              : CurrencyFormatter.format(
                                                  w.currentBalance,
                                                  currency: w.currencyCode,
                                                ),
                                          style: rubikMedium.copyWith(
                                            fontSize: Dimensions.fontSizeSmall,
                                            color: ColorResources.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (walletId) {
                                  final matchingWallets = wallets.where(
                                    (wallet) =>
                                        wallet.id.toString() == walletId,
                                  );
                                  if (matchingWallets.isNotEmpty) {
                                    setState(() {
                                      _selectedWallet = matchingWallets.first;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _isBalanceHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: ColorResources.primaryColor,
                              size: 22,
                            ),
                            tooltip: 'your_balance'.tr,
                            onPressed: () {
                              setState(() {
                                _isBalanceHidden = !_isBalanceHidden;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Text(
                            '${'available_balance_label'.tr}: ',
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: ColorResources.getGreyColor(),
                            ),
                          ),
                          Text(
                            _isBalanceHidden
                                ? '***** $currentCurrency'
                                : CurrencyFormatter.format(
                                    currentBalance,
                                    currency: currentCurrency,
                                  ),
                            style: rubikSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ==========================================
                    // 3. حقل رقم النقطة (مع أيقونة قلب وباركود)
                    // ==========================================
                    Text(
                      'terminal_number'.tr,
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _terminalController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.search,
                            onChanged: (value) {
                              final selectedTerminal = posCtrl.selectedTerminal;
                              if (posCtrl.isLoading ||
                                  (selectedTerminal != null &&
                                      selectedTerminal.terminalNumber !=
                                          value.trim())) {
                                posCtrl.clearTerminal();
                              }
                            },
                            onSubmitted: (val) {
                              if (val.trim().isNotEmpty) {
                                posCtrl.lookupTerminal(val.trim());
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'enter_terminal_number'.tr,
                              hintStyle: rubikRegular.copyWith(
                                color: ColorResources.getGreyColor(),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: 14,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // أيقونة القلب (النقاط المفضلة)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite_border,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    tooltip: 'favorite_terminals'.tr,
                                    onPressed: _showFavoriteTerminals,
                                  ),
                                  // أيقونة الباركود
                                  IconButton(
                                    icon: const Icon(
                                      Icons.qr_code_scanner,
                                      color: ColorResources.primaryColor,
                                      size: 22,
                                    ),
                                    tooltip: 'scan_qr_code'.tr,
                                    onPressed: _scanBarcode,
                                  ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSizeDefault,
                                ),
                                borderSide: BorderSide(
                                  color: ColorResources.getGreyColor()
                                      .withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSizeDefault,
                                ),
                                borderSide: BorderSide(
                                  color: ColorResources.getGreyColor()
                                      .withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSizeDefault,
                                ),
                                borderSide: const BorderSide(
                                  color: ColorResources.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorResources.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSizeDefault,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeLarge,
                              ),
                            ),
                            onPressed: posCtrl.isLoading
                                ? null
                                : () => posCtrl.lookupTerminal(
                                    _terminalController.text,
                                  ),
                            child: posCtrl.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    children: [
                                      const Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'search'.tr,
                                        style: rubikMedium.copyWith(
                                          color: Colors.white,
                                          fontSize: Dimensions.fontSizeSmall,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // ==========================================
                    // 4. بطاقة بيانات النقطة (اسم النقطة بلون primaryColor)
                    // ==========================================
                    if (terminal != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          Dimensions.paddingSizeDefault,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSizeDefault,
                          ),
                          border: Border.all(
                            color: ColorResources.primaryColor.withOpacity(
                              0.25,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: ColorResources.primaryColor
                                        .withOpacity(0.1),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_outlined,
                                    color: ColorResources.primaryColor,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(
                                  width: Dimensions.paddingSizeSmall,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // اسم النقطة بلون primaryColor
                                      Text(
                                        terminal.terminalName,
                                        style: rubikSemiBold.copyWith(
                                          fontSize: Dimensions.fontSizeLarge,
                                          color: ColorResources.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '#${terminal.terminalNumber}',
                                        style: rubikRegular.copyWith(
                                          fontSize:
                                              Dimensions.fontSizeExtraSmall,
                                          color: ColorResources.getGreyColor(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSizeVerySmall,
                                    ),
                                  ),
                                  child: Text(
                                    terminal.status.toUpperCase(),
                                    style: rubikMedium.copyWith(
                                      fontSize: Dimensions.fontSizeExtraSmall,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            if (terminal.city.isNotEmpty) ...[
                              _InfoRow(
                                icon: Icons.location_city_outlined,
                                label: 'city'.tr,
                                value: terminal.city,
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (terminal.address.isNotEmpty) ...[
                              _InfoRow(
                                icon: Icons.place_outlined,
                                label: 'address'.tr,
                                value: terminal.address,
                              ),
                              const SizedBox(height: 6),
                            ],
                            _InfoRow(
                              icon: Icons.monetization_on_outlined,
                              label: 'currency'.tr,
                              value: terminal.currencyCode.isNotEmpty
                                  ? terminal.currencyCode
                                  : 'YER',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      // ==========================================
                      // 5. حقل المبلغ (حدود سوداء سميكة) + تفقيط
                      // ==========================================
                      Text(
                        'purchase_amount'.tr,
                        style: rubikMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSizeDefault,
                          ),
                          // القاعدة الصارمة 5: حقل المبلغ فقط هو من يحصل على حدود سوداء عريضة
                          border: Border.all(
                            width: 2.0,
                            color: isOverBalance
                                ? ColorResources.errorColor
                                : Colors.black,
                          ),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          style: rubikSemiBold.copyWith(
                            fontSize: 22,
                            color: isOverBalance
                                ? ColorResources.errorColor
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: rubikRegular.copyWith(
                              fontSize: 20,
                              color: ColorResources.getGreyColor().withOpacity(
                                0.5,
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: 14,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: 14,
                              ),
                              child: Text(
                                currentCurrency,
                                style: rubikSemiBold.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: ColorResources.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // تنبيه تجاوز الرصيد
                      if (isOverBalance) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: ColorResources.errorColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'insufficient_balance'.tr,
                              style: rubikRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: ColorResources.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // تفقيط المبلغ كتابةً باللغة العربية
                      if (enteredAmount != null && enteredAmount > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: ColorResources.primaryColor.withOpacity(
                              0.06,
                            ),
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSizeSmall,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                size: 16,
                                color: ColorResources.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  TafqeetHelper.convert(
                                    enteredAmount,
                                    currencyCode: currentCurrency,
                                  ),
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: ColorResources.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                      // ==========================================
                      // 6. زر تأكيد الدفع (أخضر ColorResources.primaryColor)
                      // ==========================================
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorResources.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                Dimensions.radiusSizeDefault,
                              ),
                            ),
                            elevation: 0,
                          ),
                          onPressed: (posCtrl.isLoading || isOverBalance)
                              ? null
                              : () => _handleConfirmPayment(posCtrl),
                          child: posCtrl.isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'pay_now'.tr,
                                  style: rubikSemiBold.copyWith(
                                    color: Colors.white,
                                    fontSize: Dimensions.fontSizeDefault,
                                  ),
                                ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 60),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PosPaymentConfirmationSheet extends StatelessWidget {
  final PosTerminal terminal;
  final double amount;
  final String currencyCode;

  const _PosPaymentConfirmationSheet({
    required this.terminal,
    required this.amount,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'confirm_pos_payment'.tr,
              style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _DialogRow(
              label: 'terminal_name'.tr,
              value: terminal.terminalName,
              valueColor: ColorResources.primaryColor,
              isBold: true,
            ),
            const SizedBox(height: 8),
            _DialogRow(
              label: 'terminal_number'.tr,
              value: terminal.terminalNumber,
            ),
            if (terminal.city.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DialogRow(label: 'city'.tr, value: terminal.city),
            ],
            const SizedBox(height: 8),
            _DialogRow(
              label: 'purchase_amount'.tr,
              value: CurrencyFormatter.format(amount, currency: currencyCode),
              isBold: true,
            ),
            const SizedBox(height: 8),
            _DialogRow(label: 'from_wallet'.tr, value: currencyCode),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('cancel'.tr),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorResources.primaryColor,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'confirm'.tr,
                      style: rubikMedium.copyWith(color: Colors.white),
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
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ColorResources.getGreyColor()),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: rubikRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: ColorResources.getGreyColor(),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: rubikMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _DialogRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label: ',
          style: rubikRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: ColorResources.getGreyColor(),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: isBold
                ? rubikSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: valueColor,
                  )
                : rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: valueColor,
                  ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
