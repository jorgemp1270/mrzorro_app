import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/app_theme.dart';
import '../models/app_font.dart';
import 'package:mrzorro_app/screens/login_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int _userPoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = await AuthService.getCurrentUserId();
    if (userId != null) {
      final result = await ApiService.getUserPurchases(userId);
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _userPoints = result['points'];
            _isLoading = false;
          });
          // Update purchased themes and fonts in ThemeService
          ThemeService().updatePurchasedItems(
            themes: result['themes'],
            fonts: result['fonts'],
          );
        }
      }
    }
  }

  Future<void> _purchaseTheme(AppTheme theme) async {
    if (_userPoints < theme.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes puntos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ThemeService().purchaseTheme(theme.id);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tema "${theme.name}" comprado con éxito')),
        );
        _loadUserData(); // Refresh points and themes
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al comprar el tema'),
          ),
        );
      }
    }
  }

  Future<void> _purchaseFont(AppFont font) async {
    if (_userPoints < font.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes suficientes puntos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ThemeService().purchaseFont(font.id);

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fuente "${font.name}" comprada con éxito')),
        );
        _loadUserData(); // Refresh points and fonts
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al comprar la fuente'),
          ),
        );
      }
    }
  }

  void _equipTheme(String themeId) {
    ThemeService().setTheme(themeId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Tema aplicado')));
  }

  void _equipFont(String fontId) {
    ThemeService().setFont(fontId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fuente aplicada')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, child) {
        final themeService = ThemeService();
        final currentTheme = themeService.currentTheme;
        final currentFont = themeService.currentFont;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: currentTheme.backgroundColor,
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 370.0,
                    floating: false,
                    pinned: true,
                    backgroundColor: currentTheme.backgroundColor,
                    elevation: 0,
                    title: Column(
                      children: [
                        Text(
                          'Tienda',
                          style: (currentFont.style ?? const TextStyle())
                              .copyWith(
                                color: currentTheme.primaryColor,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),

                    actions: [
                      GestureDetector(
                        onTap: () {
                          _loadUserData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Puntos actualizados: $_userPoints',
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
                                _isLoading ? '...' : '$_userPoints',
                                style: (currentFont.style ?? const TextStyle())
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: currentTheme.textColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.logout,
                          color: currentTheme.primaryColor,
                        ),
                        onPressed: () async {
                          await AuthService.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        margin: const EdgeInsets.only(
                          top: 120,
                          left: 20,
                          right: 20,
                          bottom: 70,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              currentTheme.primaryColor,
                              currentTheme.secondaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: currentTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.stars_rounded,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '¡Personaliza tu App!',
                                        style: (currentFont.style ??
                                                const TextStyle())
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Canjea tus puntos por temas y fuentes',
                                        style: (currentFont.style ??
                                                const TextStyle())
                                            .copyWith(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildEarningMethod(
                                    icon: Icons.login,
                                    points: '+1',
                                    label: 'Login Diario',
                                    currentFont: currentFont,
                                  ),
                                  Container(
                                    width: 1,
                                    height: 30,
                                    color: Colors.white24,
                                  ),
                                  _buildEarningMethod(
                                    icon: Icons.edit_note,
                                    points: '+5',
                                    label: 'Nuevo Diario',
                                    currentFont: currentFont,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    bottom: TabBar(
                      labelColor: currentTheme.primaryColor,
                      unselectedLabelColor: currentTheme.textColor.withOpacity(
                        0.6,
                      ),
                      indicatorColor: currentTheme.primaryColor,
                      labelStyle: (currentFont.style ?? const TextStyle())
                          .copyWith(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Temas', icon: Icon(Icons.brush_outlined)),
                        Tab(
                          text: 'Fuentes',
                          icon: Icon(Icons.font_download_outlined),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  // Themes List
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: themeService.themes.length,
                    itemBuilder: (context, index) {
                      final theme = themeService.themes[index];
                      final isPurchased = themeService.purchasedThemes.contains(
                        theme.id,
                      );
                      final isEquipped =
                          themeService.currentThemeId == theme.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                          border:
                              isEquipped
                                  ? Border.all(
                                    color: currentTheme.primaryColor,
                                    width: 2,
                                  )
                                  : null,
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: theme.backgroundColor,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.secondaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        theme.name,
                                        style: (currentFont.style ??
                                                const TextStyle())
                                            .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: currentTheme.textColor,
                                            ),
                                      ),
                                      if (!isPurchased)
                                        Text(
                                          '${theme.price} puntos',
                                          style: (currentFont.style ??
                                                  const TextStyle())
                                              .copyWith(
                                                color: currentTheme.textColor
                                                    .withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                    ],
                                  ),
                                  if (isEquipped)
                                    ElevatedButton.icon(
                                      onPressed: null,
                                      icon: const Icon(Icons.check),
                                      label: Text(
                                        'Equipado',
                                        style:
                                            (currentFont.style ??
                                                const TextStyle()),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        disabledBackgroundColor: Colors.green
                                            .withOpacity(0.2),
                                        disabledForegroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                    )
                                  else if (isPurchased)
                                    ElevatedButton(
                                      onPressed: () => _equipTheme(theme.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            currentTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Equipar',
                                        style:
                                            (currentFont.style ??
                                                const TextStyle()),
                                      ),
                                    )
                                  else
                                    ElevatedButton(
                                      onPressed:
                                          _userPoints >= theme.price
                                              ? () => _purchaseTheme(theme)
                                              : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Comprar',
                                        style:
                                            (currentFont.style ??
                                                const TextStyle()),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Fonts List
                  ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: themeService.fonts.length,
                    itemBuilder: (context, index) {
                      final font = themeService.fonts[index];
                      final isPurchased = themeService.purchasedFonts.contains(
                        font.id,
                      );
                      final isEquipped = themeService.currentFontId == font.id;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                          border:
                              isEquipped
                                  ? Border.all(
                                    color: currentTheme.primaryColor,
                                    width: 2,
                                  )
                                  : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      font.name,
                                      style: (font.style ?? const TextStyle())
                                          .copyWith(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: currentTheme.textColor,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'El veloz zorro marrón salta sobre el perro perezoso.',
                                      style: (font.style ?? const TextStyle())
                                          .copyWith(
                                            fontSize: 14,
                                            color: currentTheme.textColor
                                                .withOpacity(0.8),
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (!isPurchased)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          '${font.price} puntos',
                                          style: (currentFont.style ??
                                                  const TextStyle())
                                              .copyWith(
                                                color: currentTheme.textColor
                                                    .withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              if (isEquipped)
                                ElevatedButton.icon(
                                  onPressed: null,
                                  icon: const Icon(Icons.check),
                                  label: Text(
                                    'Equipado',
                                    style:
                                        (currentFont.style ??
                                            const TextStyle()),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    disabledBackgroundColor: Colors.green
                                        .withOpacity(0.2),
                                    disabledForegroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                )
                              else if (isPurchased)
                                ElevatedButton(
                                  onPressed: () => _equipFont(font.id),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: currentTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Equipar',
                                    style:
                                        (currentFont.style ??
                                            const TextStyle()),
                                  ),
                                )
                              else
                                ElevatedButton(
                                  onPressed:
                                      _userPoints >= font.price
                                          ? () => _purchaseFont(font)
                                          : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Comprar',
                                    style:
                                        (currentFont.style ??
                                            const TextStyle()),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningMethod({
    required IconData icon,
    required String points,
    required String label,
    required AppFont currentFont,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 5),
            Text(
              points,
              style: (currentFont.style ?? const TextStyle()).copyWith(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: (currentFont.style ?? const TextStyle()).copyWith(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
