import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda, por dispositivo, si el usuario ya aceptó el disclaimer legal
/// sobre el contenido de la app (libros de dominio público, modo local).
/// Se pregunta una sola vez — no depende del usuario que haya iniciado
/// sesión, es a nivel dispositivo/instalación.
class DisclaimerService {
  static const _key = 'legal_disclaimer_accepted';

  static Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}