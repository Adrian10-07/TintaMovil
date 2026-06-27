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
}