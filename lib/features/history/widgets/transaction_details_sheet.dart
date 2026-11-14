import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:six_cash/features/history/domain/models/transaction_model.dart';
import 'package:six_cash/features/history/utils/transaction_formatting.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/util/app_constants.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/receipt_image_actions.dart';

class TransactionDetailsSheet extends StatefulWidget {
  final Transactions? transaction;

  const TransactionDetailsSheet({Key? key, required this.transaction})
      : super(key: key);

  @override
  State<TransactionDetailsSheet> createState() =>
      _TransactionDetailsSheetState();
}

class _TransactionDetailsSheetState extends State<TransactionDetailsSheet> {
  final ScreenshotController _receiptScreenshotController =
      ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    if (transaction == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Dimensions.radiusSizeExtraLarge),
          ),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Center(
          child: Text('no_data_found'.tr, style: rubikRegular),
        ),
      );
    }

    final item = transaction;
    final bool isCredit = (item.credit ?? 0) > 0;

    String? senderText;
    String? receiverText;

    final type = item.transactionType ?? '';
    if (type == AppConstants.sendMoney) {
      receiverText = item.receiver?.name?.isNotEmpty == true
          ? item.receiver?.name
          : item.receiver?.phone;
      senderText = item.sender?.name?.isNotEmpty == true
          ? item.sender?.name
          : item.sender?.phone;
    } else if (type == AppConstants.receivedMoney) {
      senderText = item.sender?.name?.isNotEmpty == true
          ? item.sender?.name
          : item.sender?.phone;
      receiverText = item.receiver?.name?.isNotEmpty == true
          ? item.receiver?.name
          : item.receiver?.phone;
    } else if (type == AppConstants.addMoney || type == 'add_money_bonus') {
      senderText = item.sender?.name?.isNotEmpty == true
          ? item.sender?.name
          : item.sender?.phone;
    } else if (type == AppConstants.cashIn) {
      senderText = item.sender?.name?.isNotEmpty == true
          ? item.sender?.name
          : item.sender?.phone;
    } else if (type == AppConstants.withdraw) {
      receiverText = item.receiver?.name?.isNotEmpty == true
          ? item.receiver?.name
          : item.receiver?.phone;
    } else if (item.userInfo != null) {
      final user = item.userInfo;
      if ((user?.name ?? '').isNotEmpty) {
        if (isCredit) {
          senderText = user?.name;
        } else {
          receiverText = user?.name;
        }
      }
    }

    senderText = senderText == null
        ? null
        : formatTransactionPhone(senderText);
    receiverText = receiverText == null
        ? null
        : formatTransactionPhone(receiverText);
    final formattedDate = formatTransactionDate(item.createdAt);

    final refNumber = (item.referenceNumber?.isNotEmpty == true)
        ? item.referenceNumber
        : item.transactionId;

    final double commissionVal = item.commission ?? 0.0;
    final String? commissionText = commissionVal > 0
        ? '${commissionVal.toStringAsFixed(2)} ${item.displayCurrencySymbol}'
        : null;
    final textToShare = [
      'transaction_details'.tr,
      if (refNumber != null && refNumber.isNotEmpty)
        '${'reference_number'.tr}: $refNumber',
      '${'transaction_type'.tr}: ${getTransactionTitle(item.transactionType)}',
      '${'amount'.tr}: ${item.formatAmount()}',
      if (formattedDate.isNotEmpty) '${'date'.tr}: $formattedDate',
      if (receiverText != null && receiverText.isNotEmpty)
        '${'beneficiary'.tr}: $receiverText',
      if (senderText != null && senderText.isNotEmpty)
        '${'depositor'.tr}: $senderText',
    ].join('\n');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusSizeExtraLarge),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeLarge,
            vertical: Dimensions.paddingSizeDefault,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // مقبض السحب العلوي
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin:
                      const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: ColorResources.getGreyColor().withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // شريط العنوان وزر الإغلاق
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'transaction_details'.tr,
                    style: rubikSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusSizeDefault),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: ColorResources.getGreyColor(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.paddingSizeDefault),

              Screenshot(
                controller: _receiptScreenshotController,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // صندوق المبلغ
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeDefault,
                  horizontal: Dimensions.paddingSizeLarge,
                ),
                decoration: BoxDecoration(
                  color: (isCredit ? Colors.green : ColorResources.primaryColor)
                      .withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(Dimensions.radiusSizeDefault),
                ),
                child: Column(
                  children: [
                    Text(
                      '${isCredit ? '+' : '-'} ${item.formatAmount()}',
                      style: rubikSemiBold.copyWith(
                        fontSize: 26,
                        color: isCredit ? Colors.green : Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeDefault),

              // ==========================================
              // صفوف التفاصيل (أخفِ أي حقل قيمته null أو فارغة)
              // ==========================================

              // 1. رقم المرجع + زر نسخ
              if (refNumber != null && refNumber.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'reference_number'.tr,
                        style: rubikRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: ColorResources.getGreyColor(),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            refNumber,
                            style: rubikMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: refNumber));
                              showCustomSnackBarHelper(
                                'copied'.tr,
                                isError: false,
                              );
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.copy_rounded,
                                size: 16,
                                color: ColorResources.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 16,
                  color: ColorResources.getGreyColor().withOpacity(0.15),
                ),
              ],

              // 2. العملية
              if (item.transactionType?.isNotEmpty == true) ...[
                _DetailRow(
                  label: 'transaction_type'.tr,
                  value: getTransactionTitle(item.transactionType),
                ),
                Divider(
                  height: 16,
                  color: ColorResources.getGreyColor().withOpacity(0.15),
                ),
              ],

              // 3. التاريخ
              if (formattedDate.isNotEmpty) ...[
                _DetailRow(
                  label: 'date'.tr,
                  value: formattedDate,
                ),
                Divider(
                  height: 16,
                  color: ColorResources.getGreyColor().withOpacity(0.15),
                ),
              ],

              // 4. المستفيد
              if (receiverText != null && receiverText.isNotEmpty) ...[
                _DetailRow(
                  label: 'beneficiary'.tr,
                  value: receiverText,
                ),
                Divider(
                  height: 16,
                  color: ColorResources.getGreyColor().withOpacity(0.15),
                ),
              ],

              // 5. المودع
              if (senderText != null && senderText.isNotEmpty) ...[
                _DetailRow(
                  label: 'depositor'.tr,
                  value: senderText,
                ),
                Divider(
                  height: 16,
                  color: ColorResources.getGreyColor().withOpacity(0.15),
                ),
              ],

              // 6. العمولة
              if (commissionText != null && commissionText.isNotEmpty) ...[
                _DetailRow(
                  label: 'commission'.tr,
                  value: commissionText,
                ),
                Divider(
                  height: 16,
                  color: ColorResources.getGreyColor().withOpacity(0.15),
                ),
              ],
                  ],
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              // ==========================================
              // زري "تنزيل الإيصال" و "مشاركة" بخلفية primaryColor
              // ==========================================
              Row(
                children: [
                  // زر تنزيل الإيصال
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorResources.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSizeDefault,
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => ReceiptImageActions.saveToGallery(
                          _receiptScreenshotController,
                        ),
                        icon: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'download_receipt'.tr,
                          style: buttonTextStyle.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  // زر مشاركة
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorResources.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              Dimensions.radiusSizeDefault,
                            ),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => ReceiptImageActions.share(
                          _receiptScreenshotController,
                          text: textToShare,
                        ),
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'share'.tr,
                          style: buttonTextStyle.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: rubikRegular.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: ColorResources.getGreyColor(),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Flexible(
            child: Text(
              value,
              style: rubikMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
