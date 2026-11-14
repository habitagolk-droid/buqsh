import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/camera_verification/screens/camera_screen.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/features/pos/controllers/pos_controller.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';

class CashierPosSaleScreen extends StatefulWidget {
  const CashierPosSaleScreen({Key? key}) : super(key: key);

  @override
  State<CashierPosSaleScreen> createState() => _CashierPosSaleScreenState();
}

class _CashierPosSaleScreenState extends State<CashierPosSaleScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _customerCodeController = TextEditingController();
  String _selectedCurrency = 'YER';
  final List<String> _currencies = ['YER', 'SAR', 'USD'];
  final List<double> _quickAmounts = [1000, 2000, 5000, 10000];

  @override
  void dispose() {
    _amountController.dispose();
    _customerCodeController.dispose();
    super.dispose();
  }

  Future<void> _scanCustomerQr() async {
    try {
      final result = await Get.to(
        () => const CameraScreen(
          fromEditProfile: false,
          isBarCodeScan: true,
          isHome: false,
        ),
      );
      if (result != null && result is String && result.trim().isNotEmpty) {
        setState(() {
          _customerCodeController.text = result.trim();
        });
        showCustomSnackBarHelper('تم قراءة كود العميل بنجاح', isError: false);
      }
    } catch (_) {
      showCustomSnackBarHelper('qr_code_scanner_not_working'.tr, isError: true);
    }
  }

  Future<void> _submitPayment() async {
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      showCustomSnackBarHelper('enter_valid_amount'.tr.isNotEmpty ? 'enter_valid_amount'.tr : 'يرجى إدخال مبلغ صحيح', isError: true);
      return;
    }

    final customerCode = _customerCodeController.text.trim();
    if (customerCode.isEmpty) {
      showCustomSnackBarHelper('يرجى مسح كود العميل QR أو إدخال رقمه', isError: true);
      return;
    }

    final cashierCtrl = Get.find<CashierAuthController>();
    final terminalNumber = cashierCtrl.sessionInfo?.terminalName ?? '';

    final posCtrl = Get.find<PosController>();
    if (posCtrl.terminal == null && terminalNumber.isNotEmpty) {
      await posCtrl.lookupTerminal(terminalNumber);
    }

    final success = await posCtrl.purchase(
      qrToken: customerCode,
      terminalNumber: terminalNumber.isNotEmpty ? terminalNumber : null,
      amount: amount,
      currencyCode: _selectedCurrency,
    );

    if (success) {
      if (posCtrl.lastResult != null) {
        Get.offNamed(RouteHelper.posReceipt, arguments: posCtrl.lastResult);
      } else {
        showCustomSnackBarHelper('تمت عملية البيع بنجاح', isError: false);
        Get.back();
      }
    } else {
      showCustomSnackBarHelper(posCtrl.errorMessage ?? 'فشلت عملية البيع. يرجى المحاولة مجدداً', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF004D40);
    const limeColor = Color(0xFFD4E157);
    const bgColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'إتمام عملية بيع جديدة (POS)',
          style: rubikMedium.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // بطاقة بيانات النقطة
            _buildTerminalHeader(primaryColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // بطاقة إدخال المبلغ
            _buildAmountCard(primaryColor, limeColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),

            // بطاقة مسح كود العميل
            _buildCustomerCard(primaryColor, limeColor),
            const SizedBox(height: Dimensions.paddingSizeExtraLarge),

            // زر تأكيد العملية
            _buildConfirmButton(primaryColor, limeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalHeader(Color primaryColor) {
    final cashierCtrl = Get.find<CashierAuthController>();
    final terminalName = cashierCtrl.sessionInfo?.terminalName ?? 'جهاز نقطة البيع';
    final merchantName = cashierCtrl.sessionInfo?.merchantName ?? 'بقش';
    final cashierName = cashierCtrl.sessionInfo?.cashierName ?? 'كاشير';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.point_of_sale_rounded, color: primaryColor, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  terminalName,
                  style: rubikBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: primaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '$merchantName • الكاشير: $cashierName',
                  style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(Color primaryColor, Color limeColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المبلغ المطلوب',
                style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black87),
              ),
              // اختيار العملة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCurrency,
                    items: _currencies.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(
                          c,
                          style: rubikBold.copyWith(color: primaryColor, fontSize: Dimensions.fontSizeSmall),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCurrency = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            textAlign: TextAlign.center,
            style: rubikBold.copyWith(fontSize: 32, color: primaryColor),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: rubikBold.copyWith(fontSize: 32, color: Colors.grey[300]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          // مبالغ سريعة
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amt) {
              return ActionChip(
                backgroundColor: primaryColor.withValues(alpha: 0.06),
                label: Text(
                  '+${amt.toInt()}',
                  style: rubikMedium.copyWith(color: primaryColor, fontSize: Dimensions.fontSizeSmall),
                ),
                onPressed: () {
                  final current = double.tryParse(_amountController.text.trim()) ?? 0;
                  final next = current + amt;
                  _amountController.text = next.toStringAsFixed(0);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Color primaryColor, Color limeColor) {
    final hasCode = _customerCodeController.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات العميل (رمز QR أو الكود)',
            style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customerCodeController,
                  decoration: InputDecoration(
                    hintText: 'امسح كود العميل أو أدخل رمزه',
                    hintStyle: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.person_outline_rounded, color: primaryColor),
                    suffixIcon: hasCode
                        ? const Icon(Icons.check_circle_rounded, color: Colors.green)
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _scanCustomerQr,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: limeColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: limeColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Color(0xFF004D40),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(Color primaryColor, Color limeColor) {
    return GetBuilder<PosController>(
      builder: (posCtrl) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: limeColor,
            foregroundColor: const Color(0xFF004D40),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
          ),
          onPressed: posCtrl.isLoading ? null : _submitPayment,
          child: posCtrl.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF004D40),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 24, color: Color(0xFF004D40)),
                    const SizedBox(width: 8),
                    Text(
                      'تأكيد واستلام الدفعة',
                      style: rubikBold.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: const Color(0xFF004D40),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
