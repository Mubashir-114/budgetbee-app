class ApiConstants {
  ApiConstants._();

  static const String _defaultBaseUrl =
      'https://expense-manager-api-qn07.onrender.com/api/';

  static String get baseUrl {
    const configuredBaseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: _defaultBaseUrl,
    );
    return configuredBaseUrl.endsWith('/')
        ? configuredBaseUrl
        : '$configuredBaseUrl/';
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}