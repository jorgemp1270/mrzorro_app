class ApiConfig {
  // Use 10.0.2.2 for Android emulator to connect to localhost
  // Use 127.0.0.1 for iOS simulator
  static const String baseUrl = 'http://10.0.2.2:8000';

  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String signupEndpoint = '/signup';
  static const String diaryEndpoint = '/diary';
  static const String predictImageEndpoint = '/predict-image';
  static const String promptEndpoint = '/prompt';
  static const String purchaseEndpoint = '/purchase';
  static const String pointsEndpoint = '/points';

  // Complete URLs
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get signupUrl => '$baseUrl$signupEndpoint';
  static String get diaryUrl => '$baseUrl$diaryEndpoint';
  static String get predictImageUrl => '$baseUrl$predictImageEndpoint';
  static String get promptUrl => '$baseUrl$promptEndpoint';
  static String get purchaseUrl => '$baseUrl$purchaseEndpoint';
  static String get pointsUrl => '$baseUrl$pointsEndpoint';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
