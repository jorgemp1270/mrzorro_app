import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'journal_entry_screen.dart';
import 'package:mrzorro_app/utils/file_utils.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isAnalyzing = false;
  String? _analysisResult;
  String? _currentUserId;
  Map<String, dynamic>? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final userId = await AuthService.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final originalFile = File(image.path);

        // Guardar en memoria interna directamente
        final savedFile = await FileUtils.saveImageToInternalStorage(
          originalFile,
        );

        setState(() {
          _capturedImage = savedFile;
          _isAnalyzing = true;
        });

        await _analyzeImage(savedFile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al tomar foto: $e')));
    }
  }

  Future<void> _analyzeImage(File image) async {
    if (_currentUserId == null) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult =
            'Error: Usuario no identificado. Por favor inicia sesión nuevamente.';
      });
      return;
    }

    try {
      // Convert image to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call the predict-image API
      final result = await ApiService.predictImage(
        userId: _currentUserId!,
        imageBase64: base64Image,
      );

      setState(() {
        _isAnalyzing = false;
        if (result['success']) {
          _aiAnalysis = result;
          _analysisResult =
              result['description'] ?? 'Imagen analizada correctamente';
        } else {
          _analysisResult = 'Error al analizar la imagen: ${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisResult = 'Error de conexión: $e';
      });
    }
  }

  Future<void> _createJournalEntry() async {
    if (_capturedImage == null) return;

    // Guardar imagen en memoria interna
    final savedImage = await FileUtils.saveImageToInternalStorage(
      _capturedImage!,
    );

    // Use the AI-predicted label as the title, or fallback to default
    String journalTitle = 'Nueva entrada desde cámara';
    if (_aiAnalysis != null && _aiAnalysis!['label'] != null) {
      journalTitle = _aiAnalysis!['label'];
    }

    // Pasar la imagen y análisis AI directamente a JournalEntryScreen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => JournalEntryScreen(
              title: journalTitle,
              initialImage: savedImage,
              aiAnalysis: _aiAnalysis,
            ),
      ),
    );

    // If entry was created, return to journal screen with success indicator
    if (result == true && mounted) {
      Navigator.pop(context, true); // Return true to indicate entry was created
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
      _analysisResult = null;
      _aiAnalysis = null;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Cámara',
              style: (currentFont.style ?? const TextStyle()).copyWith(
                color: currentTheme.primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body:
              _capturedImage == null
                  ? _buildCameraPrompt()
                  : _buildImagePreview(),
        );
      },
    );
  }

  Widget _buildCameraPrompt() {
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: currentTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 80,
                color: currentTheme.primaryColor,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Captura un momento',
              style: (currentFont.style ?? const TextStyle()).copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: currentTheme.textColor,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              'Toma una foto y la analizaré para crear una entrada en tu diario',
              textAlign: TextAlign.center,
              style: (currentFont.style ?? const TextStyle()).copyWith(
                fontSize: 16,
                color: currentTheme.textColor.withOpacity(0.6),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: Text(
                  'Abrir Cámara',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              _capturedImage!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 20),

          // Analysis Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: currentTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: currentTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Análisis de Imagen',
                      style: (currentFont.style ?? const TextStyle()).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: currentTheme.textColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (_isAnalyzing)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: currentTheme.primaryColor,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Analizando imagen...',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.textColor.withOpacity(0.6),
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  )
                else if (_analysisResult != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main description
                      Text(
                        _analysisResult!,
                        style: (currentFont.style ?? const TextStyle())
                            .copyWith(
                              fontSize: 15,
                              color: currentTheme.textColor,
                              height: 1.5,
                            ),
                      ),

                      // Show additional AI insights if available
                      if (_aiAnalysis != null) ...[
                        if (_aiAnalysis!['recommendation']?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: currentTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb,
                                      color: currentTheme.primaryColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Recomendación',
                                      style: (currentFont.style ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: currentTheme.primaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _aiAnalysis!['recommendation'],
                                  style: (currentFont.style ??
                                          const TextStyle())
                                      .copyWith(
                                        fontSize: 13,
                                        color: currentTheme.textColor,
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (_aiAnalysis!['interesting_fact']?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: currentTheme.secondaryColor.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      color: currentTheme.secondaryColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Dato Interesante',
                                      style: (currentFont.style ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: currentTheme.secondaryColor,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _aiAnalysis!['interesting_fact'],
                                  style: (currentFont.style ??
                                          const TextStyle())
                                      .copyWith(
                                        fontSize: 13,
                                        color: currentTheme.textColor,
                                        height: 1.4,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakePicture,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    'Volver a tomar',
                    style: (currentFont.style ?? const TextStyle()),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: currentTheme.primaryColor,
                    side: BorderSide(color: currentTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _createJournalEntry,
                  icon: const Icon(Icons.check),
                  label: Text(
                    'Crear entrada',
                    style: (currentFont.style ?? const TextStyle()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
