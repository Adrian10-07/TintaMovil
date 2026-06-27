/// Perfil extendido del usuario (más datos que el User de auth).
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final int streakDays;
  final int booksRead;
  final int pagesRead;
  final DateTime memberSince;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.streakDays = 0,
    this.booksRead = 0,
    this.pagesRead = 0,
    required this.memberSince,
  });

  UserProfile copyWith({
    String? name,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      streakDays: streakDays,
      booksRead: booksRead,
      pagesRead: pagesRead,
      memberSince: memberSince,
    );
  }
}