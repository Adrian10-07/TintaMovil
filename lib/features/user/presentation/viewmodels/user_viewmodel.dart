import 'package:flutter/foundation.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

enum UserState { initial, loading, ready, updating, error }

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

  bool _isRequestingCode = false;
  bool get isRequestingCode => _isRequestingCode;

  Future<String?> requestVerificationCode() async {
    _isRequestingCode = true;
    notifyListeners();
    try {
      return await _userRepository.requestVerificationCode();
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isRequestingCode = false;
      notifyListeners();
    }
  }

  bool _isVerifyingCode = false;
  bool get isVerifyingCode => _isVerifyingCode;

  Future<bool> verifyEmailCode(String code) async {
    _isVerifyingCode = true;
    notifyListeners();
    try {
      await _userRepository.verifyEmailCode(code);
      await loadProfile();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isVerifyingCode = false;
      notifyListeners();
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