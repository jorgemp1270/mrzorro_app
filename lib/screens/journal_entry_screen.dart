import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import 'package:mrzorro_app/utils/file_utils.dart';

class JournalEntryScreen extends StatefulWidget {
  final String? title;
  final String? initialPrompt;
  final File? initialImage;

  const JournalEntryScreen({
    super.key,
    this.title,
    this.initialPrompt,
    this.initialImage,
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

  @override
  void initState() {
    super.initState();
    if (widget.title != null) {
      _titleController.text = widget.title!;
    }
    if (widget.initialPrompt != null) {
      _contentController.text = '${widget.initialPrompt}\n\n';
    }
    if (widget.initialImage != null) {
      _images.add(widget.initialImage!);
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
        content: Text('Imagen analizada. Se detectó: naturaleza, paisaje'),
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

    setState(() => _isSaving = true);

    // Aquí guardarías en tu backend
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entrada guardada exitosamente')),
    );

    Navigator.pop(context);
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

            // Images Grid
            if (_images.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    _images.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              entry.value,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => _removeImage(entry.key),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
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

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
