import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar la localización en español
  await initializeDateFormatting('es', null);

  // Initialize ThemeService
  await ThemeService().init();

  runApp(const SoulCareApp());
}

class SoulCareApp extends StatelessWidget {
  const SoulCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final currentTheme = ThemeService().currentTheme;
        return MaterialApp(
          title: 'Mr. Zorro',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: currentTheme.primaryColor,
            scaffoldBackgroundColor: currentTheme.backgroundColor,
            cardColor: currentTheme.cardColor,
            textTheme: GoogleFonts.poppinsTextTheme().apply(
              bodyColor: currentTheme.textColor,
              displayColor: currentTheme.textColor,
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: currentTheme.primaryColor,
              primary: currentTheme.primaryColor,
              secondary: currentTheme.secondaryColor,
              background: currentTheme.backgroundColor,
              surface: currentTheme.cardColor,
              brightness:
                  currentTheme.isDark ? Brightness.dark : Brightness.light,
            ),
            useMaterial3: true,
            appBarTheme: AppBarTheme(
              backgroundColor: currentTheme.backgroundColor,
              foregroundColor: currentTheme.textColor,
            ),
          ),
          home: const InitialScreen(),
        );
      },
    );
  }
}

// Pantalla que decide si mostrar splash o login
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('first_time') ?? true;

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isFirstTime) {
      // Primera vez - mostrar splash
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else {
      // Check if user has saved credentials and try auto-login
      final result = await AuthService.autoLogin();

      if (result['success']) {
        // Auto-login successful - go to main menu
        await prefs.setBool('is_logged_in', true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      } else {
        // No saved credentials or auto-login failed - go to login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí puedes poner un loading o el logo
            Image.asset('assets/images/fox.png', width: 150, height: 150),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.lavender),
          ],
        ),
      ),
    );
  }
}
