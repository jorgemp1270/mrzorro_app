import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../models/app_theme.dart';
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

        DateTime imageDate = DateTime.now();
        if (widget.entry != null && widget.entry!['date'] != null) {
          try {
            imageDate = DateTime.parse(widget.entry!['date']);
          } catch (e) {
            print('Error parsing date: $e');
          }
        }

        // Guardar en memoria interna
        final savedImage = await FileUtils.saveImageToInternalStorage(
          originalFile,
          imageDate,
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
        content: Text(
          'Imagen añadida, el análisis de IA se realizará al guardar',
        ),
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
        DateTime imageDate = DateTime.now();
        if (widget.entry != null && widget.entry!['date'] != null) {
          try {
            imageDate = DateTime.parse(widget.entry!['date']);
          } catch (e) {
            print('Error parsing date: $e');
          }
        }

        // Save image to internal storage with date-based filename
        final savedImage = await FileUtils.saveImageToInternalStorage(
          _images.first,
          imageDate,
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
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: currentTheme.primaryColor,
                  ),
                  title: Text(
                    'Tomar foto',
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      color: currentTheme.textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: currentTheme.primaryColor,
                  ),
                  title: Text(
                    'Elegir de galería',
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      color: currentTheme.textColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.close,
                    color: currentTheme.textColor.withOpacity(0.6),
                  ),
                  title: Text(
                    'Cancelar',
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      color: currentTheme.textColor,
                    ),
                  ),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: currentTheme.primaryColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Entrada',
              style: (currentFont.style ?? const TextStyle()).copyWith(
                color: currentTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              if (_isSaving)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentTheme.primaryColor,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: currentTheme.primaryColor,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: currentTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: currentTheme.primaryColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: currentTheme.textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Titulo',
                      border: InputBorder.none,
                      hintStyle: (currentFont.style ?? const TextStyle())
                          .copyWith(
                            color: currentTheme.textColor.withOpacity(0.5),
                          ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Emotion Selection Row
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: currentTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: currentTheme.primaryColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo te sientes?',
                        style: (currentFont.style ?? const TextStyle())
                            .copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: currentTheme.textColor,
                            ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEmotionChip(
                            'happy',
                            '😊',
                            'Feliz',
                            currentTheme,
                          ),
                          _buildEmotionChip(
                            'sad',
                            '😢',
                            'Triste',
                            currentTheme,
                          ),
                          _buildEmotionChip(
                            'excited',
                            '🤩',
                            'Emocionado',
                            currentTheme,
                          ),
                          _buildEmotionChip(
                            'calm',
                            '😌',
                            'Tranquilo',
                            currentTheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEmotionChip(
                            'anxious',
                            '😰',
                            'Ansioso',
                            currentTheme,
                          ),
                          _buildEmotionChip(
                            'angry',
                            '😠',
                            'Enojado',
                            currentTheme,
                          ),
                          _buildEmotionChip(
                            'tired',
                            '😴',
                            'Cansado',
                            currentTheme,
                          ),
                          _buildEmotionChip(
                            'grateful',
                            '🙏',
                            'Agradecido',
                            currentTheme,
                          ),
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
                    color: currentTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: currentTheme.primaryColor.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      fontSize: 16,
                      color: currentTheme.textColor,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Escribe algo...',
                      border: InputBorder.none,
                      hintStyle: (currentFont.style ?? const TextStyle())
                          .copyWith(
                            color: currentTheme.textColor.withOpacity(0.5),
                          ),
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
                          color: currentTheme.primaryColor.withOpacity(0.1),
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
                              'Análisis de IA',
                              style: (currentFont.style ?? const TextStyle())
                                  .copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: currentTheme.textColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Main description
                        if (widget.aiAnalysis!['description'] != null)
                          Text(
                            widget.aiAnalysis!['description'],
                            style: (currentFont.style ?? const TextStyle())
                                .copyWith(
                                  fontSize: 15,
                                  color: currentTheme.textColor,
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
                                  widget.aiAnalysis!['recommendation'],
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

                        // Interesting fact section
                        if (widget
                                .aiAnalysis!['interesting_fact']
                                ?.isNotEmpty ==
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
                                  widget.aiAnalysis!['interesting_fact'],
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
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Add Image Button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _showImageOptions,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(
                      'Agregar foto',
                      style: (currentFont.style ?? const TextStyle()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentTheme.primaryColor,
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
      },
    );
  }

  Widget _buildEmotionChip(
    String emotion,
    String emoji,
    String label,
    AppTheme theme,
  ) {
    final isSelected = _selectedMood == emotion;
    final currentFont = ThemeService().currentFont;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = emotion;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color:
                isSelected
                    ? theme.primaryColor
                    : theme.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: isSelected ? 20 : 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: (currentFont.style ?? const TextStyle()).copyWith(
                fontSize: 10,
                color: isSelected ? Colors.white : theme.textColor,
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
