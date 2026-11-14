import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:six_cash/features/history/domain/models/transaction_model.dart';
import 'package:six_cash/features/history/utils/transaction_formatting.dart';
import 'package:six_cash/features/pos/models/pos_terminal.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ar');
  });

  test('formats Yemeni phone numbers for transaction history', () {
    expect(formatTransactionPhone('+967 771-234-567'), '0771234567');
    expect(formatTransactionPhone('967771234567'), '0771234567');
    expect(formatTransactionPhone(null), '');
  });

  test('formats transaction dates with the Arabic locale pattern', () {
    expect(
      formatTransactionDate('2026-10-18T18:05:00'),
      matches(RegExp(r'^\d{2}:\d{2} .+ \| \d{2}-\d{2}-\d{4}$')),
    );
  });

  test('reads sender and receiver objects and currency_code from the API', () {
    final transaction = Transactions.fromJson({
      'transaction_type': 'send_money',
      'sender': {'name': 'Sender', 'phone': '+967771234567'},
      'receiver': {'name': 'Receiver', 'phone': '967770000000'},
      'currency_code': 'USD',
    });

    expect(transaction.senderName, 'Sender');
    expect(transaction.senderPhone, '+967771234567');
    expect(transaction.receiverName, 'Receiver');
    expect(transaction.receiverPhone, '967770000000');
    expect(transaction.currencyCode, 'USD');
  });

  test('defaults missing transaction currency to Yemeni rials', () {
    final transaction = Transactions.fromJson({});

    expect(transaction.currencyCode, 'YER');
  });

  test('reads the POS label from terminal_name, not a boolean name field', () {
    final terminal = PosTerminal.fromJson({
      'terminal_number': '12345',
      'terminal_name': 'Central Market',
      'name': true,
    });
    final malformedTerminal = PosTerminal.fromJson({'name': true});

    expect(terminal.terminalName, 'Central Market');
    expect(malformedTerminal.terminalName, 'unknown_terminal');
    expect(malformedTerminal.terminalNumber, isEmpty);
  });
}
