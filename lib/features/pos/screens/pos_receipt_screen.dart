import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';
import 'package:six_cash/features/pos/models/pos_purchase_result.dart';
import 'package:six_cash/helper/date_converter_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/receipt_image_actions.dart';

class PosReceiptScreen extends StatefulWidget {
  final PosPurchaseResult result;

  const PosReceiptScreen({Key? key, required this.result}) : super(key: key);

  @override
  State<PosReceiptScreen> createState() => _PosReceiptScreenState();
}

class _PosReceiptScreenState extends State<PosReceiptScreen> {
  final ScreenshotController _receiptScreenshotController =
      ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final currency = result.currencyCode;
    final formattedDate = DateConverterHelper.localDateToIsoStringAMPM(
      result.paidAt,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Get.offAllNamed(RouteHelper.navbar);
      },
      child: Scaffold(
        appBar: CustomAppbarWidget(
          title: 'pos_receipt_title'.tr,
          onTap: () => Get.offAllNamed(RouteHelper.navbar),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            children: [
              const SizedBox(height: Dimensions.paddingSizeLarge),

              // أيقونة النجاح
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 48,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeDefault),

              Text(
                'pos_payment_success'.tr,
                style: rubikSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall),

              Text(
                '${result.amount.toStringAsFixed(2)} $currency',
                style: rubikSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraOverLarge,
                  color: Theme.of(context).primaryColor,
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // بطاقة تفاصيل الإيصال
              Screenshot(
                controller: _receiptScreenshotController,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(
                      Dimensions.radiusSizeDefault,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ReceiptRow(
                        label: 'receipt_number'.tr,
                        value: result.receiptNumber,
                      ),
                      _buildDivider(),
                      _ReceiptRow(
                        label: 'merchant_name'.tr,
                        value: result.merchantName,
                      ),
                      if (result.terminalName.isNotEmpty) ...[
                        _buildDivider(),
                        _ReceiptRow(
                          label: 'terminal_name'.tr,
                          value: result.terminalName,
                        ),
                      ],
                      _buildDivider(),
                      _ReceiptRow(
                        label: 'amount'.tr,
                        value: '${result.amount.toStringAsFixed(2)} $currency',
                      ),
                      if (result.commission > 0) ...[
                        _buildDivider(),
                        _ReceiptRow(
                          label: 'commission'.tr,
                          value:
                              '${result.commission.toStringAsFixed(2)} $currency',
                        ),
                      ],
                      _buildDivider(),
                      _ReceiptRow(
                        label: 'net_amount'.tr,
                        value:
                            '${result.netAmount.toStringAsFixed(2)} $currency',
                        isBold: true,
                      ),
                      _buildDivider(),
                      _ReceiptRow(
                        label: 'payment_status'.tr,
                        value: 'completed'.tr,
                        valueColor: Colors.green,
                      ),
                      _buildDivider(),
                      _ReceiptRow(label: 'date'.tr, value: formattedDate),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeDefault),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ReceiptImageActions.saveToGallery(
                        _receiptScreenshotController,
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: Text(
                        'download_receipt'.tr,
                        style: buttonTextStyle.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => ReceiptImageActions.share(
                        _receiptScreenshotController,
                        text: 'pos_receipt_title'.tr,
                      ),
                      icon: const Icon(Icons.share_rounded),
                      label: Text(
                        'share'.tr,
                        style: buttonTextStyle.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.paddingSizeExtraLarge),

              // زر العودة للرئيسية
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        Dimensions.radiusSizeDefault,
                      ),
                    ),
                  ),
                  onPressed: () => Get.offAllNamed(RouteHelper.navbar),
                  child: Text(
                    'back_to_home'.tr,
                    style: rubikMedium.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 20,
      color: ColorResources.getGreyColor().withOpacity(0.15),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
            style: (isBold ? rubikSemiBold : rubikMedium).copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
