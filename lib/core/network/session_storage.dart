import 'package:shared_preferences/shared_preferences.dart';

/// Persiste los tokens de sesión en el dispositivo para que el usuario
/// no tenga que iniciar sesión cada vez que abre la app.
class SessionStorage {
  static const _accessKey = 'session_access_token';
  static const _refreshKey = 'session_refresh_token';

  /// Guarda los tokens tras un login/registro exitoso.
  static Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
  }

  /// Regresa los tokens guardados, o null si no hay sesión activa.
  static Future<({String accessToken, String refreshToken})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_accessKey);
    final refresh = prefs.getString(_refreshKey);
    if (access == null || refresh == null) return null;
    return (accessToken: access, refreshToken: refresh);
  }

  /// Borra la sesión guardada (logout).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }
}