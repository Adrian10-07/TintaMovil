import 'package:flutter/material.dart';
import '../../../../core/network/http_client.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/token_pair.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState { initial, loading, success, error }

/// ViewModel de autenticación.
///
/// Flujo real:
/// 1. register() → crea usuario en /users (201)
/// 2. login()    → autentica en /auth/login → recibe tokens
/// 3. Inyecta tokens en ApiClient para requests autenticados
/// 4. logout()   → revoca refresh_token en /auth/logout
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final ApiClient _apiClient;

  AuthViewModel(this._authRepository, this._apiClient);

  // ── Estado ───────────────────────────────────────────────────
  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  TokenPair? _tokens;
  TokenPair? get tokens => _tokens;

  // ── Registro ─────────────────────────────────────────────────
  /// Crea la cuenta y luego hace login automático para obtener tokens.
  Future<void> register(String name, String email, String password) async {
    _setState(AuthState.loading);
    try {
      // 1. Crear usuario → POST /users
      _currentUser = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        language: 'es',
      );

      // 2. Login automático para obtener tokens
      _tokens = await _authRepository.login(
        email: email,
        password: password,
      );

      // 3. Inyectar tokens en el cliente HTTP
      _apiClient.setTokens(
        accessToken: _tokens!.accessToken,
        refreshToken: _tokens!.refreshToken,
      );

      _setState(AuthState.success);
    } on ConflictException catch (e) {
      _errorMessage = 'Este correo ya está registrado';
      _setState(AuthState.error);
    } on ValidationException catch (e) {
      _errorMessage = e.message;
      _setState(AuthState.error);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
    }
  }

  // ── Login ────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    _setState(AuthState.loading);
    try {
      // POST /auth/login → tokens
      _tokens = await _authRepository.login(
        email: email,
        password: password,
      );

      // Inyectar tokens en el cliente HTTP
      _apiClient.setTokens(
        accessToken: _tokens!.accessToken,
        refreshToken: _tokens!.refreshToken,
      );

      _setState(AuthState.success);
    } on UnauthorizedException {
      _errorMessage = 'Correo o contraseña incorrectos';
      _setState(AuthState.error);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
    }
  }

  // ── Logout ───────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      if (_apiClient.refreshToken != null) {
        await _authRepository.logout(_apiClient.refreshToken!);
      }
    } catch (_) {
      // Logout silencioso — si falla la red, limpiamos localmente de todas formas
    } finally {
      _apiClient.clearTokens();
      _currentUser = null;
      _tokens = null;
      _setState(AuthState.initial);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  void resetState() {
    _errorMessage = null;
    _setState(AuthState.initial);
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}