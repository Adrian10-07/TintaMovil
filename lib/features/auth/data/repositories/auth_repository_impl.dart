import '../../domain/entities/user.dart';
import '../../domain/entities/token_pair.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> register({
    required String email,
    required String password,
    required String name,
    String language = 'es',
  }) async {
    return await _remoteDataSource.register(
      email: email,
      password: password,
      name: name,
      language: language,
    );
  }

  @override
  Future<TokenPair> login({
    required String email,
    required String password,
  }) async {
    return await _remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<TokenPair> refreshToken(String refreshToken) async {
    return await _remoteDataSource.refreshToken(refreshToken);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await _remoteDataSource.logout(refreshToken);
  }
}