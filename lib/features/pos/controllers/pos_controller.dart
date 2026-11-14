import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:six_cash/features/auth/controllers/auth_controller.dart';
import 'package:six_cash/features/pos/models/pos_purchase_result.dart';
import 'package:six_cash/features/pos/models/pos_terminal.dart';
import 'package:six_cash/features/pos/services/pos_api_service.dart';
import 'package:six_cash/features/wallet/controllers/wallet_controller.dart';

class PosController extends GetxController implements GetxService {
  final PosApiService posApiService;

  PosController({required this.posApiService});

  PosTerminal? selectedTerminal;
  PosTerminal? get terminal => selectedTerminal;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  PosPurchaseResult? _lastResult;
  PosPurchaseResult? get lastResult => _lastResult;

  String? _currentIdempotencyKey;
  String? get currentIdempotencyKey => _currentIdempotencyKey;

  int _lookupGeneration = 0;

  void resetState() {
    _lookupGeneration++;
    selectedTerminal = null;
    _isLoading = false;
    _errorMessage = null;
    _lastResult = null;
    _currentIdempotencyKey = null;
    update();
  }

  void clearTerminal() {
    _lookupGeneration++;
    selectedTerminal = null;
    _isLoading = false;
    _errorMessage = null;
    update();
  }

  Future<bool> lookupTerminal(String terminalNumber) async {
    final requestedNumber = terminalNumber.trim();
    if (requestedNumber.isEmpty) {
      _errorMessage = 'please_enter_terminal_number'.tr;
      update();
      return false;
    }

    final requestGeneration = ++_lookupGeneration;
    _isLoading = true;
    _errorMessage = null;
    selectedTerminal = null;
    update();

    try {
      final response = await posApiService.lookupTerminal(requestedNumber);
      if (requestGeneration != _lookupGeneration) return false;
      if (_isSuccessful(response.statusCode)) {
        final terminalData = _extractTerminalData(response.body);
        if (terminalData == null) {
          _errorMessage = 'terminal_lookup_failed'.tr;
          _isLoading = false;
          update();
          return false;
        }

        final parsedTerminal = PosTerminal.fromJson(terminalData);
        if (parsedTerminal.terminalName.trim().isEmpty ||
            parsedTerminal.terminalName == 'unknown_terminal') {
          _errorMessage = 'terminal_not_found'.tr;
          _isLoading = false;
          update();
          return false;
        }

        selectedTerminal = PosTerminal(
          terminalNumber: parsedTerminal.terminalNumber.trim().isEmpty
              ? requestedNumber
              : parsedTerminal.terminalNumber,
          terminalName: parsedTerminal.terminalName,
          city: parsedTerminal.city,
          address: parsedTerminal.address,
          currencyCode: parsedTerminal.currencyCode,
          status: parsedTerminal.status,
        );
        _isLoading = false;
        update();
        return true;
      } else {
        String msg = 'terminal_not_found'.tr;
        if (response.body is Map && response.body['message'] != null) {
          msg = response.body['message'].toString();
        }
        _errorMessage = msg;
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      if (requestGeneration != _lookupGeneration) return false;
      debugPrint('POS terminal lookup failed: $e');
      _errorMessage = 'terminal_lookup_failed'.tr;
      _isLoading = false;
      update();
      return false;
    }
  }

  Future<bool> purchase({
    String? qrToken,
    String? terminalNumber,
    double? amount,
    String? currencyCode,
    String? note,
  }) async {
    final suppliedQrToken = qrToken?.trim() ?? '';
    final token = suppliedQrToken.length >= 32 ? suppliedQrToken : '';
    final suppliedTerminalNumber = terminalNumber?.trim() ?? '';
    final terminalNum = suppliedTerminalNumber.isNotEmpty
        ? suppliedTerminalNumber
        : selectedTerminal?.terminalNumber.trim() ?? '';

    if (selectedTerminal == null) {
      _errorMessage = 'please_search_terminal_first'.tr;
      update();
      return false;
    }

    if (amount == null || amount <= 0) {
      _errorMessage = 'enter_valid_amount'.tr;
      update();
      return false;
    }

    if (token.isEmpty && terminalNum.isEmpty) {
      _errorMessage = 'please_enter_terminal_number'.tr;
      update();
      return false;
    }

    final isAuthenticated = await Get.find<AuthController>()
        .authenticateSensitiveOperation();
    if (!isAuthenticated) {
      _errorMessage = 'transaction_authentication_cancelled'.tr;
      update();
      return false;
    }

    // ولّد Idempotency-Key مرة واحدة واحتفظ به للعملية الحالية
    final idempotencyKey = _currentIdempotencyKey ?? const Uuid().v4();
    _currentIdempotencyKey = idempotencyKey;

    _isLoading = true;
    _errorMessage = null;
    update();

    try {
      final response = await posApiService.purchase(
        qrToken: token.isNotEmpty ? token : null,
        idempotencyKey: idempotencyKey,
        terminalNumber: terminalNum.isNotEmpty ? terminalNum : null,
        amount: amount,
        currencyCode: currencyCode,
        note: note,
      );
      if (!_isSuccessful(response.statusCode)) {
        debugPrint('POS purchase failed [${response.statusCode}]');
      }

      if (response.statusCode == 302 || response.statusCode == 401) {
        _errorMessage = 'please_login_again'.tr;
        Get.snackbar(
          'error'.tr,
          _errorMessage ?? 'please_login_again'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        _isLoading = false;
        update();
        return false;
      }

      if (_isSuccessful(response.statusCode)) {
        final body = response.body;
        final data = (body is Map && body['data'] != null) ? body['data'] : body;
        if (data is Map<String, dynamic>) {
          _lastResult = PosPurchaseResult.fromJson(data);
        } else if (data is Map) {
          _lastResult =
              PosPurchaseResult.fromJson(Map<String, dynamic>.from(data));
        } else {
          _errorMessage = 'purchase_failed'.tr;
          _isLoading = false;
          update();
          return false;
        }
        _currentIdempotencyKey = null;

        if (Get.isRegistered<WalletController>()) {
          await Get.find<WalletController>().getWallets(reload: true);
        }

        _isLoading = false;
        update();
        return true;
      } else {
        String msg = 'purchase_failed'.tr;
        if (response.body is Map && response.body['message'] != null) {
          msg = response.body['message'].toString();
        } else if (response.statusText != null && response.statusText?.isNotEmpty == true) {
          msg = response.statusText ?? msg;
        }
        _errorMessage = msg;
        _isLoading = false;
        update();
        return false;
      }
    } catch (e) {
      debugPrint('POS purchase failed: $e');
      _errorMessage = 'purchase_failed'.tr;
      _isLoading = false;
      update();
      return false;
    }
  }

  bool _isSuccessful(int? statusCode) =>
      statusCode != null && statusCode >= 200 && statusCode < 300;

  Map<String, dynamic>? _extractTerminalData(dynamic body) {
    if (body is Map) {
      final root = Map<String, dynamic>.from(body);
      final data = root['data'];
      final terminal = root['terminal'] ?? root['pos_terminal'];

      if (terminal is Map) {
        return Map<String, dynamic>.from(terminal);
      }
      if (data is Map) {
        final nestedTerminal = data['terminal'] ?? data['pos_terminal'];
        if (nestedTerminal is Map) {
          return Map<String, dynamic>.from(nestedTerminal);
        }
        return Map<String, dynamic>.from(data);
      }
      return root;
    }
    return null;
  }
}
