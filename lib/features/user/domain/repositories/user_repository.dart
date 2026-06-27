import '../../../auth/domain/entities/user.dart';

abstract class UserRepository {
  Future<User> getProfile();
  Future<User> updateProfile({String? name, String? avatarUrl, String? language});
  Future<void> deleteAccount();
}