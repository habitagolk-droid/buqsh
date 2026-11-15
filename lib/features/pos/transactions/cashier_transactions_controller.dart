import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:six_cash/features/pos/auth/cashier_auth_repo.dart';
import 'package:six_cash/features/pos/transactions/cashier_transaction.dart';

class CashierTransactionsController extends GetxController {
  CashierTransactionsController({required this.authRepo});

  final CashierAuthRepo authRepo;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<CashierTransaction> _transactions = const [];

  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  List<CashierTransaction> get transactions => _transactions;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  Future<void> fetchTransactions({bool forceRefresh = false}) async {
    if (_isLoading || (_hasLoaded && !forceRefresh)) return;
    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      final response = await authRepo.getCashierTransactions();
      if (response.statusCode == 200) {
        dynamic rawTransactions = response.body;
        for (var depth = 0; depth < 3 && rawTransactions is Map; depth++) {
          rawTransactions = rawTransactions['transactions'] ??
              rawTransactions['data'] ??
              rawTransactions['items'] ??
              rawTransactions['results'];
        }
        if (rawTransactions is! List) {
          _transactions = const [];
          _errorMessage = 'تعذر قراءة قائمة حركات الكاشير من الخادم.';
        } else {
          _transactions = rawTransactions
              .whereType<Map>()
              .map((item) => CashierTransaction.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false);
          _hasLoaded = true;
        }
      } else {
        _errorMessage = response.statusText?.toString().trim().isNotEmpty == true
            ? response.statusText.toString()
            : 'تعذر تحميل سجل عمليات الكاشير (${response.statusCode ?? '—'}).';
      }
    } catch (error, stackTrace) {
      debugPrint('Cashier transaction history request failed: $error\n$stackTrace');
      _errorMessage = 'تعذر تحميل سجل عمليات الكاشير. تحقق من الاتصال وحاول مجدداً.';
    } finally {
      _isLoading = false;
      _hasLoaded = true;
      update();
    }
  }
}
