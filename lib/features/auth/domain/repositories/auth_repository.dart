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
}