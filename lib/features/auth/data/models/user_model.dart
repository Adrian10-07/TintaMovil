import '../../domain/entities/user.dart';

class UserModel {
  static User fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String? ?? 'user',
      emailVerified: json['email_verified'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String? ?? '',
      language: json['language'] as String? ?? 'es',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}