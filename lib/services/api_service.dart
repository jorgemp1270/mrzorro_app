import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  /// Add a diary entry
  static Future<Map<String, dynamic>> addDiaryEntry({
    required String userId,
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
  static Future<Map<String, dynamic>> makePurchase({
    required String userId,
    required String price,
    required String theme
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.purchaseUrl}'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'user': userId,
          'price': price,
          'theme': theme,
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

  /// Get user points
  static Future<Map<String, dynamic>> getUserPoints(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.pointsUrl}/$userId'),
        headers: ApiConfig.headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'points': data['points']};
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Error al obtener puntos',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
