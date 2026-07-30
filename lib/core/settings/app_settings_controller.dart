import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idioma de la interfaz. Independiente del "language"

enum AppLanguage { es, en }

extension AppLanguageLabel on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.es:
        return 'Español';
      case AppLanguage.en:
        return 'English';
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.es:
        return 'es';
      case AppLanguage.en:
        return 'en';
    }
  }
}

/// Temas disponibles en "Apariencia". "system" sigue el tema del
/// dispositivo (claro/oscuro); los demás son selección explícita.
enum AppThemeOption { light, dark, blue, superBlack }

extension AppThemeOptionLabel on AppThemeOption {
  String label(AppLanguage lang) {
    final es = lang == AppLanguage.es;
    switch (this) {
      case AppThemeOption.light:
        return es ? 'Claro' : 'Light';
      case AppThemeOption.dark:
        return es ? 'Oscuro' : 'Dark';
      case AppThemeOption.blue:
        return es ? 'Azul' : 'Blue';
      case AppThemeOption.superBlack:
        return es ? 'Súper negro' : 'Super black';
    }
  }

  String description(AppLanguage lang) {
    final es = lang == AppLanguage.es;
    switch (this) {
      case AppThemeOption.light:
        return es
            ? 'Fondo blanco, para ambientes con buena luz.'
            : 'White background, for well-lit environments.';
      case AppThemeOption.dark:
        return es
            ? 'Fondo oscuro estándar, cómodo de noche.'
            : 'Standard dark background, comfortable at night.';
      case AppThemeOption.blue:
        return es
            ? 'Variante con acento azul en vez de verde.'
            : 'Variant with a blue accent instead of green.';
      case AppThemeOption.superBlack:
        return es
            ? 'Negro puro con texto gris — máximo contraste, ideal para pantallas OLED y lectura nocturna larga.'
            : 'Pure black with gray text — maximum contrast, ideal for OLED screens and long night reading.';
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

  String label(AppLanguage lang) {
    final es = lang == AppLanguage.es;
    switch (this) {
      case AppTextSize.small:
        return es ? 'Pequeño' : 'Small';
      case AppTextSize.normal:
        return es ? 'Normal' : 'Normal';
      case AppTextSize.large:
        return es ? 'Grande' : 'Large';
      case AppTextSize.extraLarge:
        return es ? 'Muy grande' : 'Extra large';
    }
  }
}

/// Controla la apariencia global de la app (tema + tamaño de texto) y la
/// persiste en el dispositivo. Se instancia una sola vez en main.dart y
/// se escucha desde ahí para reconstruir el MaterialApp cuando cambie.
class AppSettingsController extends ChangeNotifier {
  static const _themeKey = 'app_theme_option';
  static const _textSizeKey = 'app_text_size';
  static const _languageKey = 'app_language';

  AppThemeOption _theme = AppThemeOption.light;
  AppThemeOption get theme => _theme;

  AppTextSize _textSize = AppTextSize.normal;
  AppTextSize get textSize => _textSize;

  AppLanguage _language = AppLanguage.es;
  AppLanguage get language => _language;

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

    final langIndex = prefs.getInt(_languageKey);
    if (langIndex != null && langIndex < AppLanguage.values.length) {
      _language = AppLanguage.values[langIndex];
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

  Future<void> setLanguage(AppLanguage language) async {
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, language.index);
  }
}