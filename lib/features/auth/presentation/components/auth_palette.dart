import 'package:flutter/material.dart';
import '../../../../core/ui/theme3material/theme.dart';

/// Paleta oscura compartida por login/register/forgot_password.
///
/// La agrupé aquí porque antes cada view redefinía las mismas constantes
/// (violación DRY) y cualquier cambio de color requería tocar 3 archivos.
/// Reuso los colores semánticos que ya viven en [MaterialTheme] (warmGold,
/// peach, coral) para no duplicarlos.
class AuthPalette {
  AuthPalette._();

  // Fondo cinematográfico — se usan puros negros y grises intencionalmente
  // porque el flujo de auth mantiene un tema fijo independientemente del
  // theme actual de la app.
  static const pureBlack = Color(0xFF000000);
  static const cardBlack = Color(0xFF121212);
  static const fieldBlack = Color(0xFF1C1C1E);
  static const lightText = Color(0xFFE8EAE6);
  static const mutedText = Color(0xFF9AA0A6);
  static const mintPrimary = Color(0xFF3DBF7A);

  // Reuso los acentos de MaterialTheme — así una sola fuente de verdad.
  static const Color warmGold = MaterialTheme.warmGold;
  static const Color peach = MaterialTheme.peach;
  static const Color coral = MaterialTheme.coral;
}
