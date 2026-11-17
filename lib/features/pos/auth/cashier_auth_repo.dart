import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:six_cash/services/fcm_service.dart';
import 'package:six_cash/services/token_storage.dart';
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:six_cash/data/api/api_client.dart';
import 'package:six_cash/util/app_constants.dart';

class CashierAuthRepo {
  final ApiClient apiClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  CashierAuthRepo({required this.apiClient});

  AndroidOptions _androidOptions() =>
      const AndroidOptions(encryptedSharedPreferences: true);

  IOSOptions _iosOptions() =>
      const IOSOptions(accessibility: KeychainAccessibility.first_unlock);

  Future<Response> login({required String username, required String password}) {
    return apiClient.postData(
      AppConstants.cashierLoginUri,
      {'username': username, 'password': password},
      headers: const {'Authorization': ''},
      sensitive: true,
    );
  }

  Future<Response> getInfo(String token) {
    final authorization = token.startsWith('Bearer ') ? token : 'Bearer $token';
    return apiClient.getData(
      AppConstants.cashierInfoUri,
      headers: {'Authorization': authorization},
      sensitive: true,
    );
  }

  Future<Response> confirm(Map<String, dynamic> body) {
    return apiClient.postData(
      AppConstants.cashierConfirmUri,
      body,
      headers: const {'Authorization': ''},
      sensitive: true,
    );
  }

  Future<Response> resendCode(Map<String, dynamic> body) {
    return apiClient.postData(
      AppConstants.cashierResendCodeUri,
      body,
      headers: const {'Authorization': ''},
      sensitive: true,
    );
  }

  /// جلب محافظ الكاشير والتاجر من GET /api/v1/cashier/wallets
  Future<Response> getCashierWallets(String token) {
    final authorization = token.startsWith('Bearer ') ? token : 'Bearer $token';
    return apiClient.getData(
      AppConstants.cashierWalletsUri,
      headers: {'Authorization': authorization},
      sensitive: true,
    );
  }

  /// جلب سجل حركات الكاشير من GET /api/v1/cashier/transactions.
  Future<Response> getCashierTransactions() async {
    final token = await getToken();
    if (token == null || token.trim().isEmpty) {
      return Response(
        statusCode: 401,
        body: {'message': 'Cashier session token is missing'},
      );
    }
    final authorization = token.startsWith('Bearer ') ? token : 'Bearer $token';
    return apiClient.getData(
      AppConstants.cashierTransactionsUri,
      headers: {'Authorization': authorization},
      sensitive: true,
    );
  }

  Future<Response> getCurrentShift() {
    return apiClient.getData(
      AppConstants.cashierCurrentShiftUri,
      sensitive: true,
    );
  }

  Future<Response> openShift({
    required String terminalNumber,
    required double openingBalance,
  }) {
    return apiClient.postData(AppConstants.cashierOpenShiftUri, {
      'terminal_number': terminalNumber,
      'opening_balance': openingBalance,
    }, sensitive: true);
  }

  Future<Response> closeShift({required double closingBalance}) {
    return apiClient.postData(AppConstants.cashierCloseShiftUri, {
      'closing_balance': closingBalance,
    }, sensitive: true);
  }

  Future<Response> submitRefund({
    required String receiptNumber,
    required double amount,
    required String reason,
  }) async {
    final token = await getToken();
    final authorization = (token ?? '').startsWith('Bearer ')
        ? token!
        : 'Bearer ${token ?? ''}';
    return apiClient.postData(
      AppConstants.cashierRefundUri,
      {
        'receipt_number': receiptNumber,
        'amount': amount,
        'reason': reason,
      },
      headers: {'Authorization': authorization},
      sensitive: true,
    );
  }

  /// يمسح جلسة العميل السابقة بالكامل من الذاكرة و ApiClient و SharedPreferences و SecureStorage
  Future<void> clearCustomerSession() async {
    try {
      await FcmService.clearForRole(
        UserRole.customer,
        authToken: await TokenStorage.getAuthToken(UserRole.customer),
      );
      // 1. مسح توكن العميل من TokenStorage
      await TokenStorage.clearRole(UserRole.customer);

      // 2. مسح توكن وبيانات العميل من SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.token);
      await prefs.remove(AppConstants.customerToken);
      await prefs.remove(AppConstants.userData);
      await prefs.remove('customer_token');
      await prefs.remove('token');

      // 3. مسح أي توكن عميل من FlutterSecureStorage
      await _secureStorage.delete(
        key: AppConstants.token,
        aOptions: _androidOptions(),
        iOptions: _iosOptions(),
      );
      await _secureStorage.delete(
        key: AppConstants.customerToken,
        aOptions: _androidOptions(),
        iOptions: _iosOptions(),
      );
      await _secureStorage.delete(
        key: 'customer_token',
        aOptions: _androidOptions(),
        iOptions: _iosOptions(),
      );
      await _secureStorage.delete(
        key: 'customer_auth_token',
        aOptions: _androidOptions(),
        iOptions: _iosOptions(),
      );

      // 4. تصفير الـ ApiClient حتى لا يحمل توكن العميل القديم في الذاكرة
      apiClient.token = null;
      apiClient.updateHeader('');
    } catch (e) {
      debugPrint('Error clearing customer session: $e');
    }
  }

  /// يُحدِّث ApiClient بتوكن الكاشير ليتم إرساله في ترويسة Authorization لجميع الطلبات القادمة
  void updateApiClient(String token) {
    apiClient.token = token;
    apiClient.updateHeader(token);
  }

  /// يحفظ 'cashier' كدور نشط في SharedPreferences.
  Future<void> saveActiveRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.activeRoleKey, UserRole.cashier.name);
  }

  /// يُرسل FCM token للكاشير إلى السيرفر عبر PUT /api/v1/cashier/update-fcm-token
  Future<bool> updateFcmToken(String authToken) async {
    try {
      await TokenStorage.saveAuthToken(UserRole.cashier, authToken);
      return await FcmService.syncForRole(UserRole.cashier);
    } catch (e) {
      debugPrint('Error updating cashier FCM token: $e');
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    updateApiClient(token);
    await TokenStorage.saveAuthToken(UserRole.cashier, token);
    return _secureStorage.write(
      key: AppConstants.cashierToken,
      value: token,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<String?> getToken() {
    return _secureStorage.read(
      key: AppConstants.cashierToken,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  /// Prevent a stale cashier token from taking over a customer/merchant session.
  Future<bool> canRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final activeRole = prefs.getString(AppConstants.activeRoleKey);
    // A missing role is allowed for compatibility with older cashier sessions.
    return activeRole == null || activeRole == UserRole.cashier.name;
  }

  Future<void> saveSessionData(String sessionJson) {
    return _secureStorage.write(
      key: 'cashier_session_info_json',
      value: sessionJson,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<String?> getSessionData() {
    return _secureStorage.read(
      key: 'cashier_session_info_json',
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }

  Future<void> removeToken() async {
    await FcmService.clearForRole(
      UserRole.cashier,
      authToken: await getToken() ?? await TokenStorage.getAuthToken(UserRole.cashier),
    );
    await TokenStorage.clearRole(UserRole.cashier);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(AppConstants.activeRoleKey) == UserRole.cashier.name) {
      await prefs.remove(AppConstants.activeRoleKey);
    }
    apiClient.token = null;
    apiClient.updateHeader('');
    await _secureStorage.delete(
      key: 'cashier_session_info_json',
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
    await _secureStorage.delete(
      key: AppConstants.cashierToken,
      aOptions: _androidOptions(),
      iOptions: _iosOptions(),
    );
  }
}
