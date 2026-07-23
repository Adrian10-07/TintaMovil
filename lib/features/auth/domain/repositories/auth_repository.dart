import '../entities/user.dart';
import '../entities/token_pair.dart';

abstract class AuthRepository {
  /// POST /api/v1/users — Crea una cuenta nueva.
  /// Retorna el User creado (201).
  Future<User> register({
    required String email,
    required String password,
    required String name,
    String language,
  });

  /// POST /api/v1/auth/login — Autentica con email+password.
  /// Retorna el par de tokens (access + refresh).
  Future<TokenPair> login({
    required String email,
    required String password,
  });

  /// POST /api/v1/auth/refresh — Rota el refresh token.
  Future<TokenPair> refreshToken(String refreshToken);

  /// POST /api/v1/auth/logout — Revoca el refresh token (204).
  Future<void> logout(String refreshToken);

  /// POST /api/v1/auth/password-reset/request — Pide un código de 6
  /// dígitos para restablecer la contraseña. Regresa el código si el
  /// backend lo trae (modo MVP sin correo real garantizado todavía).
  Future<String?> requestPasswordReset(String email);

  /// POST /api/v1/auth/password-reset/confirm — Confirma el código y
  /// establece la nueva contraseña.
  Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
  });
}