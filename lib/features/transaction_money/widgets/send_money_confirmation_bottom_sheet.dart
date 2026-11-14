import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:six_cash/common/models/contact_model.dart';
import 'package:six_cash/common/widgets/custom_pin_code_field_widget.dart';
import 'package:six_cash/features/transaction_money/controllers/transaction_controller.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';
import 'package:six_cash/features/wallet/domain/models/wallet_model.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';
import 'package:six_cash/utils/tafqeet_helper.dart';

class SendMoneyConfirmationBottomSheet extends StatefulWidget {
  final WalletModel wallet;
  final String recipientPhone;
  final String recipientName;
  final String? recipientAvatar;
  final double amount;
  final String? purpose;

  const SendMoneyConfirmationBottomSheet({
    Key? key,
    required this.wallet,
    required this.recipientPhone,
    required this.recipientName,
    this.recipientAvatar,
    required this.amount,
    this.purpose,
  }) : super(key: key);

  @override
  State<SendMoneyConfirmationBottomSheet> createState() =>
      _SendMoneyConfirmationBottomSheetState();
}

class _SendMoneyConfirmationBottomSheetState
    extends State<SendMoneyConfirmationBottomSheet> {
  String _pin = '';
  bool _isExecuting = false;

  Future<void> _handleExecute() async {
    if (_pin.length < 4) {
      showCustomSnackBarHelper('pin_must_be_4_digits'.tr, isError: true);
      return;
    }

    setState(() {
      _isExecuting = true;
    });

    try {
      final txController = Get.find<TransactionMoneyController>();
      final idempotencyKey = const Uuid().v4();

      final contact = ContactModel(
        phoneNumber: widget.recipientPhone,
        name: widget.recipientName,
        avatarImage: widget.recipientAvatar,
      );

      final response = await txController.sendMoney(
        contactModel: contact,
        amount: widget.amount,
        purpose: widget.purpose ?? 'Transfer',
        pinCode: _pin,
        currencyCode: widget.wallet.currencyCode,
        idempotencyKey: idempotencyKey,
        onSuggest: () {},
      );

      if (response.statusCode == 200) {
        // تحديث الأرصدة بعد نجاح العملية مباشرة كما تنص القواعد
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().getWallets(reload: true);
        }

        if (mounted) {
          Navigator.of(context).pop(true);
        }

        showCustomSnackBarHelper(
          'send_money_successful'.tr,
          isError: false,
        );

        // الرجوع للرئيسية
        Get.offAllNamed(RouteHelper.getNavBarRoute());
      } else {
        String message = 'error'.tr;
        final body = response.body;
        if (body is Map && body['message'] != null) {
          message = body['message'].toString();
        } else if (response.statusText != null &&
            response.statusText!.isNotEmpty) {
          message = response.statusText!;
        }
        showCustomSnackBarHelper(message, isError: true);
      }
    } catch (e) {
      showCustomSnackBarHelper('error'.tr, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isExecuting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusSizeExtraLarge),
          topRight: Radius.circular(Dimensions.radiusSizeExtraLarge),
        ),
      ),
      padding: EdgeInsets.only(
        top: Dimensions.paddingSizeDefault,
        left: Dimensions.paddingSizeDefault,
        right: Dimensions.paddingSizeDefault,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            Dimensions.paddingSizeDefault,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- شريط العنوان وزر الإغلاق (X) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'confirm_transfer'.tr,
                  style: rubikSemiBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: ColorResources.getGreyColor(),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // --- 1. صندوق المبلغ ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: ColorResources.primaryColor.withOpacity(0.06),
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusSizeDefault),
                border: Border.all(
                  color: ColorResources.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'transfer_amount'.tr,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ColorResources.getGreyColor(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(
                      widget.amount,
                      currency: widget.wallet.currencyCode,
                    ),
                    style: rubikSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeOverLarge,
                      color: ColorResources.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // التفقيط
                  Text(
                    TafqeetHelper.convert(
                      widget.amount,
                      currencyCode: widget.wallet.currencyCode,
                    ),
                    textAlign: TextAlign.center,
                    style: rubikRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: ColorResources.getGreyColor(),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${'from_wallet'.tr}: ',
                        style: rubikRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: ColorResources.getGreyColor(),
                        ),
                      ),
                      Text(
                        '${widget.wallet.currencyCode} (${widget.wallet.currencyName})',
                        style: rubikMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // --- 2. صندوق المستلم (حدود سوداء) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusSizeDefault),
                border: Border.all(
                  width: 2,
                  color: Colors.black,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorResources.primaryColor.withOpacity(0.12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: ColorResources.primaryColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'recipient_info'.tr,
                          style: rubikRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: ColorResources.getGreyColor(),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.recipientName.isNotEmpty
                              ? widget.recipientName
                              : widget.recipientPhone,
                          style: rubikSemiBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            widget.recipientPhone,
                            style: rubikRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: ColorResources.getGreyColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.verified,
                    color: ColorResources.primaryColor,
                    size: 22,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // --- 3. تحذير بلون errorColor ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: ColorResources.errorColor.withOpacity(0.08),
                borderRadius:
                    BorderRadius.circular(Dimensions.radiusSizeSmall),
                border: Border.all(
                  color: ColorResources.errorColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: ColorResources.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'transfer_warning'.tr,
                      style: rubikRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: ColorResources.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.paddingSizeDefault),

            // --- 4. طلب رمز PIN ---
            Text(
              'enter_pin_to_confirm'.tr,
              style: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            CustomPinCodeFieldWidget(
              padding: 0,
              onCompleted: (pin) {
                setState(() {
                  _pin = pin;
                });
              },
            ),

            const SizedBox(height: Dimensions.paddingSizeLarge),

            // --- 5. الأزرار (إلغاء أبيض، تنفيذ أخضر) ---
            Row(
              children: [
                // زر إلغاء أبيض
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: ColorResources.getGreyColor().withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusSizeDefault,
                          ),
                        ),
                      ),
                      onPressed: _isExecuting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: Text(
                        'cancel'.tr,
                        style: rubikMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                // زر تنفيذ أخضر
                Expanded(
                  child: SizedBox(
                    height: 50,
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
                      onPressed: _isExecuting ? null : _handleExecute,
                      child: _isExecuting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'execute_transfer'.tr,
                              style: rubikMedium.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: Colors.white,
                              ),
                            ),
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
