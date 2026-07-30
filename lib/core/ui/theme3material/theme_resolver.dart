import 'package:flutter/material.dart';

import '../../settings/app_settings_controller.dart';
import 'theme.dart';

/// Resuelve la `ThemeData` activa a partir de la preferencia del
/// usuario guardada en `AppSettingsController`.
///
/// Antes vivía como `switch` inline dentro del build de `TintaApp`,
/// creando una `MaterialTheme` nueva en cada rebuild y ocupando ~15
/// líneas del árbol. Aquí queda encapsulado y es trivial de testear.
class ThemeResolver {
  ThemeResolver._();

  /// Devuelve la `ThemeData` correspondiente a la opción elegida.
  ///
  /// Instancia `MaterialTheme` una sola vez por llamada — barato, pero
  /// evita crear varias en el mismo build si se llamara desde varios
  /// sitios.
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