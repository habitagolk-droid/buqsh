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
import 'package:six_cash/util/images.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/receipt_image_actions.dart';
import 'package:six_cash/utils/tafqeet_helper.dart';

const Color _jaibPrimary = Color(0xFF0C4A40);
const Color _jaibSecondary = Color(0xFF278D5B);
const Color _jaibPrimaryDark = Color(0xFF08332D);
const Color _jaibLime = Color(0xFFD4E157);
const Color _jaibBackground = Color(0xFFF4F5F7);

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
  bool _isFavorite = false;

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    if (transaction == null) {
      return _sheetCard(
        context,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Center(
            child: Text('no_data_found'.tr, style: rubikRegular),
          ),
        ),
      );
    }

    final item = transaction;
    final bool isCredit = (item.credit ?? 0) > 0;
    final details = _buildTransactionDetails(item, isCredit);
    final formattedDate = formatTransactionDate(item.createdAt);
    final refNumber = (item.referenceNumber?.isNotEmpty == true)
        ? item.referenceNumber!
        : (item.transactionId ?? '');
    final commissionVal = item.commission ?? 0.0;
    final commissionText = commissionVal > 0
        ? '${commissionVal.toStringAsFixed(2)} ${item.displayCurrencySymbol}'
        : '';
    final textToShare = _buildShareText(
      item: item,
      refNumber: refNumber,
      formattedDate: formattedDate,
      details: details,
    );

    return _sheetCard(
      context,
      child: Directionality(
        textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeSmall,
            Dimensions.paddingSizeLarge,
            Dimensions.paddingSizeDefault,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(onClose: () => Navigator.pop(context)),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Screenshot(
                controller: _receiptScreenshotController,
                child: _ReceiptContent(
                  item: item,
                  isCredit: isCredit,
                  refNumber: refNumber,
                  formattedDate: formattedDate,
                  commissionText: commissionText,
                  details: details,
                  isArabic: _isArabic,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              _ActionsRow(
                isFavorite: _isFavorite,
                onSave: () => ReceiptImageActions.saveToGallery(
                  _receiptScreenshotController,
                ),
                onShare: () => ReceiptImageActions.share(
                  _receiptScreenshotController,
                  text: textToShare,
                ),
                onFavorite: _toggleFavorite,
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _jaibPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تم', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetCard(BuildContext context, {required Widget child}) {
    final maxHeight = MediaQuery.of(context).size.height * 0.91;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusSizeExtraLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(top: false, child: child),
    );
  }

  Map<String, String> _buildTransactionDetails(
    Transactions item,
    bool isCredit,
  ) {
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

    return {
      'receiver': receiverText == null ? '' : formatTransactionPhone(receiverText),
      'sender': senderText == null ? '' : formatTransactionPhone(senderText),
    };
  }

  String _buildShareText({
    required Transactions item,
    required String refNumber,
    required String formattedDate,
    required Map<String, String> details,
  }) {
    return [
      'transaction_receipt'.tr,
      if (refNumber.isNotEmpty) '${'reference_number'.tr}: $refNumber',
      '${'transaction_type'.tr}: ${getTransactionTitle(item.transactionType)}',
      '${'amount'.tr}: ${item.formatAmount()}',
      if (formattedDate.isNotEmpty) '${'date'.tr}: $formattedDate',
      if (details['receiver']!.isNotEmpty)
        '${'beneficiary'.tr}: ${details['receiver']}',
      if (details['sender']!.isNotEmpty)
        '${'depositor'.tr}: ${details['sender']}',
    ].join('\n');
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    showCustomSnackBarHelper(
      (_isFavorite ? 'favorite_added' : 'favorite_removed').tr,
      isError: false,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VoidCallback onClose;

  const _SheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            'transaction_receipt'.tr,
            style: rubikSemiBold.copyWith(
              color: ColorResources.getTextColor(),
              fontSize: Dimensions.fontSizeLarge,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onClose,
              tooltip: 'close'.tr,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: Icon(
                Icons.close_rounded,
                color: ColorResources.getTextColor(),
                size: 29,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  final Transactions item;
  final bool isCredit;
  final String refNumber;
  final String formattedDate;
  final String commissionText;
  final Map<String, String> details;
  final bool isArabic;

  const _ReceiptContent({
    required this.item,
    required this.isCredit,
    required this.refNumber,
    required this.formattedDate,
    required this.commissionText,
    required this.details,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (item.amount ?? 0) > 0
        ? item.amount!
        : ((item.debit ?? 0) > 0 ? item.debit! : (item.credit ?? 0));
    final rows = <Widget>[];
    if (refNumber.isNotEmpty) {
      rows.add(
        _ReferenceRow(
          value: refNumber,
          isArabic: isArabic,
        ),
      );
    }
    if ((item.transactionType ?? '').isNotEmpty) {
      rows.add(
        _DetailRow(
          label: 'transaction_type'.tr,
          value: getTransactionTitle(item.transactionType),
          isArabic: isArabic,
        ),
      );
    }
    if (formattedDate.isNotEmpty) {
      rows.add(
        _DetailRow(
          label: 'date'.tr,
          value: formattedDate,
          isArabic: isArabic,
        ),
      );
    }
    if (details['receiver']!.isNotEmpty) {
      rows.add(
        _DetailRow(
          label: 'beneficiary'.tr,
          value: details['receiver']!,
          isArabic: isArabic,
        ),
      );
    }
    if (details['sender']!.isNotEmpty) {
      rows.add(
        _DetailRow(
          label: 'depositor'.tr,
          value: details['sender']!,
          isArabic: isArabic,
        ),
      );
    }
    if (commissionText.isNotEmpty) {
      rows.add(
        _DetailRow(
          label: 'commission'.tr,
          value: commissionText,
          isArabic: isArabic,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrandLockup(),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text(
          'transaction_details'.tr,
          style: rubikBold.copyWith(
            fontSize: Dimensions.fontSizeExtraLarge,
            color: _jaibPrimary,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_jaibSecondary, _jaibPrimaryDark]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x470C4A40), blurRadius: 12, offset: Offset(0, 5))],
          ),
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                text: TextSpan(
                  style: rubikMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                  children: [
                    TextSpan(
                      text: item.formatAmount().replaceFirst(
                        ' ${item.displayCurrencySymbol}',
                        '',
                      ),
                      style: rubikBold.copyWith(
                        color: Colors.white,
                        fontSize: Dimensions.fontSizeOverLarge,
                      ),
                    ),
                    if (item.displayCurrencySymbol.isNotEmpty)
                      TextSpan(
                        text: ' ${item.displayCurrencySymbol}',
                        style: rubikMedium.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                  ],
                ),
              ),
              if (amount >= 1 && amount <= 999999)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    TafqeetHelper.convert(
                      amount,
                      currencyCode: item.displayCurrencyCode,
                    ),
                    textAlign: TextAlign.center,
                    style: rubikMedium.copyWith(
                      color: _jaibLime,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ..._withDividers(rows),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> rows) {
    final children = <Widget>[];
    for (var index = 0; index < rows.length; index++) {
      children.add(rows[index]);
      if (index < rows.length - 1) {
        children.add(
          Divider(
            height: 1,
            color: ColorResources.getGreyColor().withOpacity(0.18),
          ),
        );
      }
    }
    return children;
  }
}

class _BrandLockup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        Image.asset(Images.logo, width: 57, height: 57),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Text(
          'بُقْش',
          style: rubikBold.copyWith(
            color: _jaibPrimary,
            fontSize: 29,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  final String value;
  final bool isArabic;

  const _ReferenceRow({required this.value, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'reference_number'.tr,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: rubikMedium.copyWith(
                color: ColorResources.getGreyBaseGray1(),
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                Flexible(
                  child: Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: rubikSemiBold.copyWith(
                      color: ColorResources.getTextColor(),
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    showCustomSnackBarHelper('copied'.tr, isError: false);
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.copy_rounded,
                      size: 19,
                      color: _jaibPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isArabic;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: rubikMedium.copyWith(
                color: ColorResources.getGreyBaseGray1(),
                fontSize: Dimensions.fontSizeDefault,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            flex: 6,
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: isArabic ? TextAlign.left : TextAlign.right,
              style: rubikSemiBold.copyWith(
                color: ColorResources.getTextColor(),
                fontSize: Dimensions.fontSizeDefault,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  const _ActionsRow({
    required this.isFavorite,
    required this.onSave,
    required this.onShare,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: _ReceiptAction(
            icon: Icons.save_alt_rounded,
            label: 'save_receipt'.tr,
            onPressed: onSave,
          ),
        ),
        Expanded(
          child: _ReceiptAction(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            label: isFavorite ? 'remove_from_favorites'.tr : 'add_to_favorites'.tr,
            iconColor: isFavorite ? ColorResources.errorColor : null,
            onPressed: onFavorite,
          ),
        ),
        Expanded(
          child: _ReceiptAction(
            icon: Icons.share_rounded,
            label: 'share'.tr,
            iconColor: _jaibPrimary,
            onPressed: onShare,
          ),
        ),
      ],
    );
  }
}

class _ReceiptAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? iconColor;

  const _ReceiptAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FA),
                borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
              ),
              child: Icon(
                icon,
                color: iconColor ?? _jaibPrimary,
                size: 30,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: rubikSemiBold.copyWith(
                color: ColorResources.getTextColor(),
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
