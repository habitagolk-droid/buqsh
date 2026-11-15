class CashierSessionInfo {
  final Map<String, dynamic> fields;

  const CashierSessionInfo._(this.fields);

  static CashierSessionInfo? fromResponse(dynamic responseBody) {
    if (responseBody is! Map) return null;

    var response = Map<String, dynamic>.from(responseBody);
    const envelopeKeys = {
      'data',
      'content',
      'message',
      'response_code',
      'success',
      'status',
    };
    final hasPayloadWrapper =
        response.containsKey('data') || response.containsKey('content');
    final isEnvelope =
        hasPayloadWrapper &&
        response.keys.every((key) => envelopeKeys.contains(key));
    if (isEnvelope) {
      final data = response['data'];
      final content = response['content'];
      if (data is Map) {
        response = Map<String, dynamic>.from(data);
      } else if (content is Map) {
        response = Map<String, dynamic>.from(content);
      } else {
        return null;
      }
    } else if (response.containsKey('response_code') ||
        response.containsKey('success')) {
      response.removeWhere(
        (key, _) => const {'message', 'response_code', 'success'}.contains(key),
      );
    }

    final visibleFields = Map<String, dynamic>.fromEntries(
      response.entries.where(
        (entry) =>
            !_isSensitiveKey(entry.key) && _hasDisplayableValue(entry.value),
      ),
    );
    return visibleFields.isEmpty ? null : CashierSessionInfo._(visibleFields);
  }

  List<MapEntry<String, String>> get displayFields {
    final fields = <MapEntry<String, String>>[];
    _appendFields(this.fields, '', fields);
    return fields;
  }

  String? get cashierName {
    return _findString(['cashier_name', 'name', 'full_name', 'username']) ??
        _findNestedString('cashier', ['name', 'full_name', 'username']);
  }

  String? get cashierCode {
    return _findString(['cashier_code', 'code', 'id', 'username']);
  }

  double? get availableBalance {
    final value = _findString([
      'available_balance',
      'current_balance',
      'balance',
      'wallet_balance',
    ]);
    return value == null ? null : double.tryParse(value.replaceAll(',', ''));
  }

  String get balanceCurrencyCode {
    return (_findString(['currency_code', 'currencyCode', 'currency']) ?? 'YER')
        .toUpperCase();
  }

  String? get terminalName {
    return _findString(['terminal_name', 'terminal_number', 'terminal_id']) ??
        _findNestedString('terminal', ['terminal_number', 'name', 'id']);
  }

  String? get terminalNumber {
    return _findString(['terminal_number']) ??
        _findNestedString('terminal', ['terminal_number']);
  }

  String? get merchantName {
    return _findString(['merchant_name', 'company_name', 'store_name']) ??
        _findNestedString('merchant', [
          'name',
          'business_name',
          'company_name',
        ]);
  }

  String? get branchName {
    return _findString(['branch_name', 'branch', 'city']) ??
        _findNestedString('branch', ['name', 'city']);
  }

  Map<String, dynamic>? get currentShift {
    if (fields['current_shift'] is Map) {
      return Map<String, dynamic>.from(fields['current_shift']);
    }
    if (fields['shift'] is Map) {
      return Map<String, dynamic>.from(fields['shift']);
    }
    return null;
  }

  bool get hasActiveShift {
    final shift = currentShift;
    if (shift == null) return false;
    final status = shift['status']?.toString().toLowerCase();
    return status == 'open' ||
        status == 'active' ||
        status == 'opened' ||
        status == '1';
  }

  double? get shiftOpeningBalance {
    final shift = currentShift;
    if (shift == null) return null;
    final val = shift['opening_balance'] ?? shift['initial_balance'];
    if (val == null) return null;
    return double.tryParse(val.toString());
  }

  double? get shiftTotalSales {
    final shift = currentShift;
    if (shift == null) return null;
    final val = shift['total_sales'] ?? shift['sales'] ?? shift['total_amount'];
    if (val == null) return null;
    return double.tryParse(val.toString());
  }

  int? get shiftTransactionsCount {
    final shift = currentShift;
    if (shift == null) return null;
    final val =
        shift['transactions_count'] ?? shift['orders_count'] ?? shift['count'];
    if (val == null) return null;
    return int.tryParse(val.toString());
  }

  String? _findString(List<String> keys) {
    for (final key in keys) {
      if (fields[key] != null && fields[key].toString().trim().isNotEmpty) {
        return fields[key].toString().trim();
      }
    }
    return null;
  }

  String? _findNestedString(String parent, List<String> keys) {
    final parentMap = fields[parent];
    if (parentMap is Map) {
      for (final key in keys) {
        if (parentMap[key] != null &&
            parentMap[key].toString().trim().isNotEmpty) {
          return parentMap[key].toString().trim();
        }
      }
    }
    return null;
  }

  static void _appendFields(
    Map<String, dynamic> values,
    String parentKey,
    List<MapEntry<String, String>> fields,
  ) {
    for (final entry in values.entries) {
      if (_isSensitiveKey(entry.key)) continue;

      final label = parentKey.isEmpty
          ? _formatKey(entry.key)
          : '$parentKey · ${_formatKey(entry.key)}';
      final value = entry.value;

      if (value is Map) {
        _appendFields(Map<String, dynamic>.from(value), label, fields);
      } else if (value is Iterable) {
        final items = <String>[];
        var index = 0;
        for (final item in value) {
          if (!_hasDisplayableValue(item)) continue;
          if (item is Map) {
            _appendFields(
              Map<String, dynamic>.from(item),
              '$label ${index + 1}',
              fields,
            );
          } else if (item is Iterable) {
            final nestedItems = item
                .where(_hasDisplayableValue)
                .map((nestedItem) => nestedItem.toString())
                .toList();
            if (nestedItems.isNotEmpty) items.addAll(nestedItems);
          } else {
            items.add(item.toString());
          }
          index++;
        }
        if (items.isNotEmpty) {
          fields.add(MapEntry(label, items.join(', ')));
        }
      } else if (_hasDisplayableValue(value)) {
        fields.add(MapEntry(label, value.toString()));
      }
    }
  }

  static bool _hasDisplayableValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Map) {
      return value.entries.any(
        (entry) =>
            !_isSensitiveKey(entry.key.toString()) &&
            _hasDisplayableValue(entry.value),
      );
    }
    if (value is Iterable) return value.any(_hasDisplayableValue);
    return true;
  }

  static bool _isSensitiveKey(String key) {
    final normalizedKey = key.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return normalizedKey.contains('authorization') ||
        normalizedKey.contains('password') ||
        normalizedKey.contains('secret') ||
        normalizedKey.contains('token') ||
        normalizedKey.contains('apikey');
  }

  static String _formatKey(String key) {
    final spaced = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]} ${match[2]}',
        )
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    return spaced.isEmpty
        ? key
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }
}
