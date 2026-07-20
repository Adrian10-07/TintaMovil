import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Temas disponibles en "Apariencia". "system" sigue el tema del
/// dispositivo (claro/oscuro); los demás son selección explícita.
enum AppThemeOption { light, dark, blue, superBlack }

extension AppThemeOptionLabel on AppThemeOption {
  String get label {
    switch (this) {
      case AppThemeOption.light:
        return 'Claro';
      case AppThemeOption.dark:
        return 'Oscuro';
      case AppThemeOption.blue:
        return 'Azul';
      case AppThemeOption.superBlack:
        return 'Súper negro';
    }
  }

  String get description {
    switch (this) {
      case AppThemeOption.light:
        return 'Fondo blanco, para ambientes con buena luz.';
      case AppThemeOption.dark:
        return 'Fondo oscuro estándar, cómodo de noche.';
      case AppThemeOption.blue:
        return 'Variante con acento azul en vez de verde.';
      case AppThemeOption.superBlack:
        return 'Negro puro con texto gris — máximo contraste, ideal para pantallas OLED y lectura nocturna larga.';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeOption.light:
        return Icons.light_mode_rounded;
      case AppThemeOption.dark:
        return Icons.dark_mode_rounded;
      case AppThemeOption.blue:
        return Icons.water_drop_rounded;
      case AppThemeOption.superBlack:
        return Icons.nights_stay_rounded;
    }
  }
}

/// Tamaños de texto disponibles, como multiplicador sobre el tamaño base.
enum AppTextSize { small, normal, large, extraLarge }

extension AppTextSizeValue on AppTextSize {
  double get scaleFactor {
    switch (this) {
      case AppTextSize.small:
        return 0.90;
      case AppTextSize.normal:
        return 1.0;
      case AppTextSize.large:
        return 1.15;
      case AppTextSize.extraLarge:
        return 1.30;
    }
  }

  String get label {
    switch (this) {
      case AppTextSize.small:
        return 'Pequeño';
      case AppTextSize.normal:
        return 'Normal';
      case AppTextSize.large:
        return 'Grande';
      case AppTextSize.extraLarge:
        return 'Muy grande';
    }
  }
}

/// Controla la apariencia global de la app (tema + tamaño de texto) y la
/// persiste en el dispositivo. Se instancia una sola vez en main.dart y
/// se escucha desde ahí para reconstruir el MaterialApp cuando cambie.
class AppSettingsController extends ChangeNotifier {
  static const _themeKey = 'app_theme_option';
  static const _textSizeKey = 'app_text_size';

  AppThemeOption _theme = AppThemeOption.light;
  AppThemeOption get theme => _theme;

  AppTextSize _textSize = AppTextSize.normal;
  AppTextSize get textSize => _textSize;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex < AppThemeOption.values.length) {
      _theme = AppThemeOption.values[themeIndex];
    }

    final sizeIndex = prefs.getInt(_textSizeKey);
    if (sizeIndex != null && sizeIndex < AppTextSize.values.length) {
      _textSize = AppTextSize.values[sizeIndex];
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> setTheme(AppThemeOption theme) async {
    _theme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  Future<void> setTextSize(AppTextSize size) async {
    _textSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_textSizeKey, size.index);
  }
}