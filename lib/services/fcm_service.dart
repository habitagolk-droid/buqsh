import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:six_cash/util/app_constants.dart';
import 'token_storage.dart';

export 'token_storage.dart' show UserRole;

class FcmService {
  static const _baseUrl = '${AppConstants.baseUrl}/api/v1';

  static String _endpoint(UserRole role) => switch (role) {
    UserRole.customer => '$_baseUrl/customer/update-fcm-token',
    UserRole.cashier  => '$_baseUrl/cashier/update-fcm-token',
    UserRole.merchant => '$_baseUrl/merchant/update-fcm-token',
  };

  static String _authorization(String token) {
    final normalized = token.trim().replaceFirst(RegExp(r'^Bearer\s+'), '');
    return 'Bearer $normalized';
  }

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
          'Authorization': _authorization(auth),
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcm_token': fcm}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
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

  /// Clears the device token from the account before its session is discarded.
  static Future<bool> clearForRole(UserRole role, {String? authToken}) async {
    try {
      final auth = authToken ?? await TokenStorage.getAuthToken(role);
      if (auth == null || auth.trim().isEmpty) return false;

      final res = await http.put(
        Uri.parse(_endpoint(role)),
        headers: {
          'Authorization': _authorization(auth),
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcm_token': null}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        await TokenStorage.clearFcmToken(role);
        return true;
      }
      if (kDebugMode) {
        print('FCM clear failed for ${role.name} (${res.statusCode}): ${res.body}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('FCM clear error for ${role.name}: $e');
      return false;
    }
  }

  /// Removes stale assignments from other roles before associating a new login.
  static Future<void> clearOtherRoles(UserRole activeRole) async {
    for (final role in UserRole.values) {
      if (role != activeRole && await TokenStorage.getAuthToken(role) != null) {
        await clearForRole(role);
      }
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
            'Authorization': _authorization(auth),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'fcm_token': newToken}),
        );
        await TokenStorage.saveFcmToken(role, newToken);
      } catch (_) {}
    });
  }
}
