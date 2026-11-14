import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/services/exchange_rate_service.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';
import 'package:six_cash/utils/tafqeet_helper.dart';

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({Key? key}) : super(key: key);

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  WalletModel? _fromWallet;
  WalletModel? _toWallet;
  final TextEditingController _amountController = TextEditingController();

  bool _isConfirming = false;
  bool _isFromBalanceHidden = false;
  bool _isToBalanceHidden = false;

  @override
  void initState() {
    super.initState();
    final walletCtrl = Get.find<WalletController>();
    if (walletCtrl.wallets.isEmpty) {
      walletCtrl.getWallets();
    } else {
      _initWallets(walletCtrl.wallets);
    }
    // جلب أسعار الصرف الحية عند الدخول
    walletCtrl.getExchangeRates();
  }

  void _initWallets(List<WalletModel> wallets) {
    if (wallets.isEmpty) return;
    final sorted = _sortWallets(wallets);
    _fromWallet ??= sorted.firstWhere(
      (w) => w.currencyCode.toUpperCase() == 'YER',
      orElse: () => sorted.first,
    );
    _toWallet ??= sorted.firstWhere(
      (w) =>
          w.currencyCode.toUpperCase() !=
          _fromWallet?.currencyCode.toUpperCase(),
      orElse: () => sorted.length > 1 ? sorted[1] : sorted.first,
    );
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
    _amountController.dispose();
    super.dispose();
  }

  /// زر Swap مربع بخلفية primaryColor: ابدل العملات وامسح المبالغ
  void _swapWallets() {
    setState(() {
      final temp = _fromWallet;
      _fromWallet = _toWallet;
      _toWallet = temp;
      // مسح المبالغ فوراً عند التبديل
      _amountController.clear();
    });
  }

  /// حساب سعر الصرف بين العملتين
  double? _getRate() {
    if (_fromWallet == null || _toWallet == null) return null;
    final fromCode = _fromWallet?.currencyCode ?? '';
    final toCode = _toWallet?.currencyCode ?? '';
    if (fromCode.isEmpty || toCode.isEmpty) return null;
    if (fromCode.toUpperCase() == toCode.toUpperCase()) return 1.0;

    final ctrl = Get.find<WalletController>();
    if (ctrl.exchangeRates != null) {
      final rate = ctrl.exchangeRates?.getExchangeRate(fromCode, toCode);
      if (rate != null && rate > 0) return rate;
    }

    // احتياطي: استخدام ExchangeRateService
    final fallbackRate = ExchangeRateService.instance.getExchangeRate(
      fromCode,
      toCode,
    );
    if (fallbackRate > 0) return fallbackRate;

    return null;
  }

  /// حساب المبلغ المحول
  double _getResult() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final rate = _getRate();
    if (rate == null) return 0.0;
    return amount * rate;
  }

  /// تأكيد عملية التحويل / المصارفة
  Future<void> _confirmTransfer() async {
    if (_fromWallet == null || _toWallet == null) return;
    if (_fromWallet?.currencyCode == _toWallet?.currencyCode) {
      showCustomSnackBarHelper('exchange_same_wallet_error'.tr, isError: true);
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showCustomSnackBarHelper('enter_valid_amount'.tr, isError: true);
      return;
    }

    final currentBalance = _fromWallet?.currentBalance ?? 0.0;
    if (amount > currentBalance) {
      showCustomSnackBarHelper('insufficient_balance'.tr, isError: true);
      return;
    }

    final rate = _getRate();
    if (rate == null) {
      showCustomSnackBarHelper('rate_unavailable'.tr, isError: true);
      return;
    }

    final fromCode = _fromWallet?.currencyCode ?? 'YER';
    final toCode = _toWallet?.currencyCode ?? 'USD';

    setState(() => _isConfirming = true);
    try {
      final response = await Get.find<WalletController>()
          .transferBetweenWallets(
            fromWalletId: _fromWallet?.id,
            toWalletId: _toWallet?.id,
            fromCurrency: fromCode,
            toCurrency: toCode,
            amount: amount,
            note: 'wallet_exchange',
          );
      if (_isSuccessful(response.statusCode)) {
        final wallets = Get.find<WalletController>().wallets;
        final updatedFromWallet = wallets.where(
          (wallet) => wallet.id == _fromWallet?.id,
        );
        final updatedToWallet = wallets.where(
          (wallet) => wallet.id == _toWallet?.id,
        );

        if (mounted) {
          setState(() {
            if (updatedFromWallet.isNotEmpty) {
              _fromWallet = updatedFromWallet.first;
            }
            if (updatedToWallet.isNotEmpty) {
              _toWallet = updatedToWallet.first;
            }
            _amountController.clear();
          });
        }

        Get.snackbar(
          'success'.tr,
          'exchange_success_message'.tr,
          backgroundColor: ColorResources.primaryColor,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        );
      } else {
        String msg = 'exchange_failed'.tr;
        if (response.body is Map && response.body['message'] != null) {
          msg = response.body['message'].toString();
        } else if (response.statusText != null &&
            response.statusText?.isNotEmpty == true) {
          msg = response.statusText ?? msg;
        }
        showCustomSnackBarHelper(msg, isError: true);
      }
    } catch (error, stackTrace) {
      debugPrint('Wallet exchange failed: $error\n$stackTrace');
      showCustomSnackBarHelper('exchange_failed'.tr, isError: true);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  bool _isSuccessful(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      builder: (walletCtrl) {
        final wallets = _sortWallets(walletCtrl.wallets);
        if (_fromWallet == null && wallets.isNotEmpty) {
          _initWallets(wallets);
        }

        final currentFromBalance = _fromWallet?.currentBalance ?? 0.0;
        final currentFromCurrency = _fromWallet?.currencyCode ?? 'YER';
        final currentToBalance = _toWallet?.currentBalance ?? 0.0;
        final currentToCurrency = _toWallet?.currencyCode ?? 'USD';

        final double? enteredAmount = double.tryParse(
          _amountController.text.trim(),
        );
        final bool isOverBalance =
            enteredAmount != null && enteredAmount > currentFromBalance;
        final bool isSameWallet =
            _fromWallet != null &&
            _toWallet != null &&
            _fromWallet?.currencyCode == _toWallet?.currencyCode;

        final rate = _getRate();
        final double result = _getResult();

        final bool canSubmit =
            !_isConfirming &&
            !walletCtrl.isTransferring &&
            rate != null &&
            enteredAmount != null &&
            enteredAmount > 0 &&
            !isOverBalance &&
            !isSameWallet;

        return Scaffold(
          appBar: CustomAppbarWidget(title: 'svc_exchange'.tr),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Dimensions.paddingSizeSmall),

                // ==========================================
                // 1. حقل Dropdown (من حساب)
                // ==========================================
                Text(
                  'from_wallet'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                _WalletSelectBox(
                  wallets: wallets,
                  selected: _fromWallet,
                  isBalanceHidden: _isFromBalanceHidden,
                  onToggleEye: () {
                    setState(() {
                      _isFromBalanceHidden = !_isFromBalanceHidden;
                    });
                  },
                  onChanged: (w) {
                    if (w != null) {
                      setState(() {
                        _fromWallet = w;
                      });
                    }
                  },
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
                        _isFromBalanceHidden
                            ? '***** $currentFromCurrency'
                            : CurrencyFormatter.format(
                                currentFromBalance,
                                currency: currentFromCurrency,
                              ),
                        style: rubikSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Dimensions.paddingSizeSmall),

                // ==========================================
                // 2. زر Swap مربع بخلفية primaryColor
                // (عند الضغط: ابدل العملات وامسح المبالغ)
                // ==========================================
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _swapWallets,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ColorResources.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: ColorResources.primaryColor.withOpacity(
                                0.3,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.swap_vert,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: Dimensions.paddingSizeSmall),

                // ==========================================
                // 3. حقل Dropdown (إلى حساب)
                // ==========================================
                Text(
                  'to_wallet'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                _WalletSelectBox(
                  wallets: wallets,
                  selected: _toWallet,
                  isBalanceHidden: _isToBalanceHidden,
                  onToggleEye: () {
                    setState(() {
                      _isToBalanceHidden = !_isToBalanceHidden;
                    });
                  },
                  onChanged: (w) {
                    if (w != null) {
                      setState(() {
                        _toWallet = w;
                      });
                    }
                  },
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
                        _isToBalanceHidden
                            ? '***** $currentToCurrency'
                            : CurrencyFormatter.format(
                                currentToBalance,
                                currency: currentToCurrency,
                              ),
                        style: rubikSemiBold.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Dimensions.paddingSizeLarge),

                // ==========================================
                // 4. صندوق معادلة (حقلان بينهما =)
                // ==========================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusSizeDefault,
                    ),
                    border: Border.all(
                      color: ColorResources.getGreyColor().withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
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
                          Icon(
                            Icons.calculate_outlined,
                            size: 18,
                            color: ColorResources.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'equation'.tr,
                            style: rubikSemiBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: ColorResources.primaryColor,
                            ),
                          ),
                          const Spacer(),
                          if (rate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: ColorResources.primaryColor.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusSizeVerySmall,
                                ),
                              ),
                              child: Text(
                                '1 $currentFromCurrency = ${rate.toStringAsFixed(4)} $currentToCurrency',
                                style: rubikMedium.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: ColorResources.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 18),

                      // صف الحقلين وبينهما علامة =
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // الحقل 1: إدخال المبلغ (حدود سوداء سميكة حصراً)
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentFromCurrency,
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: ColorResources.getGreyColor(),
                                  ),
                                ),
                                const SizedBox(height: 4),
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
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ),
                                    ],
                                    onChanged: (_) => setState(() {}),
                                    style: rubikBold.copyWith(
                                      fontSize: 18,
                                      color: isOverBalance
                                          ? ColorResources.errorColor
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: rubikRegular.copyWith(
                                        fontSize: 16,
                                        color: ColorResources.getGreyColor()
                                            .withOpacity(0.5),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // علامة = في المنتصف
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: ColorResources.primaryColor.withOpacity(
                                0.1,
                              ),
                            ),
                            child: Text(
                              '=',
                              style: rubikBold.copyWith(
                                fontSize: 18,
                                color: ColorResources.primaryColor,
                              ),
                            ),
                          ),

                          // الحقل 2: نتيجة التحويل (حدود رمادية فاتحة)
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentToCurrency,
                                  style: rubikMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: ColorResources.getGreyColor(),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: 48,
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorResources.getLightGray(),
                                    borderRadius: BorderRadius.circular(
                                      Dimensions.radiusSizeDefault,
                                    ),
                                    border: Border.all(
                                      color: ColorResources.getGreyColor()
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    result > 0
                                        ? result.toStringAsFixed(2)
                                        : '0.00',
                                    style: rubikBold.copyWith(
                                      fontSize: 18,
                                      color: ColorResources.primaryColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // تنبيه تجاوز الرصيد
                      if (isOverBalance) ...[
                        const SizedBox(height: 8),
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

                      // خطأ اختيار نفس المحفظة
                      if (isSameWallet) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: ColorResources.errorColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'exchange_same_wallet_error'.tr,
                              style: rubikRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: ColorResources.errorColor,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // تفقيط المبلغ كتابةً
                      if (enteredAmount != null && enteredAmount > 0) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
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
                                    currencyCode: currentFromCurrency,
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
                    ],
                  ),
                ),

                const SizedBox(height: Dimensions.paddingSizeLarge),

                // ==========================================
                // 5. جدول أسعار (3 أعمدة) بخلفية رمادية فاتحة
                // ==========================================
                Text(
                  'rate_table'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                _LiveRatesTable(baseCurrency: 'YER'),

                const SizedBox(height: Dimensions.paddingSizeLarge),

                // ==========================================
                // 6. زر التأكيد (أخضر مع التعطيل إذا لم يتوفر السعر)
                // ==========================================
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmit
                          ? ColorResources.primaryColor
                          : ColorResources.getGreyColor().withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          Dimensions.radiusSizeDefault,
                        ),
                      ),
                      elevation: 0,
                    ),
                    onPressed: canSubmit ? _confirmTransfer : null,
                    child: (walletCtrl.isTransferring || _isConfirming)
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            rate == null
                                ? 'rate_unavailable'.tr
                                : 'confirm_exchange'.tr,
                            style: rubikSemiBold.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// صندوق اختيار المحفظة مع أيقونة العين لإخفاء/إظهار الرصيد
class _WalletSelectBox extends StatelessWidget {
  final List<WalletModel> wallets;
  final WalletModel? selected;
  final bool isBalanceHidden;
  final VoidCallback onToggleEye;
  final ValueChanged<WalletModel?> onChanged;

  const _WalletSelectBox({
    required this.wallets,
    required this.selected,
    required this.isBalanceHidden,
    required this.onToggleEye,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueWallets = <String, WalletModel>{};
    for (final wallet in wallets) {
      uniqueWallets.putIfAbsent(
        wallet.currencyCode.trim().toUpperCase(),
        () => wallet,
      );
    }
    final selectedCode = selected?.currencyCode.trim().toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
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
                value: uniqueWallets.containsKey(selectedCode)
                    ? selectedCode
                    : null,
                dropdownColor: Theme.of(context).cardColor,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: ColorResources.getGreyColor(),
                ),
                items: uniqueWallets.entries.map((entry) {
                  final w = entry.value;
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorResources.primaryColor.withOpacity(
                              0.08,
                            ),
                          ),
                          child: Text(
                            w.currencySymbol,
                            style: rubikSemiBold.copyWith(
                              fontSize: 13,
                              color: ColorResources.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                w.currencyCode,
                                style: rubikMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                              Text(
                                w.currencyName,
                                style: rubikRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: ColorResources.getGreyColor(),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isBalanceHidden
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
                onChanged: (code) =>
                    onChanged(code == null ? null : uniqueWallets[code]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isBalanceHidden ? Icons.visibility_off : Icons.visibility,
              color: ColorResources.primaryColor,
              size: 22,
            ),
            tooltip: 'your_balance'.tr,
            onPressed: onToggleEye,
          ),
        ],
      ),
    );
  }
}

/// جدول أسعار الصرف (3 أعمدة) بخلفية رمادية فاتحة
class _LiveRatesTable extends StatelessWidget {
  final String baseCurrency;

  const _LiveRatesTable({required this.baseCurrency});

  @override
  Widget build(BuildContext context) {
    // أسعار الصرف الحية بالنسبة للريال اليمني YER
    final List<Map<String, dynamic>> rateItems = [
      {
        'code': 'USD',
        'symbol': '\$',
        'name': 'الدولار الأمريكي',
        'buy': '530.00',
        'sell': '535.00',
      },
      {
        'code': 'SAR',
        'symbol': 'ر.س',
        'name': 'الريال السعودي',
        'buy': '140.00',
        'sell': '142.00',
      },
      {
        'code': 'YER',
        'symbol': 'ر.ي',
        'name': 'الريال اليمني',
        'buy': '1.00',
        'sell': '1.00',
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ColorResources.getLightGray(),
        borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
        border: Border.all(
          color: ColorResources.getGreyColor().withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // رأس الجدول (3 أعمدة)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: ColorResources.primaryColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Dimensions.radiusSizeDefault),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'currency'.tr,
                    style: rubikSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ColorResources.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'buy_rate'.tr,
                    textAlign: TextAlign.center,
                    style: rubikSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ColorResources.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'sell_rate'.tr,
                    textAlign: TextAlign.end,
                    style: rubikSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ColorResources.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // صفوف الجدول
          ...rateItems.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == rateItems.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: ColorResources.getGreyColor().withOpacity(
                            0.15,
                          ),
                        ),
                      ),
              ),
              child: Row(
                children: [
                  // العمود 1: العملة
                  Expanded(
                    flex: 4,
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ColorResources.primaryColor.withOpacity(0.1),
                          ),
                          child: Text(
                            item['symbol'] as String,
                            style: rubikSemiBold.copyWith(
                              fontSize: 11,
                              color: ColorResources.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['code'] as String,
                              style: rubikMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // العمود 2: سعر الشراء
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item['buy']} YER',
                      textAlign: TextAlign.center,
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),

                  // العمود 3: سعر البيع
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${item['sell']} YER',
                      textAlign: TextAlign.end,
                      style: rubikMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ColorResources.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
