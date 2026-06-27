import '../../../../core/network/http_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/data/models/user_model.dart';

/// DataSource remoto para operaciones de perfil de usuario.
///
/// Mismo servicio Identity que auth:
/// https://tintaapi-production-identity.up.railway.app
class UserRemoteDataSource {
  final ApiClient _apiClient;

  static const String _baseUrl =
      'https://tinta-identity.up.railway.app/api/v1';

  UserRemoteDataSource(this._apiClient);

  /// GET /users/me — Obtiene el perfil del usuario autenticado.
  Future<User> getProfile() async {
    final data = await _apiClient.get(
      '$_baseUrl/users/me',
      auth: true,
    );
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /users/me — Actualiza campos del perfil.
  ///
  /// Request (campos opcionales):
  /// { "name": "...", "avatar_url": "...", "language": "es" }
  ///
  /// El backend solo actualiza los campos que vengan en el body.
  Future<User> updateProfile({
    String? name,
    String? avatarUrl,
    String? language,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (language != null) 'language': language,
    };
    final data = await _apiClient.patch(
      '$_baseUrl/users/me',
      body: body,
    );
    return UserModel.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /users/me — Elimina la cuenta (204).
  Future<void> deleteAccount() async {
    await _apiClient.delete('$_baseUrl/users/me');
  }
}