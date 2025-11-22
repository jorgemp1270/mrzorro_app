import 'package:flutter/material.dart';
import '../config/api_config.dart';
import 'package:http/http.dart' as http;
import '../services/theme_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _testResult = 'Tap to test API connection';
  bool _isLoading = false;

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing connection...';
    });

    try {
      // Test basic connection to root endpoint
      final response = await http
          .get(
            Uri.parse(ApiConfig.baseUrl),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _testResult =
              'API Connection Successful! ✅\nResponse: ${response.body}';
        });
      } else {
        setState(() {
          _testResult =
              'API Error: Status ${response.statusCode}\nResponse: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _testResult =
            'Connection Error: $e\n\nMake sure the FastAPI backend is running on localhost:8000';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentFont = themeService.currentFont;
        final currentTheme = themeService.currentTheme;

        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          appBar: AppBar(
            title: Text(
              'API Connection Test',
              style: (currentFont.style ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            backgroundColor: currentTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Configuration:',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: currentTheme.textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Base URL: ${ApiConfig.baseUrl}',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    color: currentTheme.textColor,
                  ),
                ),
                Text(
                  'Login URL: ${ApiConfig.loginUrl}',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    color: currentTheme.textColor,
                  ),
                ),
                Text(
                  'Signup URL: ${ApiConfig.signupUrl}',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    color: currentTheme.textColor,
                  ),
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _isLoading ? null : _testApiConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Test API Connection',
                            style: (currentFont.style ?? const TextStyle()),
                          ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: currentTheme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: currentTheme.textColor.withOpacity(0.1),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _testResult,
                        style: (currentFont.style ?? const TextStyle())
                            .copyWith(
                              fontSize: 14,
                              color: currentTheme.textColor,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
