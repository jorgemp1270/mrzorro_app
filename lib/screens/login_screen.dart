import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/theme_service.dart';
import '../utils/validation_utils.dart';
import '../services/auth_service.dart';
import 'main_menu_screen.dart';
import 'api_test_screen.dart';

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
    final themeService = ThemeService();

    // Altura real (imagen 2:3) y recorte a 2/3 de la altura
    final imageHeight = (screenWidth * 3 / 2) * (2 / 3);

    return ListenableBuilder(
      listenable: themeService,
      builder: (context, child) {
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return Scaffold(
          backgroundColor: currentTheme.backgroundColor,
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
                            color: currentTheme.primaryColor.withOpacity(0.25),
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
                                      (MediaQuery.of(context).size.width - 64) /
                                      2,
                                  decoration: BoxDecoration(
                                    color: currentTheme.primaryColor,
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
                                unselectedLabelColor: currentTheme.textColor,
                                labelStyle: (currentFont.style ??
                                        const TextStyle())
                                    .copyWith(
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
      },
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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _saveCredentials = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _autoLogin() async {
    // Try to get saved credentials and auto-login
    final credentials = await AuthService.getSavedCredentials();
    if (credentials['email'] != null && credentials['password'] != null) {
      _emailController.text = credentials['email']!;
      _passwordController.text = credentials['password']!;
      _saveCredentials = credentials['shouldSave'] == 'true';

      if (_saveCredentials) {
        // Attempt auto-login if credentials should be saved
        setState(() => _isLoading = true);
        final result = await AuthService.autoLogin();
        setState(() => _isLoading = false);

        if (result['success'] && mounted) {
          await _navigateToMainMenu();
        }
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _emailError = ValidationUtils.getEmailError(_emailController.text.trim());
      _passwordError = ValidationUtils.getPasswordError(
        _passwordController.text,
      );
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (_saveCredentials) {
        await AuthService.saveCredentials(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await AuthService.clearCredentials();
      }

      await _navigateToMainMenu();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _navigateToMainMenu() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: currentTheme.cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Bienvenido a Mr. Zorro',
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: currentTheme.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _inputField(
                    "Email",
                    _emailController,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 20),

                  _inputField(
                    "Password",
                    _passwordController,
                    obscure: true,
                    errorText: _passwordError,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 20),

                  // Save credentials option
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Guardar mis datos para iniciar sesión automáticamente',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.textColor,
                                fontSize: 14,
                              ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: _saveCredentials,
                        onChanged: (value) {
                          setState(() => _saveCredentials = value);
                        },
                        activeColor: currentTheme.primaryColor,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _button(
                    "Log In",
                    _login,
                    isLoading: _isLoading,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {},
                    child: Text(
                      '¿Olvidaste la contraseña?',
                      style: (currentFont.style ?? const TextStyle()).copyWith(
                        color: currentTheme.primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  // Debug button for API testing (remove in production)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApiTestScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Test API Connection (Debug)',
                      style: (currentFont.style ?? const TextStyle()).copyWith(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _nicknameError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _emailError = ValidationUtils.getEmailError(_emailController.text.trim());
      _passwordError = ValidationUtils.getPasswordError(
        _passwordController.text,
      );
      _confirmError = ValidationUtils.getPasswordConfirmationError(
        _passwordController.text,
        _confirmController.text,
      );
      _nicknameError = ValidationUtils.getNicknameError(
        _nicknameController.text.trim(),
      );
    });

    if (_emailError != null ||
        _passwordError != null ||
        _confirmError != null ||
        _nicknameError != null) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.signUp(
      _emailController.text.trim(),
      _passwordController.text,
      _nicknameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      await AuthService.saveCredentials(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green.shade400,
          ),
        );

        // After successful signup, try to login
        await _autoLoginAfterSignup();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  Future<void> _autoLoginAfterSignup() async {
    final loginResult = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (loginResult['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final currentTheme = themeService.currentTheme;
    final currentFont = themeService.currentFont;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: currentTheme.cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: currentTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Bienvenido a Mr. Zorro',
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: currentTheme.primaryColor,
                    ),
                  ),

                  const SizedBox(height: 25),

                  _inputField(
                    "Email",
                    _emailController,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 15),

                  _inputField(
                    "Password",
                    _passwordController,
                    obscure: true,
                    errorText: _passwordError,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 15),

                  _inputField(
                    "Repeat password",
                    _confirmController,
                    obscure: true,
                    errorText: _confirmError,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 15),

                  _inputField(
                    "Nickname",
                    _nicknameController,
                    errorText: _nicknameError,
                    themeService: themeService,
                  ),
                  const SizedBox(height: 30),

                  _button(
                    "Create Account",
                    _signUp,
                    isLoading: _isLoading,
                    themeService: themeService,
                  ),

                  const SizedBox(height: 15),

                  Text(
                    'Or',
                    style: (currentFont.style ?? const TextStyle()).copyWith(
                      color: currentTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(
                        'Continue with Google',
                        style: (currentFont.style ?? const TextStyle()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: currentTheme.textColor,
                        side: BorderSide(
                          color: currentTheme.primaryColor.withOpacity(0.5),
                        ),
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
  String? errorText,
  TextInputType? keyboardType,
  required ThemeService themeService,
}) {
  final currentTheme = themeService.currentTheme;
  final currentFont = themeService.currentFont;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: (currentFont.style ?? const TextStyle()).copyWith(
          color: currentTheme.textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: (currentFont.style ?? const TextStyle()).copyWith(
            color: currentTheme.textColor.withOpacity(0.5),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color:
                  errorText != null
                      ? Colors.red
                      : currentTheme.primaryColor.withOpacity(0.5),
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: errorText != null ? Colors.red : currentTheme.primaryColor,
              width: 2,
            ),
          ),
          errorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
      if (errorText != null) ...[
        const SizedBox(height: 5),
        Text(
          errorText,
          style: (currentFont.style ?? const TextStyle()).copyWith(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ],
  );
}

Widget _button(
  String text,
  VoidCallback? onPressed, {
  bool isLoading = false,
  required ThemeService themeService,
}) {
  final currentTheme = themeService.currentTheme;
  final currentFont = themeService.currentFont;

  return SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: currentTheme.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        disabledBackgroundColor: currentTheme.primaryColor.withOpacity(0.6),
      ),
      child:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : Text(
                text,
                style: (currentFont.style ?? const TextStyle()).copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
    ),
  );
}
