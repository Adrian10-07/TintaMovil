import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

enum UserState { initial, loading, ready, updating, error }

/// ViewModel para el perfil de usuario.
///
/// Consume el mismo servicio Identity que auth.
/// Las vistas usan Consumer<UserViewModel> para reactivo.
class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  UserViewModel(this._userRepository);

  UserState _state = UserState.initial;
  UserState get state => _state;

  User? _profile;
  User? get profile => _profile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isReady => _state == UserState.ready;
  bool get isLoading => _state == UserState.loading || _state == UserState.updating;

  /// GET /users/me — Carga el perfil autenticado.
  Future<void> loadProfile() async {
    if (_state == UserState.loading) return;
    _setState(UserState.loading);
    try {
      _profile = await _userRepository.getProfile();
      _setState(UserState.ready);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(UserState.error);
    }
  }

  /// PATCH /users/me — Actualiza nombre, avatar o idioma.
  Future<bool> updateProfile({
    String? name,
    String? avatarUrl,
    String? language,
  }) async {
    _setState(UserState.updating);
    try {
      _profile = await _userRepository.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
        language: language,
      );
      _setState(UserState.ready);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(UserState.error);
      return false;
    }
  }

  /// DELETE /users/me — Elimina la cuenta.
  Future<bool> deleteAccount() async {
    _setState(UserState.updating);
    try {
      await _userRepository.deleteAccount();
      _profile = null;
      _setState(UserState.initial);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setState(UserState.error);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    if (_state == UserState.error) {
      _setState(_profile != null ? UserState.ready : UserState.initial);
    }
  }

  void clearProfile() {
    _profile = null;
    _setState(UserState.initial);
  }

  void _setState(UserState newState) {
    _state = newState;
    notifyListeners();
  }
}