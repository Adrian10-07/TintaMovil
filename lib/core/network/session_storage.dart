import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persiste los tokens de sesión CIFRADOS en el dispositivo (Android
/// Keystore / iOS Keychain vía flutter_secure_storage), no en texto
/// plano como antes.
///
/// Antes esto usaba SharedPreferences — que guarda todo en un XML/archivo
/// legible sin cifrar. Un atacante con acceso físico al dispositivo y
/// depuración USB (o un backup de ADB) podía leer el token directo. Con
/// flutter_secure_storage, Android cifra el valor con una llave que vive
/// en el Keystore del hardware (no es extraíble ni siquiera con root en
/// la mayoría de los dispositivos modernos); en iOS se guarda en el
/// Keychain del sistema, protegido igual.
class SessionStorage {
  static const _accessKey = 'session_access_token';
  static const _refreshKey = 'session_refresh_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Guarda los tokens tras un login/registro exitoso, cifrados.
  static Future<void> save({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  /// Regresa los tokens guardados, o null si no hay sesión activa.
  static Future<({String accessToken, String refreshToken})?> load() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return (accessToken: access, refreshToken: refresh);
  }

  /// Borra la sesión guardada (logout).
  static Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}