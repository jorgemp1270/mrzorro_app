import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  static const _secureStorage = FlutterSecureStorage();

  // Keys for secure storage
  static const String _emailKey = 'user_email';
  static const String _passwordKey = 'user_password';
  static const String _userDataKey = 'user_data';
  static const String _saveCredentialsKey = 'save_credentials';

  /// Login user with email and password
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorage.write(
          key: _userDataKey,
          value: jsonEncode(data['user']),
        );
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error en el inicio de sesión',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Sign up new user
  static Future<Map<String, dynamic>> signUp(
    String email,
    String password,
    String nickname,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.signupUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'nickname': nickname,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error en el registro',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Save credentials to secure storage
  static Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(key: _saveCredentialsKey, value: 'true');
  }

  /// Get saved credentials from secure storage
  static Future<Map<String, String?>> getSavedCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    final shouldSave = await _secureStorage.read(key: _saveCredentialsKey);

    return {'email': email, 'password': password, 'shouldSave': shouldSave};
  }

  /// Get saved user data
  static Future<Map<String, dynamic>?> getSavedUserData() async {
    final userData = await _secureStorage.read(key: _userDataKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  /// Get current user ID
  static Future<String?> getCurrentUserId() async {
    final userData = await getSavedUserData();
    return userData?['user'];
  }

  /// Get current user info
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    return await getSavedUserData();
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final userData = await getSavedUserData();
    return userData != null;
  }

  /// Clear saved credentials
  static Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.delete(key: _saveCredentialsKey);
  }

  /// Clear all user data
  static Future<void> clearAllUserData() async {
    await _secureStorage.deleteAll();
  }

  /// Check if credentials should be saved
  static Future<bool> shouldSaveCredentials() async {
    final shouldSave = await _secureStorage.read(key: _saveCredentialsKey);
    return shouldSave == 'true';
  }

  /// Auto login with saved credentials
  static Future<Map<String, dynamic>> autoLogin() async {
    final credentials = await getSavedCredentials();

    if (credentials['email'] != null &&
        credentials['password'] != null &&
        credentials['shouldSave'] == 'true') {
      return await login(credentials['email']!, credentials['password']!);
    }

    return {'success': false, 'message': 'No hay credenciales guardadas'};
  }

  /// Logout user and clear all data
  static Future<void> logout() async {
    await clearAllUserData();
  }
}
