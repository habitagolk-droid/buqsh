import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/widgets/custom_ink_well_widget.dart';
import 'package:six_cash/common/widgets/rounded_button_widget.dart';
import 'package:six_cash/core/theme/buqsh_design.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class CustomAppbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Function? onTap;
  final bool isSkip;
  final Function? function;
  final bool onlyTitle;

  const CustomAppbarWidget({
    Key? key,
    required this.title,
    this.onTap,
    this.isSkip = false,
    this.function,
    this.onlyTitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final decoration = const BoxDecoration(
      gradient: BqGradients.header,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
    );
    if (onlyTitle) {
      return Container(
        decoration: decoration,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(title, style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Colors.white)),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
        ),
      );
    }
    return Container(
      decoration: decoration,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomInkWellWidget(
                onTap: onTap == null ? () => Get.back() : () => onTap!(),
                radius: Dimensions.radiusSizeSmall,
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.7), width: 0.5),
                    borderRadius: BorderRadius.circular(Dimensions.radiusSizeSmall),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: Dimensions.paddingSizeSmall, color: Colors.white),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(child: Text(title, textAlign: TextAlign.center, style: rubikMedium.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: Colors.white))),
              if (isSkip) ...[
                const SizedBox(width: Dimensions.paddingSizeDefault),
                SizedBox(child: RoundedButtonWidget(buttonText: 'skip'.tr, onTap: function, isSkip: true)),
              ] else
                const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size(double.maxFinite, 70);
}
