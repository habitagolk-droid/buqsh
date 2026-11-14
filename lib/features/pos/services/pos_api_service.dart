import 'package:get/get_connect/http/src/response/response.dart';
import 'package:six_cash/data/api/api_client.dart';

class PosApiService {
  final ApiClient apiClient;

  PosApiService({required this.apiClient});

  Future<Response> lookupTerminal(String terminalNumber) async {
    final Map<String, dynamic> body = {'terminal_number': terminalNumber};
    Response response =
        await apiClient.postData('/api/v1/customer/pos/lookup', body);
    if (response.statusCode == 404) {
      response = await apiClient.postData('/customer/pos/lookup', body);
    }
    return response;
  }

  Future<Response> purchase({
    String? qrToken,
    required String idempotencyKey,
    String? terminalNumber,
    double? amount,
    String? currencyCode,
    String? note,
  }) async {
    final Map<String, dynamic> body = {};
    if (qrToken != null && qrToken.isNotEmpty) {
      body['qr_token'] = qrToken;
    }
    if (terminalNumber != null && terminalNumber.isNotEmpty) {
      body['terminal_number'] = terminalNumber;
    }
    if (amount != null && amount > 0) {
      body['amount'] = amount;
    }
    if (currencyCode != null && currencyCode.isNotEmpty) {
      body['currency'] = currencyCode;
      body['currency_code'] = currencyCode;
      body['wallet_currency'] = currencyCode;
    }
    if (note != null && note.trim().isNotEmpty) {
      body['note'] = note.trim();
    }

    final Map<String, String> headers = {'Idempotency-Key': idempotencyKey};
    Response response = await apiClient.postData(
      '/api/v1/customer/pos/purchase',
      body,
      headers: headers,
    );
    if (response.statusCode == 404) {
      response = await apiClient.postData(
        '/customer/pos/purchase',
        body,
        headers: headers,
      );
    }
    return response;
  }
}
