import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:six_cash/common/controllers/share_controller.dart';
import 'package:six_cash/core/theme/buqsh_design.dart';
import 'package:six_cash/features/splash/controllers/splash_controller.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/common/widgets/custom_logo_widget.dart';

class QrCodeDownloadOrShareScreen extends StatelessWidget {
  final String qrCode;
  final String phoneNumber;

  const QrCodeDownloadOrShareScreen({Key? key, required this.qrCode, required this.phoneNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Screenshot(
        controller: Get.find<ShareController>().statementController,
        child: Scaffold(
          backgroundColor: BqColors.bg,
          body: Center(
            child: Container(
              height: size.height,
              width: size.width,
              margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: const BoxDecoration(
                color: BqColors.surface,
                borderRadius: BorderRadius.all(Radius.circular(BqRadius.sheet)),
                boxShadow: BqShadows.card,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CustomLogoWidget(height: 70, width: 70),
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        Text(
                          Get.find<SplashController>().configModel!.companyName!,
                          style: rubikMedium.copyWith(color: BqColors.brand, fontSize: Dimensions.fontSizeOverOverLarge),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: BqColors.input, borderRadius: BorderRadius.circular(BqRadius.card)),
                      child: SvgPicture.string(qrCode, height: size.width * .54, width: size.width * .54),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeOverLarge),
                    Text(phoneNumber, style: rubikRegular.copyWith(color: BqColors.ink, fontSize: Dimensions.fontSizeExtraOverLarge), textAlign: TextAlign.center),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    const Divider(color: BqColors.line, indent: 70, endIndent: 70),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Text('scan_the_QR_code_to_send_money'.tr, style: rubikSemiBold.copyWith(color: BqColors.ink, fontSize: Dimensions.fontSizeExtraLarge), textAlign: TextAlign.center),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    Container(height: 8, width: double.infinity, decoration: const BoxDecoration(gradient: BqGradients.proHeader, borderRadius: BorderRadius.vertical(bottom: Radius.circular(BqRadius.sheet)))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
