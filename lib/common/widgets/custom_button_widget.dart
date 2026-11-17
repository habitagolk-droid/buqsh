import 'package:flutter/material.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/common/widgets/custom_ink_well_widget.dart';

class CustomButtonWidget extends StatelessWidget {
  final Function? onTap;
  final String? buttonText;
  final Color? color;
  const CustomButtonWidget({
    Key? key,
    this.onTap,
    required this.buttonText,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        color: enabled ? buttonColor : Theme.of(context).disabledColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: buttonColor.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: CustomInkWellWidget(
        onTap: enabled ? onTap as void Function() : null,
        radius: Dimensions.radiusSizeDefault,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Center(
            child: Text(
              buttonText ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: buqshCtaTextStyle.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
