import 'package:shared_preferences/shared_preferences.dart';

/// Recuerda, por usuario, si ya pasó el CAPTCHA de entrada a Club — solo
/// se le pide la primera vez que entra, no cada vez.
class CaptchaGateService {
  static String _key(String userId) => 'club_captcha_passed_$userId';

  static Future<bool> hasPassed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId)) ?? false;
  }

  static Future<void> markPassed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId), true);
  }
}