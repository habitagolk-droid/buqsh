import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canUseBiometric() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> authenticate({required String reason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (Platform.isWindows || Platform.isLinux) {
        return const [];
      }
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }
}
