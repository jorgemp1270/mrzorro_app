import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_settings.dart';

class ApiService {
  /// Add a diary entry
  static Future<Map<String, dynamic>> addDiaryEntry({
    required String userId,
    required String date,
    required String mood,
    String? title,
    String? note,
    String? imageBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.diaryUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user': userId,
          'date': date,
          'mood': mood,
          'title': title,
          'note': note,
          'img': imageBase64,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al agregar entrada',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get diary entries for a user
  static Future<Map<String, dynamic>> getDiaryEntries(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.diaryUrl}/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'entries': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al obtener entradas',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get diary entries for a user by date
  static Future<Map<String, dynamic>> getDiaryEntriesByDate(
    String userId,
    String date,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.diaryUrl}/$userId/$date'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'entries': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'No hay entradas para esta fecha',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Predict image label with AI description
  static Future<Map<String, dynamic>> predictImage({
    required String userId,
    required String imageBase64,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.predictImageUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({'user': userId, 'img': imageBase64}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'label': data['img'], // Predicted label from ResNet-50
          'overview': data['overview'], // AI-generated description from Gemini
          'description':
              data['overview']?['message'] ?? 'Imagen analizada correctamente',
          'recommendation': data['overview']?['recommendation'] ?? '',
          'interesting_fact': data['overview']?['interesting_fact'] ?? '',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error en predicción de imagen',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Generate prompt response
  static Future<Map<String, dynamic>> generatePromptResponse({
    required String userId,
    required String prompt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.promptUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({'user': userId, 'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'response': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error en generación de respuesta',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Make a purchase request
  /// Only one of theme or font should be non-null
  static Future<Map<String, dynamic>> makePurchase({
    required String userId,
    required String price,
    required String? theme,
    required String? font,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.makePurchaseUrl}'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user': userId,
          'price': price,
          'theme': theme,
          'font': font,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'response': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error en la compra',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get user purchases
  static Future<Map<String, dynamic>> getUserPurchases(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.purchasesUrl}/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'points': data['points'],
          'themes': data['themes'],
          'fonts': data['fonts'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al obtener datos de compras',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Update user settings
  static Future<Map<String, dynamic>> updateSettings(
    UpdateSettingsRequest request,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.settingsUrl),
        headers: ApiConfig.headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Configuración actualizada',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al actualizar configuración',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get user settings
  static Future<Map<String, dynamic>> getSettings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.settingsUrl}/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'settings': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al obtener configuración',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteContext(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.deleteContextUrl}/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al eliminar contexto',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Add a new contact
  static Future<Map<String, dynamic>> addContact({
    required String userId,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.contactsUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId, 'name': name, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al agregar contacto',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get contacts for a user
  static Future<Map<String, dynamic>> getContacts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.contactsUrl}/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'contacts': data};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al obtener contactos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Delete a contact
  static Future<Map<String, dynamic>> deleteContact({
    required String userId,
    required String name,
    required String phone,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.contactsUrl),
        headers: ApiConfig.headers,
        body: jsonEncode({'user_id': userId, 'name': name, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al eliminar contacto',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Get user danger level
  static Future<Map<String, dynamic>> getUserDangerLevel(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.dangerLevelUrl}/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'danger_level': data['danger_level']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al obtener nivel de peligro',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Reset user danger level
  static Future<Map<String, dynamic>> resetUserDangerLevel(
    String userId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/reset-danger-level/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'danger_level': data['danger_level'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              errorData['detail'] ?? 'Error al resetear nivel de peligro',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
