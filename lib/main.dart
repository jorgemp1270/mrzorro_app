import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_menu_screen.dart';
import 'utils/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar la localización en español
  await initializeDateFormatting('es', null);
  runApp(const SoulCareApp());
}

class SoulCareApp extends StatelessWidget {
  const SoulCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoulCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.lavender,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lavender,
          primary: AppColors.lavender,
          secondary: AppColors.peach,
        ),
        useMaterial3: true,
      ),
      home: const InitialScreen(),
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
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (isFirstTime) {
      // Primera vez - mostrar splash
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else if (isLoggedIn) {
      // Ya inició sesión - ir al menú principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    } else {
      // Ya vio el splash pero no ha iniciado sesión
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
