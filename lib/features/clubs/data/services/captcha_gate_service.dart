import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda, por usuario, si ya pasó el CAPTCHA de entrada a Club — solo
/// se le pide la primera vez que entra, no cada vez.
class CaptchaGateService {
  static String _key(String userId) => 'club_captcha_passed_$userId';

  /// Se incrementa cada vez que alguien pasa un CAPTCHA. Cualquier
  /// pantalla puede escuchar este notificador (ValueListenableBuilder)
  /// para enterarse al instante, sin importar si el cambio pasó en un
  /// tab distinto dentro de un IndexedStack (que no dispara rutas) o en
  /// una pantalla empujada con Navigator.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<bool> hasPassed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId)) ?? false;
  }

  static Future<void> markPassed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId), true);
    changes.value++; // avisa a quien esté escuchando
  }
}