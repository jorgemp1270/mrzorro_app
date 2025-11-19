import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mrzorro_app/screens/login_screen.dart';
import 'package:mrzorro_app/services/auth_service.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

import 'journal_entry_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Datos de ejemplo
  int _entriesThisYear = 100;
  int _currentStreak = 15;

  final List<Map<String, dynamic>> _previousEntries = [
    {
      'date': '8 de Noviembre',
      'title': 'Día dos de universidad',
      'preview':
          '¡Hola diario! El día de hoy ha sido genial, tuve muchas clases, pero en todas me ha ido de forma extraordinaria...',
      'locked': true,
    },
    {
      'date': '7 de Noviembre',
      'title': 'Primer día increíble',
      'preview':
          'Hoy fue mi primer día en la universidad y conocí a muchas personas maravillosas...',
      'locked': true,
    },
  ];

  Future<bool> _authenticateUser() async {
    try {
      bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        // Si no hay biometría, mostrar diálogo de contraseña
        return await _showPasswordDialog();
      }

      bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Desbloquea para ver tu diario',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      return authenticated;
    } catch (e) {
      return await _showPasswordDialog();
    }
  }

  Future<bool> _showPasswordDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ingresa tu contraseña'),
            content: TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Aquí validarías la contraseña con tu backend
                  Navigator.pop(context, true);
                },
                child: const Text('Desbloquear'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _openEntry(Map<String, dynamic> entry) async {
    if (entry['locked'] == true) {
      bool authenticated = await _authenticateUser();
      if (!authenticated) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Autenticación fallida')));
        return;
      }
    }

    // Abrir entrada del diario
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Abriendo: ${entry['title']}')));
  }

  void _createNewEntry({String? prompt}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(initialPrompt: prompt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final todayPrompt =
        AppConstants.journalPrompts[random.nextInt(
          AppConstants.journalPrompts.length,
        )];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 244, 245),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Journal',
          style: TextStyle(
            color: AppColors.lavender,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout, color: AppColors.lavender),
            onPressed: () {
              AuthService.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '$_entriesThisYear',
                    label: 'Entradas Este Año',
                    color: AppColors.lavenderLight,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _StatCard(
                    value: '$_currentStreak',
                    label: 'Días de Racha',
                    color: AppColors.peach.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Today's Prompt Card
            GestureDetector(
              onTap: () => _createNewEntry(prompt: todayPrompt),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'EEEE, d \'de\' MMMM',
                              'es',
                            ).format(DateTime.now()),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            todayPrompt,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _createNewEntry(prompt: todayPrompt),
                      icon: Icon(Icons.refresh, color: AppColors.lavender),
                    ),
                    IconButton(
                      onPressed: () => _createNewEntry(prompt: todayPrompt),
                      icon: Icon(Icons.edit, color: AppColors.lavender),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Emotional Valence Chart
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
                    'Valencia Emocional',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Text('🦊', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade200,
                                Colors.purple.shade300,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Previous Entries Header
            Text(
              'Ayer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 15),

            // Previous Entries
            ..._previousEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: GestureDetector(
                  onTap: () => _openEntry(entry),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (entry['locked'] == true)
                              Icon(
                                Icons.lock,
                                color: AppColors.lavender,
                                size: 20,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry['preview'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry['date'],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
