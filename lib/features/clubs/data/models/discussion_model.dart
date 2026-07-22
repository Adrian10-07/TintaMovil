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
    super.messageType,
    super.imageUrl,
    super.isPinned,
    required super.createdAt,
    required super.updatedAt,
    super.userName,
    super.isMine,
  });

  factory DiscussionModel.fromJson(Map<String, dynamic> json) {
    return DiscussionModel(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      chapterNumber: json['chapter_number'] as int?,
      content: json['content'] as String,
      moderationFlag:
      ModerationFlag.fromString(json['moderation_flag'] as String?),
      messageType:
      MessageType.fromString(json['message_type'] as String?),
      imageUrl: json['image_url'] as String?,
      isPinned: (json['is_pinned'] as bool?) ?? false,
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
      if (messageType != MessageType.text) 'message_type': messageType.name,
      if (imageUrl != null) 'image_url': imageUrl,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DiscussionModel.fromSqlite(Map<String, dynamic> row) {
    return DiscussionModel(
      id: row['id'] as String,
      clubId: row['club_id'] as String,
      userId: row['user_id'] as String,
      chapterNumber: row['chapter_number'] as int?,
      content: row['content'] as String,
      moderationFlag:
      ModerationFlag.fromString(row['moderation_flag'] as String?),
      messageType:
      MessageType.fromString(row['message_type'] as String?),
      imageUrl: row['image_url'] as String?,
      isPinned: (row['is_pinned'] as int?) == 1,
      createdAt:
      DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt:
      DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      userName: row['user_name'] as String?,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      'chapter_number': chapterNumber,
      'content': content,
      'moderation_flag':
      moderationFlag == ModerationFlag.none ? null : moderationFlag.name,
      'message_type': messageType.name,
      'image_url': imageUrl,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'user_name': userName,
    };
  }
}
