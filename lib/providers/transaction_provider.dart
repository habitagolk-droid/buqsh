import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  final List<TransactionModel> _transactions = [];
  bool _loading = false;
  String? _error;

  List<TransactionModel> get transactions => _transactions;
  bool get loading => _loading;
  String? get error => _error;

  void setTransactions(List<TransactionModel> data) {
    _transactions
      ..clear()
      ..addAll(data);
    _error = null;
    notifyListeners();
  }

  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void setError(String message) {
    _error = message;
    notifyListeners();
  }
}
