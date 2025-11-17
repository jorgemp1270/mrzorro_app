import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import 'main_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  final int initialTab;

  const LoginScreen({super.key, this.initialTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Altura real (imagen 2:3) y recorte a 2/3 de la altura
    final imageHeight = (screenWidth * 3 / 2) * (2 / 3);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // -----------------------------------------------------
            //                    IMAGEN SUPERIOR
            // -----------------------------------------------------
            Transform.translate(
              offset: const Offset(
                0,
                -65,
              ), //  ←← AJUSTA AQUÍ: valor negativo = la imagen sube más
              child: SizedBox(
                width: double.infinity,
                height: imageHeight,
                child: Stack(
                  children: [
                    ClipRect(
                      child: SizedBox(
                        width: double.infinity,
                        height: imageHeight,
                        child: Image.asset(
                          'assets/images/fox.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // DIFUMINADO inferior suave
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: imageHeight * 0.35,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.10),
                                Colors.black.withOpacity(0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------
            //          CONTENEDOR PARA SWITCH + CONTENIDO
            // -----------------------------------------------------
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 0,
                ),
                child: Column(
                  children: [
                    // -----------------------------------------------------
                    //               SWITCH LOGIN / SIGN UP
                    // -----------------------------------------------------
                    Container(
                      height: 55,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.lavenderLight.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Stack(
                        children: [
                          // Indicador de fondo animado (switch)
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 230),
                            alignment:
                                _tabController.index == 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                            child: Container(
                              width:
                                  (MediaQuery.of(context).size.width - 64) / 2,
                              decoration: BoxDecoration(
                                color: AppColors.lavender,
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),

                          // TabBar sin bordes ni indicadores
                          TabBar(
                            controller: _tabController,
                            indicatorColor: Colors.transparent,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.textSecondary,
                            labelStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            tabs: const [
                              Tab(text: "Login"),
                              Tab(text: "Sign up"),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 0),

                    // -----------------------------------------------------
                    //                       CONTENIDO
                    // -----------------------------------------------------
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: const [LoginTab(), SignUpTab()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// =========================================================
//                      LOGIN TAB
// =========================================================
class LoginTab extends StatefulWidget {
  const LoginTab({super.key});

  @override
  State<LoginTab> createState() => _LoginTabState();
}

class _LoginTabState extends State<LoginTab> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', _emailController.text);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lavender.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Bienvenido a Soulcare',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lavender,
                  ),
                ),

                const SizedBox(height: 30),

                _inputField("Email", _emailController),
                const SizedBox(height: 20),

                _inputField("Password", _passwordController, obscure: true),
                const SizedBox(height: 40),

                _button("Log In", _login),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {},
                  child: Text(
                    '¿Olvidaste la contraseña?',
                    style: TextStyle(color: AppColors.lavender, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// =========================================================
//                      SIGN UP TAB
// =========================================================
class SignUpTab extends StatefulWidget {
  const SignUpTab({super.key});

  @override
  State<SignUpTab> createState() => _SignUpTabState();
}

class _SignUpTabState extends State<SignUpTab> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', _emailController.text);
    await prefs.setString('user_nickname', _nicknameController.text);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lavender.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Bienvenido a Soulcare',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lavender,
                  ),
                ),

                const SizedBox(height: 25),

                _inputField("Email", _emailController),
                const SizedBox(height: 15),

                _inputField("Password", _passwordController, obscure: true),
                const SizedBox(height: 15),

                _inputField(
                  "Repeat password",
                  _confirmController,
                  obscure: true,
                ),
                const SizedBox(height: 15),

                _inputField("Nickname", _nicknameController),
                const SizedBox(height: 30),

                _button("Create Account", _signUp),

                const SizedBox(height: 15),

                Text('Or', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.lavenderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

//
// =========================================================
//                  WIDGETS REUTILIZABLES
// =========================================================
Widget _inputField(
  String hint,
  TextEditingController controller, {
  bool obscure = false,
}) {
  return TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textLight),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.lavenderLight),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.lavender, width: 2),
      ),
    ),
  );
}

Widget _button(String text, VoidCallback onPressed) {
  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.lavender,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
