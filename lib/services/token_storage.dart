import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum UserRole { customer, cashier, merchant }

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveAuthToken(UserRole role, String token) =>
      _storage.write(key: '${role.name}_auth_token', value: token);

  static Future<String?> getAuthToken(UserRole role) =>
      _storage.read(key: '${role.name}_auth_token');

  static Future<void> saveFcmToken(UserRole role, String token) =>
      _storage.write(key: '${role.name}_fcm_token', value: token);

  static Future<String?> getFcmToken(UserRole role) =>
      _storage.read(key: '${role.name}_fcm_token');

  static Future<void> saveUserId(UserRole role, int id) =>
      _storage.write(key: '${role.name}_user_id', value: id.toString());

  static Future<int?> getUserId(UserRole role) async {
    final v = await _storage.read(key: '${role.name}_user_id');
    return v == null ? null : int.tryParse(v);
  }

  static Future<void> clearRole(UserRole role) async {
    await _storage.delete(key: '${role.name}_auth_token');
    await _storage.delete(key: '${role.name}_fcm_token');
    await _storage.delete(key: '${role.name}_user_id');
  }

  static Future<UserRole?> getActiveRole() async {
    for (final r in UserRole.values) {
      final t = await getAuthToken(r);
      if (t != null && t.isNotEmpty) return r;
    }
    return null;
  }
}
