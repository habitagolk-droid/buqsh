import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/util/app_constants.dart';

class ReceiptImageActions {
  const ReceiptImageActions._();

  static Future<void> saveToGallery(ScreenshotController controller) async {
    try {
      final image = await controller.capture();
      if (image == null) {
        throw StateError('Receipt screenshot capture returned no image.');
      }

      final directory = await getTemporaryDirectory();
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(image, flush: true);

      final result = await ImageGallerySaverPlus.saveFile(
        file.path,
        name: AppConstants.appName,
      );
      if (result is Map && result['isSuccess'] == false) {
        throw StateError('The gallery rejected the receipt image.');
      }

      showCustomSnackBarHelper(
        'receipt_downloaded_successfully'.tr,
        isError: false,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Receipt save failed: $error\n$stackTrace');
      showCustomSnackBarHelper('receipt_save_failed'.tr, isError: true);
    }
  }

  static Future<void> share(
    ScreenshotController controller, {
    String? text,
  }) async {
    try {
      final image = await controller.capture();
      if (image == null) {
        throw StateError('Receipt screenshot capture returned no image.');
      }

      final directory = await getTemporaryDirectory();
      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(image, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: text,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('Receipt share failed: $error\n$stackTrace');
      showCustomSnackBarHelper('receipt_share_failed'.tr, isError: true);
    }
  }
}
