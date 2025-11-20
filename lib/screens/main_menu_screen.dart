import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mrzorro_app/screens/login_screen.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'journal_screen.dart';
import 'camera_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeTab(),
    const JournalScreen(),
    const CameraScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.lavender,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              activeIcon: Icon(Icons.camera_alt),
              label: 'Camera',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _chatController = TextEditingController();
  String _currentPhrase = '';
  String _currentFoxPhrase = '';
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  String _points = '';
  String? _currentUserId;
  static const int maxMessages =
      10; // Limit messages to prevent performance issues

  @override
  void initState() {
    super.initState();
    _refreshPhrases();
    _getCurrentUser();
    _getUserPoints();
  }

  Future<void> _getCurrentUser() async {
    final userId = await AuthService.getCurrentUserId();
    setState(() {
      _currentUserId = userId;
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _refreshPhrases() {
    final random = Random();
    setState(() {
      _currentPhrase =
          AppConstants.motivationalPhrases[random.nextInt(
            AppConstants.motivationalPhrases.length,
          )];
      _currentFoxPhrase =
          AppConstants.foxPhrases[random.nextInt(
            AppConstants.foxPhrases.length,
          )];
    });
  }

  Future<void> _getUserPoints() async {
    final userInfo = await AuthService.getCurrentUserInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _points = userInfo['points'].toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty || _currentUserId == null) return;
    if (_isLoading) return;

    final userMessage = _chatController.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      // Keep only recent messages to prevent UI performance issues
      if (_messages.length > maxMessages) {
        _messages.removeRange(0, _messages.length - maxMessages);
      }
      _chatController.clear();
      _isLoading = true;
    });

    try {
      final result = await ApiService.generatePromptResponse(
        userId: _currentUserId!,
        prompt: userMessage,
      );

      // Debug: Print the response to understand its structure
      print('API Response: $result');

      setState(() {
        if (result['success']) {
          final responseData = result['response'];
          // Backend returns {user: "", response: ""} structure
          final aiResponse =
              responseData['response'] ??
              responseData['message'] ??
              'Lo siento, no pude generar una respuesta.';
          _messages.add({'role': 'assistant', 'content': aiResponse});
          // Keep only recent messages to prevent UI performance issues
          if (_messages.length > maxMessages) {
            _messages.removeRange(0, _messages.length - maxMessages);
          }
        } else {
          _messages.add({
            'role': 'assistant',
            'content':
                'Lo siento, hubo un error al procesar tu mensaje. ${result['message']}',
          });
          // Keep only recent messages to prevent UI performance issues
          if (_messages.length > maxMessages) {
            _messages.removeRange(0, _messages.length - maxMessages);
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Lo siento, hubo un error de conexión. Por favor intenta de nuevo.',
        });
        // Keep only recent messages to prevent UI performance issues
        if (_messages.length > maxMessages) {
          _messages.removeRange(0, _messages.length - maxMessages);
        }
        _isLoading = false;
      });
    }
  }

  void _registerEmotion(String emotion) async {
    if (_currentUserId == null) return;

    final emotionText = AppConstants.emotionsSpanish[emotion] ?? emotion;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emoción registrada: $emotionText'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Send emotion as a prompt to the AI for personalized response
    final emotionPrompt =
        'Me siento $emotionText hoy. ¿Podrías darme algunos consejos o palabras de aliento?';

    setState(() {
      _messages.add({'role': 'user', 'content': 'Me siento $emotionText hoy.'});
      // Keep only recent messages to prevent UI performance issues
      if (_messages.length > maxMessages) {
        _messages.removeRange(0, _messages.length - maxMessages);
      }
      _isLoading = true;
    });

    try {
      final result = await ApiService.generatePromptResponse(
        userId: _currentUserId!,
        prompt: emotionPrompt,
      );

      setState(() {
        if (result['success']) {
          final responseData = result['response'];
          final aiResponse =
              responseData['response'] ??
              'Entiendo cómo te sientes. Estoy aquí para apoyarte.';
          _messages.add({'role': 'assistant', 'content': aiResponse});
        } else {
          _messages.add({
            'role': 'assistant',
            'content':
                'Entiendo que te sientes $emotionText. Es normal sentir esto a veces.',
          });
        }
        // Keep only recent messages to prevent UI performance issues
        if (_messages.length > maxMessages) {
          _messages.removeRange(0, _messages.length - maxMessages);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Entiendo que te sientes $emotionText. Recuerda que es importante cuidar tu bienestar emocional.',
        });
        // Keep only recent messages to prevent UI performance issues
        if (_messages.length > maxMessages) {
          _messages.removeRange(0, _messages.length - maxMessages);
        }
        _isLoading = false;
      });
    }
  }

  void _showMoreEmotions() {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cómo te sientes?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lavender,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _EmotionChip('sad', '😢', 'Triste'),
                    _EmotionChip('angry', '😠', 'Enojado'),
                    _EmotionChip('excited', '🤩', 'Emocionado'),
                    _EmotionChip('tired', '😴', 'Cansado'),
                    _EmotionChip('confused', '😕', 'Confundido'),
                    _EmotionChip('grateful', '🙏', 'Agradecido'),
                    _EmotionChip('motivated', '💪', 'Motivado'),
                    _EmotionChip('peaceful', '😌', 'En paz'),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _EmotionChip(String emotion, String emoji, String label) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _registerEmotion(emotion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lavenderLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d \'de\' MMMM', 'es');
    final today = dateFormat.format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 244, 245),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _currentPhrase,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lavender,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap:
                            () => ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tus puntos se actualizarán la próxima vez que inicies sesión',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.apple,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$_points',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.logout, color: AppColors.lavender),
                        onPressed: () {
                          AuthService.logout();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Chat Card
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
                    Text(
                      today,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Messages
                    if (_messages.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.lavenderLight,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          _currentUserId != null
                              ? '¡Hola! Soy Mr. Zorro, tu compañero emocional. ¿Cómo te sientes hoy? Puedes contarme lo que quieras.'
                              : 'Cargando...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      )
                    else
                      ...(_messages.reversed
                          .take(3)
                          .toList()
                          .reversed
                          .map(
                            (msg) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color:
                                      msg['role'] == 'user'
                                          ? AppColors.lavender.withOpacity(0.2)
                                          : AppColors.lavenderLight,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Text(
                                  msg['content']!,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          )),

                    const SizedBox(height: 15),

                    // Input field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            enabled: !_isLoading && _currentUserId != null,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText:
                                  _currentUserId != null
                                      ? 'Cuéntame cómo te sientes...'
                                      : 'Cargando...',
                              hintStyle: TextStyle(color: AppColors.textLight),
                              filled: true,
                              fillColor:
                                  _isLoading
                                      ? AppColors.background.withOpacity(0.5)
                                      : AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: _isLoading ? null : _sendMessage,
                          icon:
                              _isLoading
                                  ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.lavender,
                                    ),
                                  )
                                  : Icon(Icons.send, color: AppColors.lavender),
                          style: IconButton.styleFrom(
                            backgroundColor:
                                _isLoading
                                    ? AppColors.lavenderLight.withOpacity(0.5)
                                    : AppColors.lavenderLight,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Emotion Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: _EmotionButton(
                      emoji: '😊',
                      label: 'Estoy Feliz',
                      onTap: () => _registerEmotion('happy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EmotionButton(
                      emoji: '😢',
                      label: 'Estoy Triste',
                      onTap: () => _registerEmotion('sad'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EmotionButton(
                      emoji: '🤔',
                      label: 'Otro',
                      onTap: () => _showMoreEmotions(),
                    ),
                  ),
                ],
              ),

              // 🦊 ========================================
              // 🦊 ZORRITO + FOX CARD INTEGRADOS
              // 🦊 ========================================
              const SizedBox(height: 10),

              Column(
                children: [
                  // Zorrito (arriba)
                  Image.asset(
                    'assets/images/hola.png',
                    width: double.infinity,
                    height: 250, // 🎯 AJUSTA LA ALTURA DEL ZORRITO AQUÍ
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  // 🎯 AJUSTA EL ESPACIO ENTRE EL ZORRITO Y LA CARD AQUÍ
                  // Fox Card (abajo)
                  GestureDetector(
                    onTap: _refreshPhrases,
                    child: Container(
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
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: AppColors.cream,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '💡',
                              style: TextStyle(fontSize: 30),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _currentFoxPhrase,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmotionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _EmotionButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.lavenderLight,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
