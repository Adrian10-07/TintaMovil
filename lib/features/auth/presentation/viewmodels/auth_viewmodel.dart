import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState { initial, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository);

  AuthState _state = AuthState.initial;
  AuthState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    _setState(AuthState.loading);
    try {
      _currentUser = await _authRepository.login(email, password);
      _setState(AuthState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
    }
  }

  Future<void> register(String name, String email, String password) async {
    _setState(AuthState.loading);
    try {
      _currentUser = await _authRepository.register(name, email, password);
      _setState(AuthState.success);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(AuthState.error);
    }
  }

  void resetState() {
    _setState(AuthState.initial);
    _errorMessage = null;
  }

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }
}