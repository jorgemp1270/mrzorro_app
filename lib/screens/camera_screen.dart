import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';
import 'journal_entry_screen.dart';
import 'package:intl/intl.dart';
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
    // Aquí conectarías con tu backend para analizar la imagen
    // Por ahora simularemos un análisis
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isAnalyzing = false;
      _analysisResult =
          'Se detectó: Una escena tranquila con naturaleza. '
          'Esto podría indicar un momento de paz y reflexión.';
    });
  }

  Future<void> _createJournalEntry() async {
    if (_capturedImage == null) return;

    // Guardar imagen en memoria interna
    final savedImage = await FileUtils.saveImageToInternalStorage(
      _capturedImage!,
    );

    // Pasar la imagen directamente a JournalEntryScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => JournalEntryScreen(
              initialPrompt: _analysisResult,
              initialImage: savedImage, // ← ENVIAR IMAGEN
            ),
      ),
    );
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
      _analysisResult = null;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 244, 245),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Camera',
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _capturedImage == null ? _buildCameraPrompt() : _buildImagePreview(),
    );
  }

  Widget _buildCameraPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.lavenderLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.camera_alt,
                size: 80,
                color: AppColors.lavender,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Captura un momento',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              'Toma una foto y la analizaré para crear una entrada en tu diario',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  'Abrir Cámara',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavender,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lavender.withOpacity(0.1),
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
                    Icon(Icons.analytics, color: AppColors.lavender, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Análisis de Imagen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                if (_isAnalyzing)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppColors.lavender),
                        const SizedBox(height: 15),
                        Text(
                          'Analizando imagen...',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_analysisResult != null)
                  Text(
                    _analysisResult!,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
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
                  label: const Text('Volver a tomar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.lavender,
                    side: BorderSide(color: AppColors.lavender),
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
                  label: const Text('Crear entrada'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lavender,
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
