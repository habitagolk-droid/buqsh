import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

export 'token_storage.dart' show UserRole;

class FcmService {
  static const _baseUrl = 'https://buqsh.online/api/v1';

  static String _endpoint(UserRole role) => switch (role) {
    UserRole.customer => '$_baseUrl/customer/update-fcm-token',
    UserRole.cashier  => '$_baseUrl/cashier/update-fcm-token',
    UserRole.merchant => '$_baseUrl/merchant/update-fcm-token',
  };

  /// استدعها بعد كل login ناجح
  static Future<bool> syncForRole(UserRole role) async {
    try {
      final fcm = await FirebaseMessaging.instance.getToken();
      if (fcm == null) return false;

      final auth = await TokenStorage.getAuthToken(role);
      if (auth == null) return false;

      final res = await http.put(
        Uri.parse(_endpoint(role)),
        headers: {
          'Authorization': 'Bearer $auth',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcm}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        await TokenStorage.saveFcmToken(role, fcm);
        if (kDebugMode) {
          print('✅ FCM synced for ${role.name}');
        }
        return true;
      }
      if (kDebugMode) {
        print('❌ FCM failed (${res.statusCode}): ${res.body}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ FCM error: $e');
      }
      return false;
    }
  }

  /// سجّلها في main()
  static void listenToRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final role = await TokenStorage.getActiveRole();
      if (role == null) return;
      final auth = await TokenStorage.getAuthToken(role);
      if (auth == null) return;

      try {
        await http.put(
          Uri.parse(_endpoint(role)),
          headers: {
            'Authorization': 'Bearer $auth',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fcm_token': newToken}),
        );
        await TokenStorage.saveFcmToken(role, newToken);
      } catch (_) {}
    });
  }
}
