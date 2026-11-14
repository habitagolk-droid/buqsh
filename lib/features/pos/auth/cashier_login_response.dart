class CashierLoginResponse {
  final String token;
  final bool? mustChangePassword;

  const CashierLoginResponse({
    required this.token,
    required this.mustChangePassword,
  });

  factory CashierLoginResponse.fromBody(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Expected a JSON object');
    }

    final tokenValues = _valuesForKey(body, 'token');
    if (tokenValues.length != 1 ||
        tokenValues.single is! String ||
        (tokenValues.single as String).trim().isEmpty) {
      throw const FormatException('Expected one non-empty token field');
    }

    final passwordChangeValues = _valuesForKey(body, 'must_change_password');
    if (passwordChangeValues.length > 1) {
      throw const FormatException('Ambiguous password-change status');
    }

    final passwordChangeValue = passwordChangeValues.isEmpty
        ? null
        : passwordChangeValues.single;
    if (passwordChangeValue != null && passwordChangeValue is! bool) {
      throw const FormatException('Invalid password-change status');
    }

    final receivedToken = (tokenValues.single as String).trim();
    final token = receivedToken.startsWith('Bearer ')
        ? receivedToken.substring('Bearer '.length).trim()
        : receivedToken;
    if (token.isEmpty) {
      throw const FormatException('Expected a non-empty token');
    }

    return CashierLoginResponse(
      token: token,
      mustChangePassword: passwordChangeValue as bool?,
    );
  }

  static List<dynamic> _valuesForKey(dynamic value, String key) {
    final values = <dynamic>[];
    _collectValues(value, key, values);
    return values;
  }

  static void _collectValues(dynamic value, String key, List<dynamic> values) {
    if (value is Map) {
      value.forEach((entryKey, entryValue) {
        if (entryKey == key) {
          values.add(entryValue);
        }
        _collectValues(entryValue, key, values);
      });
    } else if (value is Iterable) {
      for (final item in value) {
        _collectValues(item, key, values);
      }
    }
  }
}
