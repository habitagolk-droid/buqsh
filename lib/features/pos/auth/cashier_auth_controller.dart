import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_repo.dart';
import 'package:six_cash/features/pos/auth/cashier_login_response.dart';
import 'package:six_cash/features/pos/auth/cashier_session_info.dart';
import 'package:six_cash/features/pos/screens/cashier_home_screen.dart';
import 'package:six_cash/helper/route_helper.dart';
import 'package:six_cash/services/fcm_service.dart';

class CashierAuthController extends GetxController {
  final CashierAuthRepo authRepo;

  CashierAuthController({required this.authRepo});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSessionReady = false;
  bool get isSessionReady => _isSessionReady;

  bool _isSessionInfoLoading = false;
  bool get isSessionInfoLoading => _isSessionInfoLoading;

  CashierSessionInfo? _sessionInfo;
  CashierSessionInfo? get sessionInfo => _sessionInfo;

  String? _sessionInfoError;
  String? get sessionInfoError => _sessionInfoError;

  Map<String, dynamic>? _currentShift;
  Map<String, dynamic>? get currentShift => _currentShift;

  bool _isShiftLoading = false;
  bool get isShiftLoading => _isShiftLoading;

  String? _shiftError;
  String? get shiftError => _shiftError;

  Future<void>? _restoreSessionFuture;
  int _sessionGeneration = 0;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_isLoading) return false;
    _isLoading = true;
    _isSessionReady = false;
    _errorMessage = null;
    _sessionInfo = null;
    _sessionInfoError = null;
    _currentShift = null;
    _shiftError = null;
    update();

    try {
      await authRepo.clearCustomerSession();
      await authRepo.removeToken();
      final loginResponse = await authRepo.login(
        username: username,
        password: password,
      );
      if (!_isSuccessful(loginResponse.statusCode)) {
        _errorMessage = _loginError(loginResponse);
        return false;
      }

      final credentials = CashierLoginResponse.fromBody(loginResponse.body);
      if (credentials.mustChangePassword == true) {
        _errorMessage = 'cashier_password_change_required'.tr;
        return false;
      }

      authRepo.updateApiClient(credentials.token);

      if (!await _loadSessionInfo(credentials.token)) {
        _errorMessage = _sessionInfoError;
        return false;
      }

      await FcmService.clearOtherRoles(UserRole.cashier);
      await authRepo.saveToken(credentials.token);

      // ⭐ حفظ الدور النشط + مزامنة FCM للكاشير بعد login ناجح
      await authRepo.saveActiveRole();
      unawaited(authRepo.updateFcmToken(credentials.token));

      _isSessionReady = true;
      update();
      Get.offAll(const CashierHomeScreen());
      return true;
    } on FormatException {
      _errorMessage = 'cashier_response_invalid'.tr;
      return false;
    } on PlatformException {
      _errorMessage = 'cashier_login_failed'.tr;
      return false;
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> restoreSession() {
    if (_isSessionReady || _isLoading) return Future<void>.value();
    return _restoreSessionFuture ??= _restoreStoredSession();
  }

  Future<void> _restoreStoredSession() async {
    final sessionGeneration = _sessionGeneration;
    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      if (!await authRepo.canRestoreSession() ||
          sessionGeneration != _sessionGeneration) {
        return;
      }

      final token = await authRepo.getToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }

      authRepo.updateApiClient(token);

      if (!await _loadSessionInfo(token)) {
        _errorMessage = _sessionInfoError;
        return;
      }

      if (sessionGeneration != _sessionGeneration ||
          !await authRepo.canRestoreSession()) {
        return;
      }

      _isSessionReady = true;
      Get.offAll(const CashierHomeScreen());
    } on PlatformException {
      _errorMessage = 'cashier_info_failed'.tr;
    } finally {
      _isLoading = false;
      update();
      _restoreSessionFuture = null;
    }
  }

  Future<void> retrySessionInfo() async {
    if (!_isSessionReady || _isSessionInfoLoading) return;

    try {
      final token = await authRepo.getToken();
      if (token == null || token.trim().isEmpty) {
        _sessionInfoError = 'cashier_session_expired'.tr;
        update();
        return;
      }
      await _loadSessionInfo(token);
    } on PlatformException {
      _sessionInfoError = 'cashier_info_failed'.tr;
      update();
    }
  }

  Future<void> fetchCurrentShift() async {
    if (_isShiftLoading) return;
    _isShiftLoading = true;
    _shiftError = null;
    update();

    try {
      final response = await authRepo.getCurrentShift();
      if (response.statusCode == 200) {
        final body = response.body;
        final data = body is Map ? body['data'] : null;
        if (data is Map) {
          _currentShift = Map<String, dynamic>.from(data);
        } else {
          _shiftError = 'تعذر قراءة بيانات الوردية';
          Get.snackbar('خطأ', _shiftError!);
        }
      } else if (response.statusCode == 404) {
        _currentShift = null;
      } else if (response.statusCode == 403) {
        _currentShift = null;
        Get.snackbar('خطأ', 'المستخدم ليس كاشيراً');
        await logout();
      } else {
        _shiftError = _responseMessage(response) ?? 'تعذر جلب حالة الوردية';
        Get.snackbar('خطأ', _shiftError!);
      }
    } finally {
      _isShiftLoading = false;
      update();
    }
  }

  Future<bool> openShift({
    required String terminalNumber,
    double openingBalance = 0,
  }) async {
    final normalizedTerminalNumber = terminalNumber.trim();
    if (normalizedTerminalNumber.isEmpty) {
      Get.snackbar('خطأ', 'رقم نقطة البيع غير متوفر');
      return false;
    }

    _isShiftLoading = true;
    _shiftError = null;
    update();
    try {
      final response = await authRepo.openShift(
        terminalNumber: normalizedTerminalNumber,
        openingBalance: openingBalance,
      );
      if (response.statusCode == 200) {
        final body = response.body;
        final data = body is Map ? body['data'] : null;
        if (data is! Map) {
          _shiftError = 'تعذر قراءة بيانات الوردية المفتوحة';
          Get.snackbar('خطأ', _shiftError!);
          return false;
        }
        _currentShift = Map<String, dynamic>.from(data);
        Get.snackbar('نجاح', 'تم فتح الوردية');
        return true;
      }

      if (response.statusCode == 403) {
        Get.snackbar('خطأ', 'المستخدم ليس كاشيراً');
        await logout();
      } else {
        _shiftError = _responseMessage(response) ?? 'فشل فتح الوردية';
        Get.snackbar('خطأ', _shiftError!);
      }
      return false;
    } finally {
      _isShiftLoading = false;
      update();
    }
  }

  Future<bool> closeShift({double closingBalance = 0}) async {
    _isShiftLoading = true;
    _shiftError = null;
    update();
    try {
      final response = await authRepo.closeShift(
        closingBalance: closingBalance,
      );
      if (response.statusCode == 200) {
        _currentShift = null;
        Get.snackbar('نجاح', 'تم إغلاق الوردية');
        return true;
      }

      if (response.statusCode == 403) {
        Get.snackbar('خطأ', 'المستخدم ليس كاشيراً');
        await logout();
      } else {
        _shiftError = _responseMessage(response) ?? 'فشل إغلاق الوردية';
        Get.snackbar('خطأ', _shiftError!);
      }
      return false;
    } finally {
      _isShiftLoading = false;
      update();
    }
  }

  Future<bool> _loadSessionInfo(String token) async {
    _isSessionInfoLoading = true;
    _sessionInfoError = null;
    update();

    try {
      final response = await authRepo.getInfo(token);
      if (!_isSuccessful(response.statusCode) || response.body is! Map) {
        if (response.statusCode == 401 || response.statusCode == 403) {
          await authRepo.removeToken();
        }
        _sessionInfoError = _infoError(response);
        return false;
      }

      _sessionInfo = CashierSessionInfo.fromResponse(response.body);
      return true;
    } on PlatformException {
      _sessionInfoError = 'cashier_info_failed'.tr;
      return false;
    } finally {
      _isSessionInfoLoading = false;
      update();
    }
  }

  void deactivateSession() {
    _isSessionReady = false;
    _sessionInfo = null;
    _sessionInfoError = null;
    update();
  }

  /// Clears the cashier session when another account type signs in.
  Future<void> clearSessionForRoleSwitch() async {
    // Invalidate any in-flight restore request before its API response arrives.
    _sessionGeneration++;
    _isSessionReady = false;
    _errorMessage = null;
    _sessionInfo = null;
    _sessionInfoError = null;
    _currentShift = null;
    _shiftError = null;
    update();
    await authRepo.removeToken();
  }

  Future<void> logout() async {
    await clearSessionForRoleSwitch();
    Get.offAllNamed(RouteHelper.cashierLogin);
    update();
  }

  String? _responseMessage(Response response) {
    final body = response.body;
    if (body is Map && body['message'] != null) {
      final message = body['message'].toString().trim();
      if (message.isNotEmpty) return message;
    }
    return null;
  }

  bool _isSuccessful(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  String _loginError(Response response) {
    if (response.statusCode == 404) {
      return 'cashier_login_unavailable'.tr;
    }
    if (response.statusCode == 1 || response.statusCode == -1) {
      return 'cashier_login_unavailable'.tr;
    }
    return 'cashier_login_failed'.tr;
  }

  String _infoError(Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'cashier_session_expired'.tr;
    }
    return 'cashier_info_failed'.tr;
  }
}
