import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/models/contact_model.dart';
import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';
import 'package:six_cash/features/camera_verification/screens/camera_screen.dart';
import 'package:six_cash/features/transaction_money/controllers/contact_controller.dart';
import 'package:six_cash/features/transaction_money/widgets/send_money_confirmation_bottom_sheet.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';
import 'package:six_cash/utils/tafqeet_helper.dart';

class SendMoneyScreen extends StatefulWidget {
  final String? initialPhone;
  final ContactModel? initialContact;

  const SendMoneyScreen({
    Key? key,
    this.initialPhone,
    this.initialContact,
  }) : super(key: key);

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final String _countryCode = '+967'; // اليمن افتراضياً

  WalletModel? _selectedWallet;
  bool _isBalanceHidden = false;
  bool _isLoadingRecipient = false;
  String? _verifiedRecipientName;
  String? _recipientAvatar;

  bool _validMobile(String value) =>
      RegExp(r'^(70|71|73|77|78)\d{7}$').hasMatch(value.replaceAll(RegExp(r'\D'), ''));

  bool _validAmount(double? value, double balance) =>
      value != null && value >= 1 && value <= 999999 && value % 1 == 0 && value <= balance;

  @override
  void initState() {
    super.initState();

    final walletCtrl = Get.find<WalletController>();
    if (walletCtrl.wallets.isEmpty) {
      walletCtrl.getWallets();
    } else {
      _initWallet(walletCtrl.wallets);
    }

    if (widget.initialContact != null) {
      String phone = widget.initialContact?.phoneNumber ?? '';
      _setCleanPhone(phone);
      _verifiedRecipientName = widget.initialContact?.name;
      _recipientAvatar = widget.initialContact?.avatarImage;
    } else if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _setCleanPhone(widget.initialPhone ?? '');
    }
  }

  void _initWallet(List<WalletModel> wallets) {
    if (wallets.isEmpty) return;
    final sorted = _sortWallets(wallets);
    if (_selectedWallet == null) {
      // الريال اليمني YER يظهر أولاً ومحدد افتراضياً في كل Dropdown
      _selectedWallet = sorted.firstWhere(
        (w) => w.currencyCode.toUpperCase() == 'YER',
        orElse: () => sorted.first,
      );
    }
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

  void _setCleanPhone(String raw) {
    String cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+967')) {
      cleaned = cleaned.substring(4);
    } else if (cleaned.startsWith('00967')) {
      cleaned = cleaned.substring(5);
    } else if (cleaned.startsWith('0') && cleaned.length == 10) {
      cleaned = cleaned.substring(1);
    }
    _phoneController.text = cleaned;
    setState(() {
      _verifiedRecipientName = null;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// فتح جهات الاتصال
  Future<void> _pickContact() async {
    try {
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final contact = await FlutterContacts.openExternalPick();
        if (contact != null && contact.phones.isNotEmpty) {
          final phone = contact.phones.first.number;
          _setCleanPhone(phone);
          if (contact.displayName.isNotEmpty) {
            setState(() {
              _verifiedRecipientName = contact.displayName;
            });
          }
        }
      } else {
        showCustomSnackBarHelper(
          'you_must_allow_permission_for_further_use'.tr,
          isError: true,
        );
      }
    } catch (_) {
      showCustomSnackBarHelper('no_contact_available'.tr, isError: true);
    }
  }

  /// مسح الباركود QR
  Future<void> _scanBarcode() async {
    try {
      final result = await Get.to(() => const CameraScreen(
            fromEditProfile: false,
            isBarCodeScan: true,
            transactionType: 'send_money',
          ));

      if (result != null && result is String && result.isNotEmpty) {
        _setCleanPhone(result);
      }
    } catch (_) {}
  }

  /// متابعة العملية: التحقق وجلب اسم المستلم أولاً ثم فتح BottomSheet
  Future<void> _onContinuePressed() async {
    // 1. التحقق من المحفظة
    if (_selectedWallet == null) {
      showCustomSnackBarHelper('please_select_wallet'.tr, isError: true);
      return;
    }

    // 2. التحقق من رقم الهاتف
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      showCustomSnackBarHelper('please_enter_recipient_mobile'.tr, isError: true);
      return;
    }

    if (!_validMobile(phone)) {
      showCustomSnackBarHelper('please_input_your_valid_number'.tr, isError: true);
      return;
    }

    // 3. التحقق من المبلغ
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (!_validAmount(amount, _selectedWallet?.currentBalance ?? 0)) {
      showCustomSnackBarHelper('enter_valid_amount'.tr, isError: true);
      return;
    }

    // التحقق من الرصيد الكافي
    final balance = _selectedWallet?.currentBalance ?? 0.0;
    if (amount > balance) {
      showCustomSnackBarHelper('insufficient_balance'.tr, isError: true);
      return;
    }

    // 4. جلب اسم المستلم أولاً من الخادم
    setState(() {
      _isLoadingRecipient = true;
    });

    final fullPhone = '$_countryCode$phone';
    String resolvedName = _verifiedRecipientName ?? '';

    try {
      final contactCtrl = Get.find<ContactController>();
      final response = await contactCtrl.checkCustomerNumber(phoneNumber: fullPhone);

      if (response != null && response.statusCode == 200) {
        final data = response.body?['data'];
        if (data is Map) {
          final serverName = data['name']?.toString();
          if (serverName != null && serverName.isNotEmpty) {
            resolvedName = serverName;
          }
          _recipientAvatar = data['image']?.toString();
        }
      } else {
        // إذا فشل الاستعلام أو المستلم غير مسجل
        String errorMsg = 'customer_not_found'.tr;
        if (response?.body is Map && response?.body['message'] != null) {
          errorMsg = response?.body['message'].toString() ?? errorMsg;
        }
        showCustomSnackBarHelper(errorMsg, isError: true);
        return;
      }
    } catch (_) {
      showCustomSnackBarHelper('customer_not_found'.tr, isError: true);
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRecipient = false;
        });
      }
    }

    if (resolvedName.isEmpty) {
      resolvedName = fullPhone;
    }

    // 5. فتح نافذة التأكيد (Bottom Sheet)
    if (!mounted || _selectedWallet == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SendMoneyConfirmationBottomSheet(
        wallet: _selectedWallet!,
        recipientPhone: fullPhone,
        recipientName: resolvedName,
        recipientAvatar: _recipientAvatar,
        amount: amount,
        note: _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbarWidget(title: 'svc_send_to_subscriber'.tr),
      body: GetBuilder<WalletController>(
        builder: (walletCtrl) {
          final wallets = _sortWallets(walletCtrl.wallets);
          if (_selectedWallet == null && wallets.isNotEmpty) {
            _initWallet(wallets);
          }

          final currentBalance = _selectedWallet?.currentBalance ?? 0.0;
          final currentCurrency = _selectedWallet?.currencyCode ?? 'YER';
          final double? enteredAmount = double.tryParse(_amountController.text.trim());
          final bool isOverBalance =
              enteredAmount != null && enteredAmount > currentBalance;
          final bool canContinue = _selectedWallet != null &&
              _validMobile(_phoneController.text) &&
              _validAmount(enteredAmount, currentBalance);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: Dimensions.paddingSizeSmall),

                // ==========================================
                // 1. Dropdown للمحفظة (YER أولاً + زر عين)
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
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSizeDefault),
                    // باقي الحقول حدود رمادية فاتحة
                    border: Border.all(
                      color: ColorResources.getGreyColor().withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // القائمة المنسدلة للمحافظ
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<WalletModel>(
                            isExpanded: true,
                            value: _selectedWallet,
                            dropdownColor: Theme.of(context).cardColor,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: ColorResources.getGreyColor(),
                            ),
                            items: wallets.map((w) {
                              return DropdownMenuItem<WalletModel>(
                                value: w,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: ColorResources.primaryColor
                                            .withOpacity(0.08),
                                      ),
                                      child: Text(
                                        w.currencySymbol,
                                        style: rubikSemiBold.copyWith(
                                          fontSize: 14,
                                          color: ColorResources.primaryColor,
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
                                              fontSize:
                                                  Dimensions.fontSizeDefault,
                                            ),
                                          ),
                                          Text(
                                            w.currencyName,
                                            style: rubikRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeExtraSmall,
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
                            onChanged: (w) {
                              if (w != null) {
                                setState(() {
                                  _selectedWallet = w;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // زر العين بجانب Dropdown المحفظة
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
                // الرصيد المتاح تحت المحفظة
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
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: Dimensions.paddingSizeLarge),

                // ==========================================
                // 2. حقل موبايل (مع أيقونات باركود وجهات اتصال)
                // ==========================================
                Text(
                  'recipient_mobile'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSizeDefault),
                    // باقي الحقول حدود رمادية فاتحة
                    border: Border.all(
                      color: ColorResources.getGreyColor().withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(12),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _verifiedRecipientName = null;
                      });
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      hintText: '77XXXXXXX',
                      hintStyle: rubikRegular.copyWith(
                        color: ColorResources.getGreyColor().withOpacity(0.6),
                      ),
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _countryCode,
                              style: rubikMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 24,
                              color: ColorResources.getGreyColor()
                                  .withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // أيقونة مسح الباركود
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            color: ColorResources.primaryColor,
                            tooltip: 'scan_qr_code'.tr,
                            onPressed: _scanBarcode,
                          ),
                          // أيقونة جهات الاتصال
                          IconButton(
                            icon: const Icon(Icons.contacts_outlined),
                            color: ColorResources.primaryColor,
                            tooltip: 'phone_book'.tr,
                            onPressed: _pickContact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.star_outline_rounded),
                            color: ColorResources.primaryColor,
                            tooltip: 'favorite'.tr,
                            onPressed: () => _setCleanPhone('777123456'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (_verifiedRecipientName != null &&
                    _verifiedRecipientName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: ColorResources.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _verifiedRecipientName!,
                          style: rubikMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: ColorResources.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: Dimensions.paddingSizeLarge),

                // ==========================================
                // 3. حقل مبلغ (حدود سوداء) + تفقيط المبلغ تحته
                // ==========================================
                Text(
                  'amount'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSizeDefault),
                    // حقل المبلغ فقط هو الذي له حدود سوداء سميكة
                    border: Border.all(
                      width: 2,
                      color: Colors.black,
                    ),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) {
                      setState(() {});
                    },
                    style: rubikSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: isOverBalance
                          ? ColorResources.errorColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraLarge,
                        color: ColorResources.getGreyColor().withOpacity(0.5),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Text(
                          _selectedWallet?.currencySymbol ?? '﷼',
                          style: rubikBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: ColorResources.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // تفقيط المبلغ تحته مباشرة
                if (enteredAmount != null && enteredAmount > 0) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: ColorResources.primaryColor.withOpacity(0.06),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSizeSmall),
                    ),
                    child: Text(
                      TafqeetHelper.convert(
                        enteredAmount,
                        currencyCode: currentCurrency,
                      ),
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ColorResources.primaryColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],

                if (isOverBalance) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'insufficient_balance'.tr,
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ColorResources.errorColor,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text(
                  'notes'.tr,
                  style: rubikMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                TextField(
                  controller: _notesController,
                  minLines: 2,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'notes'.tr,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSizeDefault,
                      ),
                      borderSide: BorderSide(
                        color: ColorResources.getGreyColor().withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSizeDefault,
                      ),
                      borderSide: BorderSide(
                        color: ColorResources.getGreyColor().withOpacity(0.3),
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

                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                // ==========================================
                // 5. زر استمرار أخضر (ColorResources.primaryColor)
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
                    onPressed: _isLoadingRecipient || !canContinue ? null : _onContinuePressed,
                    child: _isLoadingRecipient
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'checking_recipient'.tr,
                                style: rubikMedium.copyWith(
                                  fontSize: Dimensions.fontSizeDefault,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'continue_button'.tr,
                            style: rubikMedium.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
