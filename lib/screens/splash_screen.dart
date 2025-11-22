import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';

import 'login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return Scaffold(
          backgroundColor: const Color.fromARGB(255, 250, 244, 245),
          body: Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Image.asset(
                        'assets/images/fox-hola.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Expanded(flex: 3, child: SizedBox()),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 30,
                  ),
                  decoration: BoxDecoration(
                    color: currentTheme.backgroundColor.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// App Name
                      Text(
                        '',
                        style: (currentFont.style ?? const TextStyle())
                            .copyWith(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: currentTheme.primaryColor,
                            ),
                      ),

                      const SizedBox(height: 1),

                      Text(
                        'Tu compañero de bienestar emocional',
                        textAlign: TextAlign.center,
                        style: (currentFont.style ?? const TextStyle())
                            .copyWith(
                              fontSize: 16,
                              color: currentTheme.textColor,
                            ),
                      ),

                      const SizedBox(height: 30),

                      /// Botón "Iniciar Sesión"
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('first_time', false);

                            if (!context.mounted) return;

                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            'Iniciar Sesión',
                            style: (currentFont.style ?? const TextStyle())
                                .copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Registro
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Aún no tienes una cuenta? ',
                            style: (currentFont.style ?? const TextStyle())
                                .copyWith(
                                  color: currentTheme.textColor,
                                  fontSize: 14,
                                ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('first_time', false);

                              if (!context.mounted) return;

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder:
                                      (_) => const LoginScreen(initialTab: 1),
                                ),
                              );
                            },
                            child: Text(
                              'Regístrate',
                              style: (currentFont.style ?? const TextStyle())
                                  .copyWith(
                                    color: currentTheme.primaryColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
