import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  static UserProfile fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      streakDays: (json['streak_days'] as num?)?.toInt() ?? 0,
      booksRead: (json['books_read'] as num?)?.toInt() ?? 0,
      pagesRead: (json['pages_read'] as num?)?.toInt() ?? 0,
      memberSince: DateTime.parse(
        json['member_since'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static Map<String, dynamic> toJson(UserProfile profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      if (profile.avatarUrl != null) 'avatar_url': profile.avatarUrl,
      if (profile.bio != null) 'bio': profile.bio,
    };
  }
}