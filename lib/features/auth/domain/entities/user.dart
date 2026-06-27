
class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool emailVerified;
  final String avatarUrl;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.emailVerified,
    required this.avatarUrl,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });
}