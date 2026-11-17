import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/add_money/controllers/add_money_controller.dart';
import 'package:six_cash/features/setting/controllers/profile_screen_controller.dart';
import 'package:six_cash/features/splash/controllers/splash_controller.dart';
import 'package:six_cash/features/transaction_money/controllers/contact_controller.dart';
import 'package:six_cash/features/transaction_money/controllers/transaction_controller.dart';
import 'package:six_cash/features/transaction_money/domain/models/purpose_model.dart';
import 'package:six_cash/common/models/contact_model.dart';
import 'package:six_cash/features/transaction_money/domain/models/withdraw_model.dart';
import 'package:six_cash/helper/email_checker_helper.dart';
import 'package:six_cash/helper/price_converter_helper.dart';
import 'package:six_cash/helper/transaction_type.dart';
import 'package:six_cash/util/dimensions.dart';
import 'package:six_cash/util/styles.dart';
import 'package:six_cash/common/widgets/custom_app_bar_widget.dart';
import 'package:six_cash/common/widgets/custom_loader_widget.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/features/add_money/widgets/digital_payment_widget.dart';
import 'package:six_cash/features/transaction_money/screens/transaction_confirmation_screen.dart';
import 'package:six_cash/features/transaction_money/widgets/input_box_widget.dart';
import 'package:six_cash/features/transaction_money/widgets/purpose_widget.dart';
import 'package:six_cash/features/transaction_money/screens/transaction_money_screen.dart';
import '../widgets/field_item_widget.dart';
import '../widgets/for_person_widget.dart';

class TransactionBalanceInputScreen extends StatefulWidget {
  final String? transactionType;
  final ContactModel? contactModel;
  final String? countryCode;
   const TransactionBalanceInputScreen({Key? key, this.transactionType ,this.contactModel, this.countryCode}) : super(key: key);
  @override
  State<TransactionBalanceInputScreen> createState() => _TransactionBalanceInputScreenState();
}

class _TransactionBalanceInputScreenState extends State<TransactionBalanceInputScreen> {
  final TextEditingController _inputAmountController = TextEditingController();
  String? _selectedMethodId;
  List<MethodField>? _fieldList;
  List<MethodField>? _gridFieldList;
  Map<String?, TextEditingController> _textControllers =  {};
  Map<String?, TextEditingController> _gridTextController =  {};
  final FocusNode _inputAmountFocusNode = FocusNode();

  String? get _transactionType {
    final providedType = widget.transactionType;
    if (providedType != null && providedType.trim().isNotEmpty) {
      return providedType;
    }

    final arguments = Get.arguments;
    if (arguments is Map) {
      final type = arguments['type'];
      return type is String && type.trim().isNotEmpty ? type : null;
    }
    return null;
  }

  ContactModel? get _contactModel {
    final providedContact = widget.contactModel;
    if (providedContact != null) return providedContact;

    final arguments = Get.arguments;
    if (arguments is Map) {
      final contact = arguments['contactModel'];
      if (contact is ContactModel) return contact;

      final rawContactData = arguments['contact'];
      final Map<String, dynamic> contactData = rawContactData is Map
          ? Map<String, dynamic>.from(rawContactData)
          : Map<String, dynamic>.from(arguments);
      final phoneNumber =
          (contactData['phoneNumber'] ?? contactData['phone'])?.toString();
      if (phoneNumber == null || phoneNumber.trim().isEmpty) return null;

      return ContactModel(
        phoneNumber: phoneNumber,
        name: contactData['name']?.toString(),
        avatarImage: contactData['avatarImage']?.toString() ??
            contactData['avatar_image']?.toString(),
      );
    }
    return null;
  }

  void setFocus() {
    _inputAmountFocusNode.requestFocus();
    Get.back();
  }

  @override
  void initState() {
    super.initState();
    final transactionType = _transactionType;
    if (transactionType == null || transactionType.isEmpty) return;
    if (transactionType == TransactionType.withdrawRequest) {
      Get.find<TransactionMoneyController>().getWithdrawMethods();
    }
    Get.find<AddMoneyController>().setPaymentMethod(null, isUpdate: false);
  }
 
  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    if (widget.transactionType == null &&
        (arguments == null || (arguments is Map) == false)) {
      return Scaffold(body: Center(child: Text('missing_data'.tr)));
    }

    final transactionType = _transactionType;
    if (transactionType == null || transactionType.isEmpty) {
      return Scaffold(body: Center(child: Text('missing_data'.tr)));
    }
    final contactModel = _contactModel;
    final requiresContact = transactionType == TransactionType.requestMoney ||
        transactionType == TransactionType.sendMoney ||
        transactionType == TransactionType.cashOut;
    if (requiresContact && contactModel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.off(() => TransactionMoneyScreen(transactionType: transactionType));
      });
      return Scaffold(
        appBar: CustomAppbarWidget(title: transactionType.tr),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final ProfileController profileController = Get.find<ProfileController>();
    final SplashController splashController = Get.find<SplashController>();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
          appBar: CustomAppbarWidget(title: transactionType.tr),

          body: GetBuilder<TransactionMoneyController>(
              builder: (transactionMoneyController) {
                final fields = _fieldList ?? <MethodField>[];
                final gridFields = _gridFieldList ?? <MethodField>[];
                final purposeList = transactionMoneyController.purposeList;
                if(transactionType == TransactionType.withdrawRequest &&
                    transactionMoneyController.withdrawModel == null) {
                  return CustomLoaderWidget(color: Theme.of(context).primaryColor);
                }
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(transactionType != TransactionType.addMoney &&
                          transactionType != TransactionType.withdrawRequest)
                        ForPersonWidget(contactModel: contactModel),


                      if(transactionType == TransactionType.withdrawRequest)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeDefault,
                            horizontal: Dimensions.paddingSizeSmall,
                          ),
                          child: Column(children: [
                            Container(
                              height: context.height * 0.05,
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(Dimensions.radiusSizeSmall),
                                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.4)),
                              ),

                              child: DropdownButton<String>(
                                menuMaxHeight: Get.height * 0.5,
                                hint: Text(
                                  'please_select_a_method'.tr,
                                  style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                ),
                                value: _selectedMethodId,
                                items: (transactionMoneyController.withdrawModel?.withdrawalMethods ?? []).map((withdraw) =>
                                    DropdownMenuItem<String>(
                                      value: withdraw.id.toString(),
                                      child: Text(
                                        withdraw.methodName ?? 'no method',
                                        style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                      ),
                                    )
                                ).toList(),

                                onChanged: (id) {
                                  _selectedMethodId = id;
                                  _gridFieldList = [];
                                  _fieldList = [];

                                  (transactionMoneyController.withdrawModel?.withdrawalMethods ?? []).firstWhere((method) =>
                                  method.id.toString() == id).methodFields.forEach((method) {
                                    _gridFieldList?.addIf((method.inputName ?? '').contains('cvv') || method.inputType == 'date', method);
                                  });


                                  (transactionMoneyController.withdrawModel?.withdrawalMethods ?? []).firstWhere((method) =>
                                  method.id.toString() == id).methodFields.forEach((method) {
                                    _fieldList?.addIf(!(method.inputName ?? '').contains('cvv') && method.inputType != 'date', method);
                                  });

                                  _textControllers = {};
                                  _gridTextController = {};

                                  for (var method in (_fieldList ?? [])) {
                                    _textControllers[method.inputName] = TextEditingController();
                                  }
                                  for (var method in (_gridFieldList ?? [])) {
                                    _gridTextController[method.inputName] = TextEditingController();
                                  }

                                  transactionMoneyController.update();
                                },

                                isExpanded: true,
                                underline: const SizedBox(),
                              ),
                            ),

                            const SizedBox(height: Dimensions.paddingSizeDefault),

                            if(fields.isNotEmpty) ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: fields.length,
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeExtraSmall, horizontal: 10,
                              ),

                              itemBuilder: (context, index) => FieldItemWidget(
                                methodField: fields[index],
                                textControllers: _textControllers,
                              ),
                            ),

                            if(gridFields.isNotEmpty)

                              GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  vertical: Dimensions.paddingSizeExtraSmall, horizontal: 10,
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 2,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: gridFields.length,

                                itemBuilder: (context, index) => FieldItemWidget(
                                  methodField: gridFields[index],
                                  textControllers: _gridTextController,
                                ),
                              ),

                          ],),
                        ),

                      InputBoxWidget(
                        inputAmountController: _inputAmountController,
                        focusNode: _inputAmountFocusNode,
                        transactionType: transactionType,
                      ),


                      if(transactionType == TransactionType.cashOut)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeLarge,
                            vertical:Dimensions.paddingSizeDefault,
                          ),
                          child: Row( children: [
                            Text(
                              'save_future_cash_out'.tr,
                              style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
                            ),
                            const Spacer(),

                            GetBuilder<ContactController>(
                              builder: (contactController) {
                                return Padding(
                                  padding: EdgeInsets.zero,
                                  child: CupertinoSwitch(
                                    value: contactController.isFutureSave,
                                    onChanged: contactController.onSaveChange,
                                  ),
                                );
                              }
                            ),

                          ],),
                        ),


                      transactionType == TransactionType.sendMoney
                          ? purposeList == null
                          ? CustomLoaderWidget(color: Theme.of(context).primaryColor)
                          :  purposeList.isEmpty
                          ? const SizedBox()
                          : MediaQuery.of(context).viewInsets.bottom > 10
                          ?
                      Container(
                        color: Theme.of(context).cardColor.withOpacity(0.92),
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.paddingSizeLarge,
                          vertical: Dimensions.paddingSizeSmall,
                        ),
                        child: Row(children: [
                          purposeList.isEmpty ?
                          Center(child: CircularProgressIndicator(
                            color: Theme.of(context).textTheme.titleLarge?.color ??
                                Colors.black87,
                          )) : const SizedBox(),

                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Text('change_purpose'.tr, style: rubikRegular.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                          ))
                        ],),

                      ): const PurposeWidget() : const SizedBox(),

                      if(transactionType == TransactionType.addMoney)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                          child: DigitalPaymentWidget(),
                        ),

                    ],
                  ),
                );
              }
          ),

          bottomNavigationBar: GetBuilder<TransactionMoneyController>(
              builder: (transactionMoneyController) {
                return GetBuilder<AddMoneyController>(
                  builder: (addMoneyController) {
                    final isLoading = addMoneyController.isLoading || transactionMoneyController.isLoading;
                    return Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      color: Theme.of(context).cardColor,
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSizeDefault),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading ? null : () {
                              double amount;
                              if(_inputAmountController.text.trim().isEmpty){
                                showCustomSnackBarHelper('please_input_amount'.tr, isError: true);
                              }else{
                                String balance = _inputAmountController.text.trim();
                                final symbol = splashController.configModel?.currencySymbol ?? '';
                                if(symbol.isNotEmpty && balance.contains(symbol)) {
                                  balance = balance.replaceAll(symbol, '');
                                }
                                if(balance.contains(',')){
                                  balance = balance.replaceAll(',', '');
                                }
                                if(balance.contains(' ')){
                                  balance = balance.replaceAll(' ', '');
                                }
                                amount = double.tryParse(balance) ?? 0.0;
                                if(amount <= 0) {
                                  showCustomSnackBarHelper('transaction_amount_must_be'.tr, isError: true);
                                }else {
                                  bool inSufficientBalance = false;
                                  bool isPaymentSelect = Get.find<AddMoneyController>().paymentMethod != null;

                                  final bool isCheck = transactionType != TransactionType.requestMoney
                                      && transactionType != TransactionType.addMoney;

                                  final configModel = splashController.configModel;
                                  final userBalance = profileController.userInfo?.balance ?? 0.0;
                                  if(isCheck && transactionType == TransactionType.sendMoney) {
                                    inSufficientBalance = PriceConverterHelper.balanceWithCharge(amount, configModel?.sendMoneyChargeFlat, false) > userBalance;
                                  }else if(isCheck && transactionType == TransactionType.cashOut) {
                                    inSufficientBalance = PriceConverterHelper.balanceWithCharge(amount, configModel?.cashOutChargePercent, true) > userBalance;
                                  }else if(isCheck && transactionType == TransactionType.withdrawRequest) {
                                    inSufficientBalance = PriceConverterHelper.balanceWithCharge(amount, configModel?.withdrawChargePercent, true) > userBalance;
                                  }else if(isCheck){
                                    inSufficientBalance = amount > userBalance;
                                  }

                                  if(inSufficientBalance) {
                                    showCustomSnackBarHelper('insufficient_balance'.tr, isError: true);
                                  }else if(transactionType == TransactionType.addMoney && !isPaymentSelect){
                                    showCustomSnackBarHelper('please_select_a_payment'.tr, isError: true);
                                  } else {
                                    _confirmationRoute(amount);
                                  }
                                }
                              }
                            },
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'continue_button'.tr,
                                    style: rubikMedium.copyWith(
                                      color: Colors.white,
                                      fontSize: Dimensions.fontSizeLarge,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
          ),

      ),
    );
  }


  void _confirmationRoute(double amount) {
    final transactionType = _transactionType;
    final SplashController splashController = Get.find<SplashController>();
    if (transactionType == null || transactionType.isEmpty) {
      showCustomSnackBarHelper('error'.tr, isError: true);
      return;
    }

    final transactionMoneyController = Get.find<TransactionMoneyController>();
    if(transactionType == TransactionType.addMoney){
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('بيانات الحركة', textAlign: TextAlign.right),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF278D5B), Color(0xFF0C4A40)]), borderRadius: BorderRadius.circular(16)), child: Text('${amount.toStringAsFixed(2)} ${splashController.configModel?.currencySymbol ?? ''}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            const Text('يرجى التحقق من المبلغ وطريقة الدفع قبل المتابعة، فالعملية لا يمكن إلغاؤها بعد التنفيذ.', textAlign: TextAlign.right, style: TextStyle(color: Color(0xFFB3261E), fontSize: 12)),
          ]),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
            FilledButton(onPressed: () { Get.back(); Get.find<AddMoneyController>().addMoney(amount); }, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0C4A40)), child: const Text('تنفيذ')),
          ],
        ),
      );
    }
    else if(transactionType == TransactionType.withdrawRequest) {
      String? message;
      WithdrawalMethod? withdrawMethod = (transactionMoneyController.withdrawModel?.withdrawalMethods ?? []).
      firstWhereOrNull((method) => _selectedMethodId == method.id.toString());

      List<MethodField> list = [];
      String? validationKey;

      if(withdrawMethod != null) {
        for (var method in withdrawMethod.methodFields) {
          if(method.inputType == 'email') {
            validationKey = method.inputName;
          }
          if(method.inputType == 'date') {
            validationKey = method.inputName;
          }
        }
      }else{
        message = 'please_select_a_method'.tr;
      }

      _textControllers.forEach((key, textController) {
        list.add(MethodField(
          inputName: key, inputType: null,
          inputValue: textController.text,
          placeHolder: null,
        ));

        if((validationKey == key) && EmailCheckerHelper.isNotValid(textController.text)) {
          message = 'please_provide_valid_email'.tr;
        }else if((validationKey == key) && textController.text.contains('-')) {
          message = 'please_provide_valid_date'.tr;
        }

        if(textController.text.trim().isEmpty && message == null) {
          message = 'please_fill_all_fields'.tr;
        }
      });

      _gridTextController.forEach((key, textController) {
        list.add(MethodField(
          inputName: key, inputType: null,
          inputValue: textController.text,
          placeHolder: null,
        ));

        if((validationKey == key) && textController.text.contains('-')) {
          message = 'please_provide_valid_date'.tr;
        }

        if(textController.text.trim().isEmpty && message == null) {
          message = 'please_fill_all_fields'.tr;
        }
      });

      if(message != null) {
        showCustomSnackBarHelper(message, isError: true);
        message = null;
      }
      else if (withdrawMethod != null) {
        Get.to(() => TransactionConfirmationScreen(
          inputBalance: amount,
          transactionType: TransactionType.withdrawRequest,
          contactModel: null,
          withdrawMethod: WithdrawalMethod(
            methodFields: list,
            methodName: withdrawMethod.methodName,
            id: withdrawMethod.id,
          ),
          callBack: setFocus,
        ));
      }
    }
    else{
      final purposes =
          transactionMoneyController.purposeList ?? <PurposeModel>[];
      final selectedItem = transactionMoneyController.selectedItem;
      final purposeTitle = selectedItem >= 0 && selectedItem < purposes.length
          ? purposes[selectedItem].title
          : PurposeModel().title;
      Get.to(()=> TransactionConfirmationScreen(
        inputBalance: amount,
        transactionType: transactionType,
        purpose: transactionType == TransactionType.sendMoney
            ? purposeTitle
            : TransactionType.requestMoney.tr,

        contactModel: _contactModel,
        callBack: setFocus,

      ));
    }


  }
}
