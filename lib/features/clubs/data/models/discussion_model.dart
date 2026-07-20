import '../../domain/entities/discussion.dart';

/// Modelo de datos para [Discussion] con serialización JSON y SQLite.
class DiscussionModel extends Discussion {
  const DiscussionModel({
    required super.id,
    required super.clubId,
    required super.userId,
    super.chapterNumber,
    required super.content,
    super.moderationFlag,
    required super.createdAt,
    required super.updatedAt,
    super.userName,
    super.isMine,
  });

  /// Desde la respuesta JSON de la API.
  factory DiscussionModel.fromJson(Map<String, dynamic> json) {
    return DiscussionModel(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      chapterNumber: json['chapter_number'] as int?,
      content: json['content'] as String,
      moderationFlag:
          ModerationFlag.fromString(json['moderation_flag'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      if (chapterNumber != null) 'chapter_number': chapterNumber,
      'content': content,
      'moderation_flag':
          moderationFlag == ModerationFlag.none ? null : moderationFlag.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Desde un registro de SQLite.
  factory DiscussionModel.fromSqlite(Map<String, dynamic> row) {
    return DiscussionModel(
      id: row['id'] as String,
      clubId: row['club_id'] as String,
      userId: row['user_id'] as String,
      chapterNumber: row['chapter_number'] as int?,
      content: row['content'] as String,
      moderationFlag:
          ModerationFlag.fromString(row['moderation_flag'] as String?),
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      userName: row['user_name'] as String?,
    );
  }

  /// A mapa para insertar en SQLite.
  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      'chapter_number': chapterNumber,
      'content': content,
      'moderation_flag':
          moderationFlag == ModerationFlag.none ? null : moderationFlag.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'user_name': userName,
    };
  }
}
