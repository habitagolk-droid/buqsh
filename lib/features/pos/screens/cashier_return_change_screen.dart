import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/utils/currency_formatter.dart';

class CashierReturnChangeScreen extends StatefulWidget {
  const CashierReturnChangeScreen({super.key});

  @override
  State<CashierReturnChangeScreen> createState() =>
      _CashierReturnChangeScreenState();
}

class _CashierReturnChangeScreenState extends State<CashierReturnChangeScreen> {
  static const _primary = Color(0xFF086048);
  final _receiptController = TextEditingController();
  final _totalController = TextEditingController();
  final _paidController = TextEditingController();
  bool _isSubmitting = false;

  double? get _change {
    final total = double.tryParse(_totalController.text.trim());
    final paid = double.tryParse(_paidController.text.trim());
    if (total == null || paid == null || total <= 0 || paid < total) return null;
    return paid - total;
  }

  @override
  void dispose() {
    _receiptController.dispose();
    _totalController.dispose();
    _paidController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final receipt = _receiptController.text.trim();
    final total = double.tryParse(_totalController.text.trim());
    final paid = double.tryParse(_paidController.text.trim());
    final change = _change;
    if (receipt.isEmpty || total == null || paid == null || change == null || change <= 0) {
      showCustomSnackBarHelper('cashier_invalid_change_amount'.tr, isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('cashier_change_title'.tr, style: rubikBold),
        content: Text(
          '${'receipt_number'.tr}: $receipt\n${'cashier_change_result'.tr}: ${CurrencyFormatter.format(change, currency: 'YER')}\n\n${'authenticate_to_confirm_transaction'.tr}',
          style: rubikRegular,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('execute_transaction'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final authenticated = await LocalAuthentication().authenticate(
        localizedReason: 'authenticate_to_confirm_transaction'.tr,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!authenticated) {
        showCustomSnackBarHelper(
          'transaction_authentication_cancelled'.tr,
          isError: true,
        );
        return;
      }

      // لا يُرسل أي طلب قبل تأكيد المستخدم ونجاح التحقق المحلي.
      final response = await Get.find<CashierAuthController>().authRepo.submitRefund(
        receiptNumber: receipt,
        amount: change,
        reason: 'إرجاع الباقي للعميل',
      );
      final succeeded = response.statusCode != null &&
          response.statusCode! >= 200 && response.statusCode! < 300;
      final body = response.body;
      final serverMessage = body is Map
          ? (body['message'] ?? body['error'])?.toString()
          : null;
      showCustomSnackBarHelper(
        serverMessage?.isNotEmpty == true
            ? serverMessage!
            : succeeded
                ? 'cashier_refund_success'.tr
                : 'cashier_refund_failed'.tr,
        isError: !succeeded,
      );
      if (succeeded && mounted) Get.back();
    } catch (_) {
      showCustomSnackBarHelper('cashier_refund_unavailable'.tr, isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final change = _change;
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAF5),
      appBar: AppBar(
        title: Text('cashier_change_title'.tr, style: rubikBold),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('cashier_change_result'.tr,
                    style: rubikRegular.copyWith(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  CurrencyFormatter.format(change ?? 0, currency: 'YER'),
                  style: rubikBold.copyWith(color: Colors.white, fontSize: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _receiptController,
            decoration: _decoration('receipt_number'.tr, Icons.receipt_long_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _totalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: _decoration('cashier_total_amount'.tr, Icons.shopping_bag_outlined),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _paidController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: _decoration('cashier_paid_amount'.tr, Icons.payments_outlined),
          ),
          if (_totalController.text.isNotEmpty &&
              _paidController.text.isNotEmpty &&
              change == null) ...[
            const SizedBox(height: 10),
            Text(
              'cashier_invalid_change_amount'.tr,
              style: rubikRegular.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.fingerprint_rounded),
              label: Text('execute_transaction'.tr),
            ),
          ),
        ],
      ),
    );
  }
}
