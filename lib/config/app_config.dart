class AppConfig {
  const AppConfig._();

  static const String appName = 'buqsh';
  static const String baseUrl = 'https://www.buqsh.online';
  static const String apiVersion = '/api/v1';
  static const String defaultCurrency = 'YER';
  static const List<String> supportedCurrencies = ['YER', 'USD', 'SAR'];
  static const String defaultLocale = 'ar';
  static const int defaultPageSize = 20;
  static const double screenPadding = 16;
  static const double cardRadius = 16;
  static const double buttonRadius = 12;

  static const Map<String, String> walletGradients = {
    'YER': 'C8102E-8B0000',
    'USD': '2E7D32-1B5E20',
    'SAR': '00695C-004D40',
  };
}
