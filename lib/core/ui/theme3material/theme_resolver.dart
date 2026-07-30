import 'package:flutter/material.dart';

import '../../settings/app_settings_controller.dart';
import 'theme.dart';


class ThemeResolver {
  ThemeResolver._();

  /// Devuelve la `ThemeData` correspondiente a la opción elegida.
  /// Instancia `MaterialTheme` una sola vez por llamada
  static ThemeData resolve(AppThemeOption option) {
    final theme = MaterialTheme(MaterialTheme.tintaTextTheme);
    switch (option) {
      case AppThemeOption.light:
        return theme.light();
      case AppThemeOption.dark:
        return theme.dark();
      case AppThemeOption.blue:
        return theme.blue();
      case AppThemeOption.superBlack:
        return theme.superBlack();
    }
  }
}