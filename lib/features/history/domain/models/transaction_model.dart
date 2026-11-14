class TransactionModel {
  int? totalSize;
  int? limit;
  int? offset;
  List<Transactions>? transactions;

  TransactionModel({
    this.totalSize,
    this.limit,
    this.offset,
    this.transactions,
  });

  TransactionModel.fromJson(Map<String, dynamic> json) {
    totalSize = json['total_size'];
    limit = json['limit'];
    offset = json['offset'];
    final transactionData = json['transactions'];
    if (transactionData is List) {
      transactions = transactionData
          .whereType<Map>()
          .map(
            (value) => Transactions.fromJson(Map<String, dynamic>.from(value)),
          )
          .toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    final transactionList = transactions;
    if (transactionList != null) {
      data['transactions'] = transactionList.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Transactions {
  String? transactionType;
  String? transactionId;
  String? referenceNumber;
  double? debit;
  double? credit;
  double? commission;
  UserInfo? userInfo;
  String? createdAt;
  double? amount;
  Receiver? receiver;
  Sender? sender;
  String? currencyCode;
  String? currencySymbol;

  String get senderName => sender?.name ?? '';
  String get senderPhone => sender?.phone ?? '';
  String get receiverName => receiver?.name ?? '';
  String get receiverPhone => receiver?.phone ?? '';

  Transactions({
    this.transactionType,
    this.transactionId,
    this.referenceNumber,
    this.debit,
    this.credit,
    this.commission,
    this.userInfo,
    this.createdAt,
    this.receiver,
    this.sender,
    this.amount,
    this.currencyCode,
    this.currencySymbol,
  });

  Transactions.fromJson(Map<String, dynamic> json) {
    transactionType = json['transaction_type']?.toString() ?? '';
    transactionId =
        json['transaction_id']?.toString() ?? json['id']?.toString();
    referenceNumber =
        json['reference_number']?.toString() ??
        json['referenceNumber']?.toString() ??
        transactionId;
    debit = json['debit'] != null
        ? double.tryParse(json['debit'].toString()) ?? 0.0
        : 0.0;
    credit = json['credit'] != null
        ? double.tryParse(json['credit'].toString()) ?? 0.0
        : 0.0;
    commission = json['commission'] != null
        ? double.tryParse(json['commission'].toString()) ?? 0.0
        : 0.0;
    final userInfoJson = _asJsonMap(json['user_info']);
    userInfo = userInfoJson == null ? null : UserInfo.fromJson(userInfoJson);
    final receiverJson = _asJsonMap(json['receiver']);
    receiver = receiverJson == null ? null : Receiver.fromJson(receiverJson);
    final senderJson = _asJsonMap(json['sender']);
    sender = senderJson == null ? null : Sender.fromJson(senderJson);
    createdAt = json['created_at']?.toString();
    amount = json['amount'] != null
        ? double.tryParse(json['amount'].toString()) ?? 0.0
        : 0.0;
    currencyCode =
        json['currency_code']?.toString() ??
        json['currency']?.toString() ??
        json['currencyCode']?.toString() ??
        'YER';
    currencySymbol =
        json['currency_symbol']?.toString() ??
        json['currencySymbol']?.toString();
  }

  String get displayCurrencySymbol {
    if (currencySymbol != null && currencySymbol?.trim().isNotEmpty == true) {
      return currencySymbol?.trim() ?? '';
    }
    if (currencyCode != null && currencyCode?.trim().isNotEmpty == true) {
      final code = currencyCode?.trim().toUpperCase() ?? '';
      switch (code) {
        case 'USD':
          return '\$';
        case 'SAR':
          return 'ر.س';
        case 'YER':
          return 'يل';
        default:
          return code;
      }
    }
    return '';
  }

  String get displayCurrencyCode {
    if (currencyCode != null && currencyCode?.trim().isNotEmpty == true) {
      return currencyCode?.trim().toUpperCase() ?? '';
    }
    return '';
  }

  String formatAmount() {
    final amt = (amount != null && (amount ?? 0) > 0)
        ? (amount ?? 0.0)
        : ((debit != null && (debit ?? 0) > 0)
              ? (debit ?? 0.0)
              : (credit ?? 0.0));
    final parts = amt
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    final symbol = displayCurrencySymbol;
    return symbol.isNotEmpty ? '$parts $symbol' : parts;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['transaction_type'] = transactionType;
    data['transaction_id'] = transactionId;
    data['debit'] = debit;
    data['credit'] = credit;
    final user = userInfo;
    if (user != null) {
      data['user_info'] = user.toJson();
    }
    data['created_at'] = createdAt;
    data['amount'] = amount;
    data['currency_code'] = currencyCode;
    data['currency_symbol'] = currencySymbol;
    return data;
  }
}

class UserInfo {
  String? phone;
  String? name;

  UserInfo({this.phone, this.name});

  UserInfo.fromJson(Map<String, dynamic> json) {
    phone = json['phone']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['phone'] = phone;
    data['name'] = name;
    return data;
  }
}

class Sender {
  String? phone;
  String? name;

  Sender({this.phone, this.name});

  Sender.fromJson(Map<String, dynamic> json) {
    phone = json['phone']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
  }
}

class Receiver {
  String? phone;
  String? name;
  Receiver({this.phone, this.name});

  Receiver.fromJson(Map<String, dynamic> json) {
    phone = json['phone']?.toString() ?? '';
    name = json['name']?.toString() ?? '';
  }
}

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
