import 'package:get/get_connect/http/src/response/response.dart';
import 'package:uuid/uuid.dart';
import 'package:six_cash/data/api/api_client.dart';
import 'package:six_cash/util/app_constants.dart';

class WalletRepo {
  final ApiClient apiClient;

  WalletRepo({required this.apiClient});

  Future<Response> getWalletsList() async {
    Response response = await apiClient.getData(AppConstants.customerWalletsUri);
    if (response.statusCode == 404) {
      response = await apiClient.getData(AppConstants.walletsUri);
    }
    return response;
  }

  Future<Response> getExchangeRates() async {
    Response response = await apiClient.getData(AppConstants.customerWalletRatesUri);
    if (response.statusCode == 404) {
      response = await apiClient.getData(AppConstants.walletRatesUri);
    }
    return response;
  }

  Future<Response> setDefaultWallet({required int walletId}) async {
    Map<String, dynamic> body = {'wallet_id': walletId};
    Response response =
        await apiClient.postData(AppConstants.customerWalletDefaultUri, body);
    if (response.statusCode == 404) {
      response = await apiClient.postData(AppConstants.walletDefaultUri, body);
    }
    return response;
  }

  Future<Response> transferBetweenWallets({
    int? fromWalletId,
    int? toWalletId,
    String? fromCurrency,
    String? toCurrency,
    required double amount,
    String? note,
  }) async {
    Map<String, dynamic> body = {
      if (fromWalletId != null) 'from_wallet_id': fromWalletId,
      if (toWalletId != null) 'to_wallet_id': toWalletId,
      if (fromCurrency != null) 'from_currency': fromCurrency,
      if (toCurrency != null) 'to_currency': toCurrency,
      'amount': amount,
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final Map<String, String> headers = {
      'Idempotency-Key': const Uuid().v4(),
    };
    Response response = await apiClient.postData(
      AppConstants.customerWalletTransferUri,
      body,
      headers: headers,
    );
    if (response.statusCode == 404) {
      response = await apiClient.postData(
        AppConstants.walletTransferUri,
        body,
        headers: headers,
      );
    }
    return response;
  }
}
