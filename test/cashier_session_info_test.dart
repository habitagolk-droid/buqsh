import 'package:flutter_test/flutter_test.dart';
import 'package:six_cash/features/pos/auth/cashier_session_info.dart';

void main() {
  group('CashierSessionInfo', () {
    test('extracts session fields from the data response envelope', () {
      final session = CashierSessionInfo.fromResponse({
        'response_code': 'default_200',
        'message': 'ok',
        'data': {'cashier_name': 'Cashier A', 'branch': 'North'},
      });

      expect(session?.fields, {'cashier_name': 'Cashier A', 'branch': 'North'});
      expect(session?.displayFields.map((field) => field.value).toList(), [
        'Cashier A',
        'North',
      ]);
    });

    test('extracts session fields from the project content envelope', () {
      final session = CashierSessionInfo.fromResponse({
        'response_code': 'default_200',
        'message': 'ok',
        'content': {'cashier_name': 'Cashier B'},
      });

      expect(session?.displayFields.single.value, 'Cashier B');
    });

    test('preserves direct session maps without assuming field names', () {
      final session = CashierSessionInfo.fromResponse({
        'name': 'Cashier C',
        'data': {'shift': 'Morning'},
      });

      expect(session?.displayFields.map((field) => field.value).toList(), [
        'Cashier C',
        'Morning',
      ]);
    });

    test('returns no session for empty or envelope-only responses', () {
      expect(CashierSessionInfo.fromResponse({}), isNull);
      expect(
        CashierSessionInfo.fromResponse({
          'response_code': 'default_200',
          'message': 'ok',
        }),
        isNull,
      );
      expect(
        CashierSessionInfo.fromResponse({
          'response_code': 'default_200',
          'data': {},
        }),
        isNull,
      );
    });

    test('does not expose sensitive session values', () {
      final session = CashierSessionInfo.fromResponse({
        'cashier_name': 'Cashier D',
        'access_token': 'private-token',
        'details': {'api_key': 'private-key', 'branch': 'East'},
      });

      expect(session?.displayFields.map((field) => field.value).toList(), [
        'Cashier D',
        'East',
      ]);
    });
  });
}
