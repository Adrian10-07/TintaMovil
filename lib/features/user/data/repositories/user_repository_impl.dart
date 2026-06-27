import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource _remoteDataSource;

  UserRepositoryImpl(this._remoteDataSource);

  @override
  Future<User> getProfile() async {
    return await _remoteDataSource.getProfile();
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? avatarUrl,
    String? language,
  }) async {
    return await _remoteDataSource.updateProfile(
      name: name,
      avatarUrl: avatarUrl,
      language: language,
    );
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDataSource.deleteAccount();
  }
}