import '../../../../core/network/http_client.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/data/models/user_model.dart';

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

  /// POST /auth/verification/request — Pide al backend generar un código
  /// de verificación de 6 dígitos y lo asocia al usuario autenticado.
  ///
  /// El backend responde { message, code, expires_at }. El campo `code`
  /// sigue viniendo como respaldo por si el correo tarda, aunque ya se
  /// manda correo real por Gmail SMTP.
  Future<String?> requestVerificationCode() async {
    final data = await _apiClient.post(
      '$_baseUrl/auth/verification/request',
      body: const {},
      auth: true,
    );
    return (data as Map<String, dynamic>)['code'] as String?;
  }

  /// POST /auth/verification/verify — Confirma el código de 6 dígitos
  /// y marca el correo como verificado en el backend.
  Future<void> verifyEmailCode(String code) async {
    await _apiClient.post(
      '$_baseUrl/auth/verification/verify',
      body: {'code': code},
      auth: true,
    );
  }
}