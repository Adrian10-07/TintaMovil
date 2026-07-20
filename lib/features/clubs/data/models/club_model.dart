import '../../domain/entities/club.dart';

/// Modelo de datos para [Club] con serialización JSON.
///
/// Mapea 1:1 con el ClubResponse del backend Go.
class ClubModel extends Club {
  const ClubModel({
    required super.id,
    required super.creatorId,
    super.bookId,
    required super.name,
    super.description,
    super.isPrivate,
    super.category,
    super.tags,
    super.maxMembers,
    super.memberCount,
    super.avatarUrl,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ClubModel.fromJson(Map<String, dynamic> json) {
    return ClubModel(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String,
      bookId: json['book_id'] as String?,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      isPrivate: (json['is_private'] as bool?) ?? false,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      maxMembers: (json['max_members'] as int?) ?? 50,
      memberCount: (json['member_count'] as int?) ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      if (bookId != null) 'book_id': bookId,
      'name': name,
      'description': description,
      'is_private': isPrivate,
      if (category != null) 'category': category,
      if (tags.isNotEmpty) 'tags': tags,
      'max_members': maxMembers,
      'member_count': memberCount,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ClubModel.fromEntity(Club club) {
    return ClubModel(
      id: club.id,
      creatorId: club.creatorId,
      bookId: club.bookId,
      name: club.name,
      description: club.description,
      isPrivate: club.isPrivate,
      category: club.category,
      tags: club.tags,
      maxMembers: club.maxMembers,
      memberCount: club.memberCount,
      avatarUrl: club.avatarUrl,
      createdAt: club.createdAt,
      updatedAt: club.updatedAt,
    );
  }
}
