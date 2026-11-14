import 'package:get/get.dart';
import 'package:intl/intl.dart';

String getTransactionTitle(String? type) {
  switch (type) {
    case 'exchange':
    case 'wallet_exchange':
      return 'wallet_exchange'.tr;
    case 'send_money':
    case 'money_transfer_message':
      return 'money_transfer'.tr;
    case null:
    case '':
      return '';
    default:
      return type.tr;
  }
}

String formatTransactionPhone(String? phone) {
  if (phone == null || phone.trim().isEmpty) return '';

  final normalized = phone.trim().replaceAll(RegExp(r'[\s()-]'), '');
  final withoutPlus = normalized.startsWith('+')
      ? normalized.substring(1)
      : normalized;

  if (withoutPlus.startsWith('967')) {
    return '0${withoutPlus.substring(3)}';
  }
  return withoutPlus;
}

String formatTransactionDate(String? value) {
  if (value == null || value.isEmpty) return '';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return DateFormat('hh:mm a | dd-MM-yyyy', 'ar').format(date.toLocal());
}
