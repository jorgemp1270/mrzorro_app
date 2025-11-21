import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mrzorro_app/screens/camera_screen.dart';
import 'package:mrzorro_app/screens/login_screen.dart';
import 'package:mrzorro_app/services/api_service.dart';
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

  String? _currentUserId = '';
  List<Map<String, dynamic>> _previousEntries = [];
  int _entriesThisYear = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  int _points = 0;
  bool _entriesLocked = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserData();
    await _getDiaryEntries(_currentUserId);
    await _getUserPoints(); // Add points fetching to initialization
  }

  /// Refresh all data after entry creation/modification
  Future<void> _refreshAllData() async {
    // Refresh diary entries
    await _getDiaryEntries(_currentUserId);

    // Refresh user stats (points, streaks, etc.)
    await _getUserData();

    // Refresh user points
    await _getUserPoints();

    // Force rebuild of UI
    if (mounted) {
      setState(() {
        // This will trigger recalculation of emotional averages and stats
      });
    }
  }

  Future<void> _getUserData() async {
    final userInfo = await AuthService.getCurrentUserInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _currentUserId = userInfo['user'];
        _currentStreak = userInfo['streak'] ?? 0;
        _bestStreak = userInfo['best_streak'] ?? 0;
      });
    }
  }

  Future<void> _getUserPoints() async {
    if (_currentUserId == null) return;

    try {
      final result = await ApiService.getUserPoints(_currentUserId!);
      if (result['success'] == true && mounted) {
        setState(() {
          _points = result['points'] ?? 0;
        });
        print('User points loaded: $_points');
      } else {
        print('Error fetching user points: ${result['message']}');
        // Set default points if API call fails
        if (mounted) {
          setState(() {
            _points = 0;
          });
        }
      }
    } catch (e) {
      print('Exception fetching user points: $e');
      // Set default points if exception occurs
      if (mounted) {
        setState(() {
          _points = 0;
        });
      }
    }
  }

  Future<void> _getDiaryEntries(String? userId) async {
    if (userId == null) return;

    try {
      final result = await ApiService.getDiaryEntries(userId);

      if (result['success'] == true) {
        print('Diary entries loaded: ${result['entries'].length}');
        if (mounted) {
          setState(() {
            _previousEntries = List<Map<String, dynamic>>.from(
              result['entries'],
            );
            // Sort entries by date (newest first)
            _previousEntries.sort((a, b) {
              final dateA = DateTime.parse(a['date']);
              final dateB = DateTime.parse(b['date']);
              return dateB.compareTo(dateA);
            });

            // Filter entries for current year only
            final currentYear = DateTime.now().year;
            final thisYearEntries =
                _previousEntries.where((entry) {
                  final entryDate = DateTime.parse(entry['date']);
                  return entryDate.year == currentYear;
                }).toList();

            _entriesThisYear = thisYearEntries.length;
          });
        }
      } else {
        print('Error fetching diary entries: ${result['message']}');
      }
    } catch (e) {
      print('Exception fetching diary entries: $e');
    }
  }

  /// Map emotions to numerical values (1-10 scale)
  Map<String, double> get _emotionValues => {
    'anxious': 2.0, // Negative emotion
    'sad': 2.5, // Negative emotion
    'angry': 1.5, // Most negative
    'tired': 3.0, // Slightly negative
    'confused': 3.5, // Neutral-negative
    'calm': 7.0, // Positive
    'happy': 8.5, // Very positive
    'excited': 9.0, // Very positive
    'grateful': 9.5, // Most positive
    'motivated': 8.0, // Positive
    'peaceful': 7.5, // Positive
  };

  /// Calculate average emotion for current month
  double _calculateCurrentMonthAverage() {
    if (_previousEntries.isEmpty) return 5.0; // Neutral if no entries

    final now = DateTime.now();
    final currentMonthKey = DateFormat('yyyy-MM').format(now);

    final currentMonthEntries =
        _previousEntries.where((entry) {
          final entryDate = DateTime.parse(entry['date']);
          final entryMonthKey = DateFormat('yyyy-MM').format(entryDate);
          return entryMonthKey == currentMonthKey;
        }).toList();

    if (currentMonthEntries.isEmpty) {
      // If no entries this month, use last month or overall average
      return _calculateOverallAverage();
    }

    double totalValue = 0.0;
    int validEntries = 0;

    for (final entry in currentMonthEntries) {
      final mood = entry['mood'] as String?;
      if (mood != null && _emotionValues.containsKey(mood)) {
        totalValue += _emotionValues[mood]!;
        validEntries++;
      }
    }

    return validEntries > 0 ? totalValue / validEntries : 5.0;
  }

  /// Calculate overall average emotion
  double _calculateOverallAverage() {
    if (_previousEntries.isEmpty) return 5.0;

    double totalValue = 0.0;
    int validEntries = 0;

    for (final entry in _previousEntries) {
      final mood = entry['mood'] as String?;
      if (mood != null && _emotionValues.containsKey(mood)) {
        totalValue += _emotionValues[mood]!;
        validEntries++;
      }
    }

    return validEntries > 0 ? totalValue / validEntries : 5.0;
  }

  // final List<Map<String, dynamic>> _previousEntries = [
  //   {
  //     'date': '8 de Noviembre',
  //     'title': 'Día dos de universidad',
  //     'preview':
  //         '¡Hola diario! El día de hoy ha sido genial, tuve muchas clases, pero en todas me ha ido de forma extraordinaria...',
  //     'locked': true,
  //   },
  //   {
  //     'date': '7 de Noviembre',
  //     'title': 'Primer día increíble',
  //     'preview':
  //         'Hoy fue mi primer día en la universidad y conocí a muchas personas maravillosas...',
  //     'locked': true,
  //   },
  // ];

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
    final password = await AuthService.getSavedCredentials().then(
      (creds) => creds['password'] ?? '',
    );
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
                onPressed: () async {
                  // Aquí validarías la contraseña con tu backend
                  if (controller.text == password) {
                    // Contraseña correcta
                    return Navigator.pop(context, true);
                  } else {
                    // Mostrar error
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contraseña incorrecta')),
                    );
                  }
                },
                child: const Text('Desbloquear'),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Future<void> _openEntry(Map<String, dynamic> entry) async {
    if (_entriesLocked) {
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

    _entriesLocked = false;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder:
            (_) => JournalEntryScreen(
              entry:
                  entry, // Pass the entire entry for proper mood highlighting
              aiAnalysis: entry['overview'],
            ),
      ),
    );

    // Refresh data if entry was modified
    if (result == true) {
      _refreshAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrada actualizada'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _createNewEntry({String? prompt}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => JournalEntryScreen(initialPrompt: prompt),
      ),
    );

    // Refresh data if new entry was created
    if (result == true) {
      _refreshAllData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nueva entrada creada'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
          GestureDetector(
            onTap: () {
              // Refresh points when tapped
              _getUserPoints();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Puntos actualizados: $_points'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
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
                  Text(
                    _points > 0 ? '$_points' : '---',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CameraScreen()),
          );

          // Refresh data if an entry was created from camera
          if (result == true) {
            _refreshAllData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nueva entrada creada desde cámara'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        backgroundColor: AppColors.lavender,
        child: const Icon(
          Icons.camera_alt_outlined,
          color: AppColors.textPrimary,
        ),
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

            SizedBox(
              width: double.infinity,
              child: _StatCard(
                value: '$_bestStreak',
                label: 'Mejor Racha',
                color: AppColors.cream,
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "Crea un recuerdo para hoy",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
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
                    // IconButton(
                    //   onPressed: () => _createNewEntry(prompt: todayPrompt),
                    //   icon: Icon(Icons.refresh, color: AppColors.lavender),
                    // ),
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
                    'Valencia emocional del mes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      // Sad emoji (left)
                      const Text('😢', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            // Background gradient bar
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade300,
                                    Colors.orange.shade300,
                                    Colors.yellow.shade300,
                                    Colors.green.shade300,
                                    Colors.blue.shade300,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            // Emotion indicator dot
                            Positioned(
                              left:
                                  (_calculateCurrentMonthAverage() - 1) *
                                  (MediaQuery.of(context).size.width - 140) /
                                  9,
                              top: 14,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.lavender,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Happy emoji (right)
                      const Text('🦊', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Average score display
                  Center(
                    child: Text(
                      'Promedio: ${_calculateCurrentMonthAverage().toStringAsFixed(1)}/10',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Previous Entries by Month
            ..._buildMonthlyEntries(),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupEntriesByMonth() {
    final groupedEntries = <String, List<Map<String, dynamic>>>{};

    for (final entry in _previousEntries) {
      final date = DateTime.parse(entry['date']);
      final monthKey = DateFormat('yyyy-MM', 'es').format(date);

      if (!groupedEntries.containsKey(monthKey)) {
        groupedEntries[monthKey] = [];
      }
      groupedEntries[monthKey]!.add(entry);
    }

    return groupedEntries;
  }

  List<Widget> _buildMonthlyEntries() {
    final groupedEntries = _groupEntriesByMonth();
    final widgets = <Widget>[];

    // Sort months by date (newest first)
    final sortedMonths =
        groupedEntries.keys.toList()..sort((a, b) => b.compareTo(a));

    for (final monthKey in sortedMonths) {
      final entries = groupedEntries[monthKey]!;
      final date = DateTime.parse('$monthKey-01');
      final monthName = DateFormat('MMMM', 'es').format(date);
      final year = DateFormat('yyyy').format(date);

      // Month Header with Year Container
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                monthName.substring(0, 1).toUpperCase() +
                    monthName.substring(1),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lavender.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  year,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // Month Entries
      for (final entry in entries) {
        widgets.add(
          Padding(
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
                        Expanded(
                          child: Text(
                            entry['title'] ?? "Sin título",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        _entriesLocked
                            ? Icon(
                              Icons.lock,
                              color: AppColors.lavender,
                              size: 20,
                            )
                            : Icon(
                              Icons.lock_open,
                              color: AppColors.lavender,
                              size: 20,
                            ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry['note'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat(
                        'd \'de\' MMMM',
                        'es',
                      ).format(DateTime.parse(entry['date'])),
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
        );
      }

      // Add spacing between months
      if (monthKey != sortedMonths.last) {
        widgets.add(const SizedBox(height: 20));
      }
    }

    return widgets;
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
