import 'package:flutter/material.dart';
import '../models/user_settings.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class CustomizeFoxScreen extends StatefulWidget {
  final String userId;

  const CustomizeFoxScreen({super.key, required this.userId});

  @override
  State<CustomizeFoxScreen> createState() => _CustomizeFoxScreenState();
}

class _CustomizeFoxScreenState extends State<CustomizeFoxScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _selectedAge = 'kids';
  String _selectedPersonality = 'default';
  final _considerationsController = TextEditingController();
  final _aboutMeController = TextEditingController();

  final List<String> _ageOptions = ['kids', 'teen', 'adult'];
  final List<String> _personalityOptions = [
    'default',
    'friendly',
    'professional',
    'funny',
    'empathetic',
    'wise',
    'energetic',
    'calm',
    'creative',
  ];

  final Map<String, String> _ageLabels = {
    'kids': 'Niños',
    'teen': 'Adolescentes',
    'adult': 'Adultos',
  };

  final Map<String, Map<String, String>> _personalityDetails = {
    'default': {'label': 'Por defecto', 'emoji': '🦊'},
    'friendly': {'label': 'Amigable', 'emoji': '😊'},
    'professional': {'label': 'Profesional', 'emoji': '👔'},
    'funny': {'label': 'Divertido', 'emoji': '🤪'},
    'empathetic': {'label': 'Empático', 'emoji': '🤗'},
    'wise': {'label': 'Sabio', 'emoji': '🦉'},
    'energetic': {'label': 'Enérgico', 'emoji': '⚡'},
    'calm': {'label': 'Relajado', 'emoji': '🧘'},
    'creative': {'label': 'Creativo', 'emoji': '🎨'},
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _considerationsController.dispose();
    _aboutMeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getSettings(widget.userId);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success']) {
        try {
          final settings = UserSettings.fromJson(result['settings']);
          setState(() {
            if (_ageOptions.contains(settings.age)) {
              _selectedAge = settings.age;
            }
            if (_personalityOptions.contains(settings.personality)) {
              _selectedPersonality = settings.personality;
            }
            _considerationsController.text = settings.considerations ?? '';
            _aboutMeController.text = settings.aboutMe ?? '';
          });
        } catch (e) {
          print("Error parsing settings: $e");
        }
      }
      // If not success (e.g. 404), we just keep defaults
    }
  }

  Future<void> _deleteContext() async {
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    // Show confirmation dialog
    final bool? confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: currentTheme.cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '¿Borrar memoria?',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  'Esta acción eliminará todos los recuerdos de conversación de Mr. Zorro. No se puede deshacer.',
                  textAlign: TextAlign.center,
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    color: currentTheme.textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(color: currentTheme.textColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.textColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Borrar',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final result = await ApiService.deleteContext(widget.userId);

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final settings = UserSettings(
      age: _selectedAge,
      personality: _selectedPersonality,
      considerations:
          _considerationsController.text.trim().isEmpty
              ? null
              : _considerationsController.text.trim(),
      aboutMe:
          _aboutMeController.text.trim().isEmpty
              ? null
              : _aboutMeController.text.trim(),
    );

    final request = UpdateSettingsRequest(
      user: widget.userId,
      settings: settings,
    );

    final result = await ApiService.updateSettings(request);

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración actualizada con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            backgroundColor: currentTheme.primaryColor,
            title: Text(
              'Personalizar Mr. Zorro',
              style: (currentFont.style ?? const TextStyle()).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text(
                          'Configuración de IA',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: currentTheme.primaryColor,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Age Selection
                        Text(
                          'Edad Objetivo',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children:
                              _ageOptions.map((age) {
                                final isSelected = _selectedAge == age;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () =>
                                            setState(() => _selectedAge = age),
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isSelected
                                                ? currentTheme.primaryColor
                                                : currentTheme.cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color:
                                              isSelected
                                                  ? currentTheme.primaryColor
                                                  : currentTheme.textColor
                                                      .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _ageLabels[age]!,
                                          style: (currentFont.style ??
                                                  const TextStyle())
                                              .copyWith(
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : currentTheme
                                                            .textColor,
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                fontSize: 12,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Personality Selection
                        Text(
                          'Personalidad',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              _personalityOptions.map((personality) {
                                final isSelected =
                                    _selectedPersonality == personality;
                                final details =
                                    _personalityDetails[personality]!;

                                // Calculate width for 3 columns (minus spacing)
                                final width =
                                    (MediaQuery.of(context).size.width -
                                        40 -
                                        40 -
                                        20) /
                                    3;

                                return GestureDetector(
                                  onTap:
                                      () => setState(
                                        () =>
                                            _selectedPersonality = personality,
                                      ),
                                  child: Container(
                                    width: width,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? currentTheme.primaryColor
                                              : currentTheme.cardColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? currentTheme.primaryColor
                                                : currentTheme.textColor
                                                    .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          details['emoji']!,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          details['label']!,
                                          textAlign: TextAlign.center,
                                          style: (currentFont.style ??
                                                  const TextStyle())
                                              .copyWith(
                                                fontSize: 12,
                                                color:
                                                    isSelected
                                                        ? Colors.white
                                                        : currentTheme
                                                            .textColor,
                                                fontWeight:
                                                    isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Considerations
                        Text(
                          'Consideraciones Especiales',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _considerationsController,
                          maxLines: 3,
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(color: currentTheme.textColor),
                          decoration: InputDecoration(
                            hintText:
                                'Ej: Evitar temas sensibles, ser muy paciente...',
                            hintStyle: TextStyle(
                              color: currentTheme.textColor.withOpacity(0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: currentTheme.textColor.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: currentTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // About Me
                        Text(
                          'Sobre Mí',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.textColor,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _aboutMeController,
                          maxLines: 3,
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(color: currentTheme.textColor),
                          decoration: InputDecoration(
                            hintText:
                                'Ej: Me gusta el arte, tengo ansiedad social...',
                            hintStyle: TextStyle(
                              color: currentTheme.textColor.withOpacity(0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: currentTheme.textColor.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: currentTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _deleteContext,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'Borrar memoria',
                                      style: (currentFont.style ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: currentTheme.textColor,
                                          ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : Text(
                                      'Guardar Cambios',
                                      style: (currentFont.style ??
                                              const TextStyle())
                                          .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
