import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:mrzorro_app/screens/login_screen.dart';
import 'package:mrzorro_app/screens/shop_screen.dart';
import 'package:mrzorro_app/screens/customize_fox_screen.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'journal_screen.dart';

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
    const ShopScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final currentTheme = ThemeService().currentTheme;

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
              backgroundColor: currentTheme.cardColor,
              selectedItemColor: currentTheme.primaryColor,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.book_outlined),
                  activeIcon: Icon(Icons.book),
                  label: 'Diario',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_outlined),
                  activeIcon: Icon(Icons.shopping_bag),
                  label: 'Tienda',
                ),
              ],
            ),
          ),
        );
      },
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
  bool _crisisAlert = false;
  bool _isLoading = false;
  String _points = '';
  String? _currentUserId;
  static const int maxMessages =
      10; // Limit messages to prevent performance issues

  @override
  void initState() {
    super.initState();
    _refreshPhrases();
    _getCurrentUser().then((_) {
      _getUserPoints();
    });
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
    if (_currentUserId == null) return;

    try {
      final result = await ApiService.getUserPurchases(_currentUserId!);
      if (result['success'] == true && mounted) {
        setState(() {
          _points = (result['points'] ?? 0).toString();
        });
        print('User points loaded: $_points');
      } else {
        print('Error fetching user points: ${result['message']}');
        // Set default points if API call fails
        if (mounted) {
          setState(() {
            _points = '0';
          });
        }
      }
    } catch (e) {
      print('Exception fetching user points: $e');
      // Set default points if exception occurs
      if (mounted) {
        setState(() {
          _points = '0';
        });
      }
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
          final crisis_alert = responseData['crisis_alert'] ?? false;
          if (crisis_alert) {
            _crisisAlert = true;
            // Show crisis alert dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Alerta de crisis detectada: Por favor, contacta a la línea de la vida.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 30),
              ),
            );
          }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Cómo te sientes?',
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: currentTheme.primaryColor,
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
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _registerEmotion(emotion);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: currentTheme.primaryColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: (currentFont.style ?? const TextStyle()).copyWith(
                fontSize: 14,
                color: currentTheme.textColor,
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
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
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
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: currentTheme.primaryColor,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Refresh points when tapped
                              _getUserPoints();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Puntos actualizados: $_points',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: currentTheme.cardColor,
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
                                    _points.isNotEmpty ? '$_points' : '---',
                                    style: (currentFont.style ??
                                            const TextStyle())
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: currentTheme.textColor,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: currentTheme.primaryColor,
                            ),
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
                          today,
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                fontSize: 14,
                                color: currentTheme.textColor.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 10),
                        if (_currentUserId != null)
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CustomizeFoxScreen(
                                        userId: _currentUserId!,
                                      ),
                                ),
                              );
                            },
                            icon: const Text(
                              '🦊',
                              style: TextStyle(fontSize: 18),
                            ),
                            label: Text(
                              'Personalizar',
                              style: (currentFont.style ?? const TextStyle())
                                  .copyWith(
                                    color: currentTheme.textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              backgroundColor: currentTheme.primaryColor,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),

                        const SizedBox(height: 15),

                        // Messages
                        if (_messages.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: currentTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _currentUserId != null
                                  ? '¡Hola! Soy Mr. Zorro, tu compañero emocional. ¿Cómo te sientes hoy? Puedes contarme lo que quieras.'
                                  : 'Cargando...',
                              style: (currentFont.style ?? const TextStyle())
                                  .copyWith(
                                    color: currentTheme.textColor,
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
                                              ? currentTheme.primaryColor
                                                  .withOpacity(0.2)
                                              : currentTheme.primaryColor
                                                  .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      msg['content']!,
                                      style: (currentFont.style ??
                                              const TextStyle())
                                          .copyWith(
                                            color: currentTheme.textColor,
                                            fontSize: 15,
                                          ),
                                    ),
                                  ),
                                ),
                              )),

                        const SizedBox(height: 15),

                        if (_crisisAlert) ...[
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    'Por favor, contacta a la línea de la vida: 800 911 2000',
                                    style: (currentFont.style ??
                                            const TextStyle())
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () async {
                                    setState(() {
                                      _crisisAlert = false;
                                    });
                                    const number =
                                        '8009112000'; //set the number here
                                    await FlutterPhoneDirectCaller.callNumber(
                                      number,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.phone,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 15),

                        // Input field
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatController,
                                enabled: !_isLoading && _currentUserId != null,
                                maxLines: null,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: (currentFont.style ?? const TextStyle())
                                    .copyWith(color: currentTheme.textColor),
                                decoration: InputDecoration(
                                  hintText:
                                      _currentUserId != null
                                          ? 'Cuéntame cómo te sientes...'
                                          : 'Cargando...',
                                  hintStyle: (currentFont.style ??
                                          const TextStyle())
                                      .copyWith(
                                        color: currentTheme.textColor
                                            .withOpacity(0.5),
                                      ),
                                  filled: true,
                                  fillColor:
                                      _isLoading
                                          ? currentTheme.backgroundColor
                                              .withOpacity(0.5)
                                          : currentTheme.backgroundColor,
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
                                          color: currentTheme.primaryColor,
                                        ),
                                      )
                                      : Icon(
                                        Icons.send,
                                        color: currentTheme.primaryColor,
                                      ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    _isLoading
                                        ? currentTheme.primaryColor.withOpacity(
                                          0.1,
                                        )
                                        : currentTheme.primaryColor.withOpacity(
                                          0.2,
                                        ),
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
                        'assets/images/fox-hola.png',
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
                            color: currentTheme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: currentTheme.primaryColor.withOpacity(
                                  0.1,
                                ),
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
                                  color: currentTheme.secondaryColor
                                      .withOpacity(0.2),
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
                                  style: (currentFont.style ??
                                          const TextStyle())
                                      .copyWith(
                                        fontSize: 14,
                                        color: currentTheme.textColor,
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
      },
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
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: currentTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: (currentFont.style ?? const TextStyle()).copyWith(
                    fontSize: 11,
                    color: currentTheme.textColor,
                    fontWeight: FontWeight.w500,
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
