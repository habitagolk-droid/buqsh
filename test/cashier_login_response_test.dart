import 'package:flutter_test/flutter_test.dart';
import 'package:six_cash/features/pos/auth/cashier_login_response.dart';

void main() {
  group('CashierLoginResponse', () {
    test('extracts a uniquely named token from a wrapped response', () {
      final response = CashierLoginResponse.fromBody({
        'data': {'token': 'access-token', 'must_change_password': false},
      });

      expect(response.token, 'access-token');
      expect(response.mustChangePassword, isFalse);
    });

    test('accepts a missing password-change flag', () {
      final response = CashierLoginResponse.fromBody({'token': 'access-token'});

      expect(response.mustChangePassword, isNull);
    });

    test('rejects ambiguous token fields', () {
      expect(
        () => CashierLoginResponse.fromBody({
          'token': 'first-token',
          'data': {'token': 'second-token'},
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid password-change flag', () {
      expect(
        () => CashierLoginResponse.fromBody({
          'token': 'access-token',
          'must_change_password': 'true',
        }),
        throwsFormatException,
      );
    });
  });
}
