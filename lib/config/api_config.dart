class ApiConfig {
  // Use 10.0.2.2 for Android emulator to connect to localhost
  // Use 127.0.0.1 for iOS simulator
  // static const String baseUrl = 'http://10.0.2.2:8000';
  static const String baseUrl = 'http://192.168.1.203:8000';

  // API Endpoints
  static const String loginEndpoint = '/login';
  static const String signupEndpoint = '/signup';
  static const String diaryEndpoint = '/diary';
  static const String predictImageEndpoint = '/predict-image';
  static const String promptEndpoint = '/prompt';
  static const String makePurchaseEndpoint = '/make-purchase';
  static const String purchasesEndpoint = '/purchases';

  // Complete URLs
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get signupUrl => '$baseUrl$signupEndpoint';
  static String get diaryUrl => '$baseUrl$diaryEndpoint';
  static String get predictImageUrl => '$baseUrl$predictImageEndpoint';
  static String get promptUrl => '$baseUrl$promptEndpoint';
  static String get makePurchaseUrl => '$baseUrl$makePurchaseEndpoint';
  static String get purchasesUrl => '$baseUrl$purchasesEndpoint';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
