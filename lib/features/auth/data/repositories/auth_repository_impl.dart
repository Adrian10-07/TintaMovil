import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> login(String email, String password) async {
    try {
      return await remoteDataSource.login(email, password);
    } catch (e) {
      // Aquí mapearías excepciones de red a excepciones de dominio (ej. AuthException)
      rethrow;
    }
  }

  @override
  Future<User> register(String name, String email, String password) async {
    try {
      return await remoteDataSource.register(name, email, password);
    } catch (e) {
      rethrow;
    }
  }
}