
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:six_cash/features/transaction_money/controllers/bootom_slider_controller.dart';
import 'package:six_cash/features/setting/controllers/profile_screen_controller.dart';
import 'package:six_cash/features/camera_verification/controllers/camera_screen_controller.dart';
import 'package:six_cash/features/splash/controllers/splash_controller.dart';
import 'package:six_cash/features/verification/controllers/verification_controller.dart';
import 'package:six_cash/data/api/api_checker.dart';
import 'package:six_cash/data/api/api_client.dart';
import 'package:six_cash/common/models/signup_body_model.dart';
import 'package:six_cash/common/models/response_model.dart';
import 'package:six_cash/features/auth/domain/models/user_short_data_model.dart';
import 'package:six_cash/features/auth/domain/reposotories/auth_repo.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_controller.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/util/app_constants.dart';
import 'package:six_cash/helper/custom_snackbar_helper.dart';
import 'package:six_cash/services/fcm_service.dart';
import 'package:six_cash/services/token_storage.dart';

class AuthController extends GetxController implements GetxService {
  final AuthRepo authRepo;
  AuthController({required this.authRepo}) {
    _biometric = authRepo.isBiometricEnabled();
    checkBiometricSupport();
  }

    bool _isLoading = false;
    bool _isVerifying = false;
    bool _biometric = true;
    bool _isBiometricSupported = false;
    bool _isAuthenticating = false;
    List<BiometricType> _bioList = [];
    List<BiometricType> get bioList => _bioList;

    bool get isLoading => _isLoading;
    bool get isVerifying => _isVerifying;
    bool get biometric => _biometric;
    bool get isBiometricSupported => _isBiometricSupported;
    bool get isAuthenticating => _isAuthenticating;

    Future<bool> canUseBiometrics() async {
      try {
        final LocalAuthentication bioAuth = LocalAuthentication();
        return (await bioAuth.canCheckBiometrics || await bioAuth.isDeviceSupported());
      } catch (_) {
        return false;
      }
    }

    Future<void> updatePin(String pin) async {
      await authRepo.writeSecureData(AppConstants.biometricPin, pin);
    }

    Future<bool> setBiometric(bool isActive, {String? customPin}) async {
      final String? pin = customPin ?? Get.find<BottomSliderController>().pin;
      if (pin == null || pin.trim().isEmpty) {
        showCustomSnackBarHelper('please_enter_your_valid_pin'.tr, isError: true);
        return false;
      }
      final response = await Get.find<ProfileController>().pinVerify(getPin: pin, isUpdateTwoFactor: false);
      if (response.statusCode == 200 && response.body != null) {
        _biometric = isActive;
        await authRepo.setBiometric(isActive);
        if (isActive && pin.isNotEmpty) {
          await authRepo.writeSecureData(AppConstants.biometricPin, pin);
        } else if (!isActive) {
          await removeBiometricPin();
        }
        await checkBiometricSupport();
        Get.back(closeOverlays: true);
        update();
        showCustomSnackBarHelper(
          isActive ? 'biometric_enabled_successfully'.tr : 'biometric_disabled_successfully'.tr,
          isError: false,
        );
        return true;
      }
      return false;
    }

  Future<String> biometricPin() async {
      return await  authRepo.readSecureData(AppConstants.biometricPin);
  }

  Future<void> removeBiometricPin() async {
    return await  authRepo.deleteSecureData(AppConstants.biometricPin);
  }

  void checkBiometricWithPin() async {
    if(_biometric && (await biometricPin() == ''))  {
      authRepo.setBiometric(false).then((value) => _biometric = authRepo.isBiometricEnabled());
    }
  }

  /// Requires device authentication before any sensitive money movement.
  /// biometricOnly=false allows the operating system to offer its device PIN
  /// or passcode when biometric authentication is unavailable.
  Future<bool> authenticateSensitiveOperation() async {
    if (_isAuthenticating) return false;

    _isAuthenticating = true;
    try {
      final LocalAuthentication bioAuth = LocalAuthentication();
      final isSupported = await bioAuth.isDeviceSupported();
      final canCheckBiometrics = await bioAuth.canCheckBiometrics;
      if (!isSupported && !canCheckBiometrics) return false;

      return await bioAuth.authenticate(
        localizedReason: 'authenticate_to_confirm_transaction'.tr,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Sensitive-operation authentication failed: $e');
      return false;
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> authenticateWithBiometric(
    bool autoLogin,
    String? pin, {
    bool fromUserInteraction = false,
  }) async {
    if (_isAuthenticating) return;

    final LocalAuthentication bioAuth = LocalAuthentication();
    _isBiometricSupported = await bioAuth.canCheckBiometrics || await bioAuth.isDeviceSupported();

    if (!_isBiometricSupported) {
      if (fromUserInteraction) {
        showCustomSnackBarHelper('device_not_support_biometric'.tr, isError: true);
      }
      return;
    }

    if (autoLogin) {
      if (!authRepo.isBiometricEnabled()) {
        if (fromUserInteraction) {
          showCustomSnackBarHelper('biometric_is_disabled'.tr, isError: true);
        }
        return;
      }

      final storedPin = await biometricPin();
      final user = getUserData();

      if (storedPin.isEmpty || user?.phone == null) {
        if (fromUserInteraction) {
          showCustomSnackBarHelper(
            'please_login_with_pin_first_to_activate_biometric'.tr,
            isError: true,
          );
        }
        return;
      }

      _isAuthenticating = true;
      try {
        final bool didAuthenticate = await bioAuth.authenticate(
          localizedReason: 'please_authenticate_to_login'.tr,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
            useErrorDialogs: true,
          ),
        );
        if (didAuthenticate) {
          login(code: user?.countryCode, phone: user?.phone, password: storedPin);
        }
      } catch (e) {
        debugPrint('Biometric authentication error: $e');
        if (fromUserInteraction) {
          showCustomSnackBarHelper('biometric_error'.tr, isError: true);
        }
      } finally {
        _isAuthenticating = false;
      }
    } else {
      _isAuthenticating = true;
      try {
        final bool didAuthenticate = await bioAuth.authenticate(
          localizedReason: 'please_authenticate_to_easy_access_for_next_time'.tr,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
            useErrorDialogs: true,
          ),
        );
        if (didAuthenticate && pin != null && pin.isNotEmpty) {
          await authRepo.writeSecureData(AppConstants.biometricPin, pin);
          await authRepo.setBiometric(true);
          _biometric = true;
          update();
        }
      } catch (e) {
        debugPrint('Biometric enrollment error: $e');
        if (fromUserInteraction) {
          showCustomSnackBarHelper('biometric_error'.tr, isError: true);
        }
      } finally {
        _isAuthenticating = false;
      }
    }
  }

  Future<void> checkBiometricSupport() async {
    try {
      final LocalAuthentication bioAuth = LocalAuthentication();
      final isSupported = await bioAuth.isDeviceSupported();
      final canCheck = await bioAuth.canCheckBiometrics;
      _bioList = await bioAuth.getAvailableBiometrics();
      _isBiometricSupported = (isSupported || canCheck);
      _biometric = authRepo.isBiometricEnabled();
      update();
    } catch (e) {
      debugPrint('checkBiometricSupport error: $e');
    }
  }

  Future<Response> checkPhone(String phone) async{
      _isLoading = true;
      update();
      Response response = await authRepo.checkPhoneNumber(phoneNumber: phone);

      if(response.statusCode == 200){
        if(!Get.find<SplashController>().configModel!.phoneVerification!) {
          requestCameraPermission(fromEditProfile: false);
        }else if(response.body['otp'] == "active"){
         Get.find<VerificationController>().startTimer();
         Get.toNamed(RouteHelper.getVerifyRoute());
        }else{
          showCustomSnackBarHelper(response.body['message']);
        }

      }
      else if(response.statusCode == 403 && response.body['user_type'] == 'customer'){

        PhoneNumber phoneNumber = PhoneNumber.parse(phone);
        String numberWithCountryCode = phoneNumber.international;

        String? countryCode = phoneNumber.countryCode;
        String? nationalNumber = numberWithCountryCode.replaceAll(countryCode, '');

        authRepo.setBiometric(false);
        Get.offNamed(RouteHelper.getLoginRoute(countryCode: countryCode,phoneNumber: nationalNumber));

      }
      else{
        ApiChecker.checkApi(response);
      }
      _isLoading = false;
      update();
      return response;
    }


  Future<void> requestCameraPermission({required bool fromEditProfile}) async {
    var serviceStatus = await Permission.camera.status;

    if(serviceStatus.isGranted && GetPlatform.isAndroid){
      Get.offNamed(RouteHelper.getSelfieRoute(fromEditProfile: fromEditProfile));
    }else{
      if(GetPlatform.isIOS){
        Get.offNamed(RouteHelper.getSelfieRoute(fromEditProfile: fromEditProfile));
      }else{
        final status = await Permission.camera.request();
        if (status == PermissionStatus.granted) {
          Get.offNamed(RouteHelper.getSelfieRoute(fromEditProfile: fromEditProfile));
        } else if (status == PermissionStatus.denied) {
          Get.find<CameraScreenController>().showDeniedDialog(fromEditProfile: fromEditProfile);
        } else if (status == PermissionStatus.permanentlyDenied) {
          Get.find<CameraScreenController>().showPermanentlyDeniedDialog(fromEditProfile: fromEditProfile);
        }
      }

    }
  }

    //Phone Number verification
  Future<ResponseModel> phoneVerify(String phoneNumber,String otp) async{
    _isLoading = true;
    update();
    Response response = await authRepo.verifyPhoneNumber(phoneNumber: phoneNumber, otp: otp);

    ResponseModel responseModel;
    if(response.statusCode == 200){
      responseModel = ResponseModel(true, response.body["message"]);
      Get.find<VerificationController>().cancelTimer();
      showCustomSnackBarHelper(responseModel.message, isError: false);
      requestCameraPermission(fromEditProfile: false);
    }
    else{
      responseModel = ResponseModel(false, response.body['errors'][0]['message']);
      showCustomSnackBarHelper(
          responseModel.message,
          isError: true);
    }
    _isLoading = false;
    update();
    return responseModel;
  }


  // registration ..
  Future<Response> registration(SignUpBodyModel signUpBody,List<MultipartBody> multipartBody) async{
      _isLoading = true;
      update();

      Map<String, String> allCustomerInfo = {
        'f_name': signUpBody.fName ?? '',
        'l_name': signUpBody.lName ?? '',
        'phone': signUpBody.phone!,
        'dial_country_code': signUpBody.dialCountryCode!,
        'password': signUpBody.password!,
        'gender': signUpBody.gender!,
        'occupation': signUpBody.occupation ?? '',
      };
      if(signUpBody.otp != null) {
        allCustomerInfo.addAll({'otp': signUpBody.otp!});
      }
      if(signUpBody.email != '') {
        allCustomerInfo.addAll({'email': signUpBody.email!});
      }

      Response response = await authRepo.registration(allCustomerInfo, multipartBody);

      if (response.statusCode == 200) {
        Get.find<CameraScreenController>().removeImage();

        await setUserData(UserShortDataModel(
          countryCode: signUpBody.dialCountryCode,
          phone: signUpBody.phone,
          name: '${signUpBody.fName} ${signUpBody.lName}'
        ));

        Get.offAllNamed(RouteHelper.getWelcomeRoute(
          countryCode: signUpBody.dialCountryCode,phoneNumber: signUpBody.phone,
          password: signUpBody.password,
        ));

      } else {
        ApiChecker.checkApi(response);
      }
      _isLoading = false;
      update();
      return response;
  }


  Future<Response> login({String? code, String? phone, String? password}) async {
    _isLoading = true;
    update();

    Response response = await authRepo.login(phone: phone, password: password, dialCode: code);

    // استخراج بيانات الاستجابة بأمان
    dynamic body = response.body;
    if (body is String) {
      try {
        body = jsonDecode(body);
      } catch (_) {}
    }

    // استخراج التوكن من أي صيغة يرسلها الخادم
    String? token;
    if (body is Map) {
      final rawToken = body['token'] ??
          (body['data'] is Map ? body['data']['token'] : null) ??
          body['content'] ??
          (body['data'] is Map ? body['data']['content'] : null) ??
          body['access_token'] ??
          (body['data'] is Map ? body['data']['access_token'] : null);
      if (rawToken != null) {
        final t = rawToken.toString().trim();
        if (t.isNotEmpty && t.toLowerCase() != 'null') {
          token = t.startsWith('Bearer ') ? t.substring(7).trim() : t;
        }
      }
      // بحث بديل في حال كانت التسمية مختلفة
      if (token == null) {
        for (final entry in body.entries) {
          if (entry.key.toString().toLowerCase().contains('token') &&
              entry.value is String &&
              (entry.value as String).trim().isNotEmpty) {
            final t = (entry.value as String).trim();
            token = t.startsWith('Bearer ') ? t.substring(7).trim() : t;
            break;
          }
        }
      }
    }

    // شرط النجاح يعتمد حصراً على وجود التوكن ونجاح كود الحالة HTTP
    final bool isSuccess = (response.statusCode == 200 || response.statusCode == 201) &&
        token != null &&
        token.isNotEmpty;

    if (isSuccess) {
      // تحديد الدور: تاجر أم عميل؟
      final user = (body is Map)
          ? (body['user'] ?? (body['data'] is Map ? body['data']['user'] : null))
          : null;
      final isMerchant = user is Map && user['is_merchant'] == true;
      final role = isMerchant ? UserRole.merchant : UserRole.customer;

      // Cashier login clears the customer session; do the same when switching
      // back to a customer/merchant so an old cashier token cannot reclaim the UI.
      if (Get.isRegistered<CashierAuthController>()) {
        await Get.find<CashierAuthController>().clearSessionForRoleSwitch();
      }

      // Detach any previous account from this device before assigning its token.
      await FcmService.clearForRole(
        role,
        authToken: await TokenStorage.getAuthToken(role),
      );
      await FcmService.clearOtherRoles(role);

      // حفظ التوكن في SharedPreferences و ApiClient
      await authRepo.saveUserToken(token);
      // حفظ التوكن في SecureStorage
      await TokenStorage.saveAuthToken(role, token);
      // حفظ الدور النشط
      await authRepo.saveActiveRole(role);
      // مزامنة FCM token
      unawaited(authRepo.updateToken(role: role));

      // إغلاق أي Snackbar مفتوح لتفادي ظهور أي شريط سابق
      if (Get.isSnackbarOpen) {
        Get.closeCurrentSnackbar();
      }

      // الانتقال الفوري للشاشة الرئيسية ومسح الشاشات السابقة
      Get.offAllNamed(RouteHelper.getNavBarRoute(), arguments: true);

      _isLoading = false;
      update();
      return response;
    } else {
      _isLoading = false;
      update();

      // عرض الخطأ فقط في حالة الفشل الحقيقي (تجنب عرض "success" في شريط أحمر نهائياً)
      String errorMessage = 'login_failed'.tr;
      if (body is Map) {
        final msg = body['message'];
        if (msg is String &&
            msg.trim().isNotEmpty &&
            msg.trim().toLowerCase() != 'success') {
          errorMessage = msg.trim();
        } else if (body['errors'] is List && (body['errors'] as List).isNotEmpty) {
          final firstError = (body['errors'] as List).first;
          if (firstError is Map && firstError['message'] != null) {
            errorMessage = firstError['message'].toString();
          }
        }
      } else if (response.statusText != null &&
          response.statusText!.isNotEmpty &&
          response.statusText!.toLowerCase() != 'ok') {
        errorMessage = response.statusText!;
      }

      showCustomSnackBarHelper(errorMessage, isError: true);

      return Response(
        statusCode: response.statusCode == 200 ? 400 : response.statusCode,
        statusText: errorMessage,
        body: response.body,
      );
    }
  }


  Future removeUser() async {

    _isLoading = true;
    update();
    Get.back();
    Response response = await authRepo.deleteUser();

    if (response.statusCode == 200) {
      Get.find<SplashController>().removeSharedData();
      showCustomSnackBarHelper('your_account_remove_successfully'.tr);
      Get.offAllNamed(RouteHelper.getSplashRoute());
    }else{
      Get.back();
      ApiChecker.checkApi(response);
    }
    _isLoading = false;
    update();
  }


  Future<Response> checkOtp()async{
      _isLoading = true;
      update();
      Response  response = await authRepo.checkOtpApi();
      if(response.statusCode == 200){
        _isLoading = false;
      }else{
        _isLoading = false;
        ApiChecker.checkApi(response);
      }
      update();
      return response;
  }

  Future<Response> verifyOtp(String otp)async{
    _isVerifying = true;
    update();
    Response  response = await authRepo.verifyOtpApi(otp: otp);
    if(response.statusCode == 200){
      _isVerifying = false;
      Get.back();
    }else{
      Get.back();
      ApiChecker.checkApi(response);
      _isVerifying = false;
    }
    _isVerifying = false;
    update();
    return response;
  }


  Future<Response> logout() async {
    _isLoading = true;
    update();
    Response response = await authRepo.logout();
    if (response.statusCode == 200) {

      Get.offAllNamed(RouteHelper.getSplashRoute());
      _isLoading = false;
    }
    else{
      _isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }

  Future<ResponseModel?> otpForForgetPass(String phoneNumber) async{
    _isLoading = true;
    update();
    Response response = await authRepo.forgetPassOtp(phoneNumber: phoneNumber);
    ResponseModel? responseModel;

    if(response.statusCode == 200){
      _isLoading = false;
      Get.toNamed(RouteHelper.getVerifyRoute(phoneNumber: phoneNumber));
    }
    else{
      _isLoading = false;
      ApiChecker.checkApi(response);

    }
    update();
    return responseModel;
  }

  Future<Response> verificationForForgetPass(String? phoneNumber, String otp) async{
    _isLoading = true;
    update();
    Response response = await authRepo.forgetPassVerification(phoneNumber: phoneNumber,otp: otp);

    if(response.statusCode == 200){
      _isLoading = false;
      Get.offNamed(RouteHelper.getFResetPassRoute(phoneNumber: phoneNumber, otp: otp));
    }
    else{
      _isLoading = false;
      ApiChecker.checkApi(response);
    }
    update();
    return response;
  }


  String? getAuthToken() {
    return authRepo.getUserToken();
  }


  bool isLoggedIn() {
    return authRepo.isLoggedIn();
  }

  void removeCustomerToken() {
    authRepo.removeCustomerToken();
  }



  Future setUserData(UserShortDataModel userData) async {
    await authRepo.setUserData(userData);
  }
  UserShortDataModel? getUserData(){
    UserShortDataModel? userData;
    if(authRepo.getUserData() != '') {
      userData = UserShortDataModel.fromJson(jsonDecode(authRepo.getUserData()));
    }
    return userData;
  }

  void removeUserData()=>  authRepo.removeUserData();
}
