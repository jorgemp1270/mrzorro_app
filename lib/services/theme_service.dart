import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_theme.dart';
import '../models/app_font.dart';
import '../utils/colors.dart';
import 'auth_service.dart';
import 'api_service.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  String _currentThemeId = 'default';
  String _currentFontId = 'default';
  Set<String> _purchasedThemes = {'default'};
  Set<String> _purchasedFonts = {'default'};

  // Define fonts
  final List<AppFont> _fonts = [
    AppFont(
      id: 'default',
      name: 'Poppins',
      price: 0,
      style: null, // Uses system default
    ),
    AppFont(id: 'lato', name: 'Lato', price: 50, style: GoogleFonts.lato()),
    AppFont(
      id: 'opensans',
      name: 'Open Sans',
      price: 50,
      style: GoogleFonts.openSans(),
    ),
    AppFont(
      id: 'montserrat',
      name: 'Montserrat',
      price: 60,
      style: GoogleFonts.montserrat(),
    ),
    AppFont(
      id: 'oswald',
      name: 'Oswald',
      price: 60,
      style: GoogleFonts.oswald(),
    ),
    AppFont(
      id: 'raleway',
      name: 'Raleway',
      price: 70,
      style: GoogleFonts.raleway(),
    ),
    AppFont(
      id: 'merriweather',
      name: 'Merriweather',
      price: 80,
      style: GoogleFonts.merriweather(),
    ),
    AppFont(
      id: 'playfair',
      name: 'Playfair Display',
      price: 80,
      style: GoogleFonts.playfairDisplay(),
    ),
  ];

  // Define themes
  final List<AppTheme> _themes = [
    AppTheme(
      id: 'default',
      name: 'Estándar',
      price: 0,
      primaryColor: AppColors.lavender,
      secondaryColor: AppColors.peach,
      backgroundColor: AppColors.background,
      cardColor: AppColors.cardBackground,
      textColor: AppColors.textPrimary,
    ),
    AppTheme(
      id: 'dark',
      name: 'Oscuro',
      price: 20,
      primaryColor: Color(0xFF7E57C2),
      secondaryColor: Color(0xFF512DA8),
      backgroundColor: Color(0xFF121212),
      cardColor: Color(0xFF1E1E1E),
      textColor: Colors.white,
      isDark: true,
    ),
    AppTheme(
      id: 'fox',
      name: 'Mr. Zorro',
      price: 50,
      primaryColor: AppColors.foxOrange,
      secondaryColor: AppColors.foxBorder,
      backgroundColor: Colors.white,
      cardColor: Color(0xFFFFF3E0),
      textColor: Color(0xFF5D4037),
    ),
    AppTheme(
      id: 'ocean',
      name: 'Océano',
      price: 80,
      primaryColor: Color(0xFF4FC3F7),
      secondaryColor: Color(0xFF0288D1),
      backgroundColor: Color(0xFFE1F5FE),
      cardColor: Colors.white,
      textColor: Color(0xFF01579B),
    ),
    AppTheme(
      id: 'forest',
      name: 'Bosque',
      price: 100,
      primaryColor: Color(0xFF66BB6A),
      secondaryColor: Color(0xFF388E3C),
      backgroundColor: Color(0xFFE8F5E9),
      cardColor: Colors.white,
      textColor: Color(0xFF1B5E20),
    ),
    AppTheme(
      id: 'sunset',
      name: 'Atardecer',
      price: 120,
      primaryColor: Color(0xFFFF7043),
      secondaryColor: Color(0xFFD84315),
      backgroundColor: Color(0xFFFFF3E0),
      cardColor: Colors.white,
      textColor: Color(0xFFBF360C),
    ),
    AppTheme(
      id: 'galaxy',
      name: 'Galaxia',
      price: 150,
      primaryColor: Color(0xFF9C27B0),
      secondaryColor: Color(0xFF7B1FA2),
      backgroundColor: Color(0xFF311B92),
      cardColor: Color(0xFF4527A0),
      textColor: Colors.white,
      isDark: true,
    ),
  ];

  List<AppTheme> get themes => _themes;
  List<AppFont> get fonts => _fonts;

  String get currentThemeId => _currentThemeId;
  String get currentFontId => _currentFontId;

  AppTheme get currentTheme => _themes.firstWhere(
    (t) => t.id == _currentThemeId,
    orElse: () => _themes[0],
  );

  AppFont get currentFont =>
      _fonts.firstWhere((f) => f.id == _currentFontId, orElse: () => _fonts[0]);

  Set<String> get purchasedThemes => _purchasedThemes;
  Set<String> get purchasedFonts => _purchasedFonts;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeId = prefs.getString('current_theme') ?? 'default';
    _currentFontId = prefs.getString('current_font') ?? 'default';
    await loadPurchasedItems();
    notifyListeners();
  }

  Future<void> loadPurchasedItems() async {
    final userData = await AuthService.getSavedUserData();
    if (userData != null) {
      if (userData['themes'] != null) {
        final List<dynamic> themesList = userData['themes'];
        _purchasedThemes = {'default', ...themesList.map((e) => e.toString())};
      }
      if (userData['fonts'] != null) {
        final List<dynamic> fontsList = userData['fonts'];
        _purchasedFonts = {'default', ...fontsList.map((e) => e.toString())};
      }
    } else {
      _purchasedThemes = {'default'};
      _purchasedFonts = {'default'};
    }
    notifyListeners();
  }

  Future<void> setTheme(String themeId) async {
    if (_purchasedThemes.contains(themeId)) {
      _currentThemeId = themeId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_theme', themeId);
      notifyListeners();
    }
  }

  Future<void> setFont(String fontId) async {
    if (_purchasedFonts.contains(fontId)) {
      _currentFontId = fontId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_font', fontId);
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> purchaseTheme(String themeId) async {
    final theme = _themes.firstWhere((t) => t.id == themeId);
    final userId = await AuthService.getCurrentUserId();

    if (userId == null)
      return {'success': false, 'message': 'Usuario no identificado'};

    final result = await ApiService.makePurchase(
      userId: userId,
      price: theme.price.toString(),
      theme: themeId,
      font: null,
    );

    if (result['success'] == true) {
      _purchasedThemes.add(themeId);
      await loadPurchasedItems();
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> purchaseFont(String fontId) async {
    final font = _fonts.firstWhere((f) => f.id == fontId);
    final userId = await AuthService.getCurrentUserId();

    if (userId == null)
      return {'success': false, 'message': 'Usuario no identificado'};

    final result = await ApiService.makePurchase(
      userId: userId,
      price: font.price.toString(),
      theme: null,
      font: fontId,
    );

    if (result['success'] == true) {
      _purchasedFonts.add(fontId);
      await loadPurchasedItems();
      notifyListeners();
    }
    return result;
  }

  void updatePurchasedItems({List<dynamic>? themes, List<dynamic>? fonts}) {
    if (themes != null) {
      _purchasedThemes = {'default', ...themes.map((e) => e.toString())};
    }
    if (fonts != null) {
      _purchasedFonts = {'default', ...fonts.map((e) => e.toString())};
    }
    notifyListeners();
  }
}
