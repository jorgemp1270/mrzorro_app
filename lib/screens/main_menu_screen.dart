import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshPhrases();
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

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;

    final userMessage = _chatController.text;
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _chatController.clear();
    });

    // Aquí conectarías con tu API de IA
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _messages.add({
        'role': 'assistant',
        'content':
            'Entiendo cómo te sientes. Estoy aquí para escucharte. ¿Quieres hablar más sobre eso?',
      });
    });
  }

  void _registerEmotion(String emotion) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Emoción registrada: ${AppConstants.emotionsSpanish[emotion]}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    // Aquí guardarías la emoción en tu backend
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
                      Container(
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
                            Icon(Icons.apple, color: Colors.red[700], size: 20),
                            const SizedBox(width: 5),
                            const Text(
                              '195',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.settings, color: AppColors.lavender),
                        onPressed: () {},
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
                          '¡Hola! Soy Foxito, ¿Cómo te sientes hoy?',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                          ),
                        ),
                      )
                    else
                      ...(_messages
                          .take(3)
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
                            decoration: InputDecoration(
                              hintText: 'Escribe algo...',
                              hintStyle: TextStyle(color: AppColors.textLight),
                              filled: true,
                              fillColor: AppColors.background,
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
                          onPressed: _sendMessage,
                          icon: Icon(Icons.send, color: AppColors.lavender),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.lavenderLight,
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
                children: [
                  _EmotionButton(
                    emoji: '😰',
                    label: 'Estoy Ansioso',
                    onTap: () => _registerEmotion('anxious'),
                  ),
                  _EmotionButton(
                    emoji: '😊',
                    label: 'Estoy Feliz',
                    onTap: () => _registerEmotion('happy'),
                  ),
                  _EmotionButton(
                    emoji: '🤔',
                    label: 'Otro',
                    onTap: () {
                      // Mostrar más emociones
                    },
                  ),
                ],
              ),

              // 🦊 ========================================
              // 🦊 ZORRITO + FOX CARD INTEGRADOS
              // 🦊 ========================================
              const SizedBox(height: 0),

              Column(
                children: [
                  // Zorrito (arriba)
                  Image.asset(
                    'assets/images/hola.png',
                    width: double.infinity,
                    height: 250, // 🎯 AJUSTA LA ALTURA DEL ZORRITO AQUÍ
                    fit: BoxFit.contain,
                  ),

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
