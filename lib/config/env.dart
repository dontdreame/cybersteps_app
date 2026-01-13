class Env {
  Env._();

  /// Base URL for API requests.
  /// Override with: flutter run --dart-define=BASE_URL=https://example.com/api
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://cybersteps-1.onrender.com/api',
  );

  /// You can add more flags later:
  /// static const bool isProd = bool.fromEnvironment('PROD', defaultValue: false);
}
