import 'package:shared_preferences/shared_preferences.dart';

/// Controla qué tipos de notificación in-app quiere recibir el usuario.
/// Se consulta antes de crear cada notificación en StreakService y
/// UploadBookViewModel — si el tipo está apagado, simplemente no se crea.
class NotificationSettingsService {
  static String _key(String userId, String type) =>
      'notif_pref_${userId}_$type';

  /// Por defecto todo está activado.
  static Future<bool> isEnabled(String userId, String type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId, type)) ?? true;
  }

  static Future<void> setEnabled(String userId, String type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId, type), enabled);
  }
}