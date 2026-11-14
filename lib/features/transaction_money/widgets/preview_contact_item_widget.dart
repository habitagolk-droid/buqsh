import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/common/models/contact_model.dart';
import 'package:six_cash/util/color_resources.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class PreviewContactItemWidget extends StatelessWidget {
  final ContactModel? contactModel;
  const PreviewContactItemWidget({Key? key, required this.contactModel,}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final contact = contactModel;
    final phoneNumber = (contact?.phoneNumber ?? '').replaceAll('-', '');
    final name = contact?.name?.trim();
    final displayName =
        name?.isNotEmpty == true ? name : (phoneNumber.isNotEmpty ? phoneNumber : 'no_user'.tr);

    return ListTile(
      title: Text(
        displayName ?? 'no_user'.tr,
        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
      ),
      subtitle: phoneNumber.isEmpty
          ? const SizedBox()
          : Text(
              phoneNumber,
              style: rubikLight.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: ColorResources.getGreyBaseGray1(),
              ),
            ),
    );
  }
}


