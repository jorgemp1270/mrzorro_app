import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:mrzorro_app/utils/file_utils.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? title;
  final String? initialPrompt;
  final File? initialImage;
  final Map<String, dynamic>? aiAnalysis;
  final Map<String, dynamic>? entry; // For editing existing entries

  const JournalEntryScreen({
    super.key,
    this.title,
    this.initialPrompt,
    this.initialImage,
    this.aiAnalysis,
    this.entry,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;
  String? _selectedMood;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    if (widget.title != null) {
      _titleController.text = widget.title!;
    }
    if (widget.initialPrompt != null) {
      _contentController.text = '${widget.initialPrompt}\n\n';
    }
    if (widget.initialImage != null) {
      _images.add(widget.initialImage!);
    }
    // Set mood from existing entry if editing
    if (widget.entry != null) {
      print('Setting mood from entry: ${widget.entry!['mood']}');
      _selectedMood = widget.entry!['mood'];
      _titleController.text = widget.entry!['title'] ?? '';
      _contentController.text = widget.entry!['note'] ?? '';
      _loadImageFromEntry();
    }
  }

  Future<void> _getCurrentUser() async {
    final userId = await AuthService.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<void> _loadImageFromEntry() async {
    if (widget.entry != null && widget.entry!['date'] != null) {
      try {
        print('Loading image for date: ${widget.entry!['date']}');
        final imagePath = await FileUtils.getImageFromDate(
          widget.entry!['date'],
        );
        print('Image path found: $imagePath');
        if (imagePath != null) {
          setState(() {
            _images.add(File(imagePath));
          });
          print('Image added to list, total images: ${_images.length}');
        } else {
          print('No image found for this date');
        }
      } catch (e) {
        print('Error loading image from entry: $e');
      }
    } else {
      print('No entry or date provided for image loading');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final originalFile = File(image.path);

        // Guardar en memoria interna
        final savedImage = await FileUtils.saveImageToInternalStorage(
          originalFile,
        );

        setState(() {
          _images.clear(); // Only keep one image
          _images.add(savedImage);
        });

        _analyzeImage(savedImage);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _analyzeImage(File image) async {
    // Aquí conectarías con tu backend para analizar la imagen
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Imagen añadida, el análisis de IA se realizará al guardar'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty &&
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega un título o contenido')),
      );
      return;
    }

    if (_selectedMood == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una emoción')));
      return;
    }

    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no identificado')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageBase64;
      if (_images.isNotEmpty) {
        // Save image to internal storage with date-based filename
        final savedImage = await FileUtils.saveImageToInternalStorage(
          _images.first,
        );
        // Convert to base64 for API
        final bytes = await savedImage.readAsBytes();
        imageBase64 = base64Encode(bytes);
      }

      final result = await ApiService.addDiaryEntry(
        userId: _currentUserId!,
        mood: _selectedMood!,
        title:
            _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : null,
        note:
            _contentController.text.trim().isNotEmpty
                ? _contentController.text.trim()
                : null,
        imageBase64: imageBase64,
      );

      if (!mounted) return;

      setState(() => _isSaving = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Entrada guardada exitosamente'),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful save
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: AppColors.lavender),
                  title: const Text('Tomar foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: AppColors.lavender),
                  title: const Text('Elegir de galería'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.close, color: AppColors.textSecondary),
                  title: const Text('Cancelar'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 244, 245),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.lavender),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.check_circle,
                color: AppColors.lavender,
                size: 30,
              ),
              onPressed: _saveEntry,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.lavenderLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Titulo',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Emotion Selection Row
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lavenderLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo te sientes?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEmotionChip('happy', '😊', 'Feliz'),
                      _buildEmotionChip('sad', '😢', 'Triste'),
                      _buildEmotionChip('excited', '🤩', 'Emocionado'),
                      _buildEmotionChip('calm', '😌', 'Tranquilo'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEmotionChip('anxious', '😰', 'Ansioso'),
                      _buildEmotionChip('angry', '😠', 'Enojado'),
                      _buildEmotionChip('tired', '😴', 'Cansado'),
                      _buildEmotionChip('grateful', '🙏', 'Agradecido'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content Field
            Container(
              constraints: const BoxConstraints(minHeight: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lavenderLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Escribe algo...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Single Image Display
            if (_images.isNotEmpty) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lavender.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _images.first,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _removeImage(0),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // AI Analysis Section
            if (widget.aiAnalysis != null) ...[
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
                        Icon(
                          Icons.analytics,
                          color: AppColors.lavender,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Análisis de IA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Main description
                    if (widget.aiAnalysis!['description'] != null)
                      Text(
                        widget.aiAnalysis!['description'],
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),

                    // Recommendation section
                    if (widget.aiAnalysis!['recommendation']?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb,
                                  color: AppColors.lavender,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Recomendación',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lavender,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.aiAnalysis!['recommendation'],
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Interesting fact section
                    if (widget.aiAnalysis!['interesting_fact']?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.peach.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: AppColors.peach,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Dato Interesante',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.peach,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.aiAnalysis!['interesting_fact'],
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Add Image Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _showImageOptions,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Agregar foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavender,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionChip(String emotion, String emoji, String label) {
    final isSelected = _selectedMood == emotion;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = emotion;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lavender : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.lavender
                    : AppColors.lavender.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: isSelected ? 20 : 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
