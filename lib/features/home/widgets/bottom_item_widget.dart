import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:six_cash/features/home/controllers/menu_controller.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class BottomItemWidget extends StatelessWidget {
  final String icon;
  final String name;
  final int? selectIndex;
  final VoidCallback? onTop;
  const BottomItemWidget({
    Key? key,
    required this.icon,
    required this.name,
    this.selectIndex,
    this.onTop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTop,
      borderRadius: BorderRadius.circular(12),
      child: GetBuilder<MenuItemController>(
        builder: (menuItemController) {
          final bool isSelected =
              menuItemController.currentTabIndex == selectIndex;
          final Color activeColor = Theme.of(context).primaryColor;
          final Color inactiveColor = ColorResources.nevDefaultColor;

          return SizedBox(
            width: double.infinity,
            height: 60,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Image.asset(
                      icon,
                      fit: BoxFit.contain,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 3.0),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      name,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: rubikSemiBold.copyWith(
                        color: isSelected ? activeColor : inactiveColor,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
