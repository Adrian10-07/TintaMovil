import '../../../../core/network/http_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/token_pair.dart';
import '../models/user_model.dart';
import '../models/token_pair_model.dart';

/// DataSource remoto para autenticación.
///
/// Apunta al servicio Identity de Tinta en Railway:
/// https://tintaapi-production-identity.up.railway.app
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  static const String _baseUrl =
      'https://tinta-identity.up.railway.app/api/v1';

  AuthRemoteDataSource(this._apiClient);

  /// POST /users — Registro de nuevo usuario.
  ///
  /// Request:  { "email", "password", "name", "language" }
  /// Response: UserResponse (201)
  Future<User> register({
    required String email,
    required String password,
    required String name,
    String language = 'es',
  }) async {
    final data = await _apiClient.post(
      '$_baseUrl/users',
      body: {
        'email': email,
        'password': password,
        'name': name,
        'language': language,
      },
    );
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /auth/login — Inicio de sesión.
  ///
  /// Request:  { "email", "password" }
  /// Response: { "access_token", "refresh_token", "token_type" }
  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post(
      '$_baseUrl/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return TokenPairModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /auth/refresh — Rota tokens.
  ///
  /// Request:  { "refresh_token" }
  /// Response: { "access_token", "refresh_token", "token_type" }
  Future<TokenPair> refreshToken(String refreshToken) async {
    final data = await _apiClient.post(
      '$_baseUrl/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return TokenPairModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /auth/logout — Revoca el refresh token.
  ///
  /// Request:  { "refresh_token" }
  /// Response: 204 No Content
  Future<void> logout(String refreshToken) async {
    await _apiClient.post(
      '$_baseUrl/auth/logout',
      body: {'refresh_token': refreshToken},
    );
  }

  /// POST /auth/password-reset/request — Pide un código de 6 dígitos
  /// para restablecer la contraseña.
  ///
  /// El backend siempre responde 200 (para no dar pistas de si el
  /// correo existe o no), pero incluye `code` en la respuesta solo si
  /// el correo sí es de una cuenta real — igual que el flujo de
  /// verificación de correo, esto es un respaldo mientras se confirma
  /// que el correo real (vía Brevo) llega bien.
  Future<String?> requestPasswordReset(String email) async {
    final data = await _apiClient.post(
      '$_baseUrl/auth/password-reset/request',
      body: {'email': email},
    );
    return (data as Map<String, dynamic>)['code'] as String?;
  }

  /// POST /auth/password-reset/confirm — Confirma el código y establece
  /// la nueva contraseña.
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _apiClient.post(
      '$_baseUrl/auth/password-reset/confirm',
      body: {
        'email': email,
        'code': code,
        'new_password': newPassword,
      },
    );
  }
}