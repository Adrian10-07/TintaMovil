/// Tipo de moderación aplicada al mensaje.
enum ModerationFlag {
  none,
  spoiler,
  warned,
  blocked;

  static ModerationFlag fromString(String? value) {
    if (value == null) return ModerationFlag.none;
    return ModerationFlag.values.firstWhere(
          (f) => f.name == value,
      orElse: () => ModerationFlag.none,
    );
  }
}

/// Tipo de contenido del mensaje.
enum MessageType {
  text,
  image;

  static MessageType fromString(String? value) {
    if (value == null) return MessageType.text;
    return MessageType.values.firstWhere(
          (t) => t.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Mensaje de discusión dentro del chat de un club.
class Discussion {
  final String id;
  final String clubId;
  final String userId;
  final int? chapterNumber;
  final String content;
  final ModerationFlag moderationFlag;
  final MessageType messageType;
  final String? imageUrl;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Campos enriquecidos por el cliente (no vienen de la API).
  final String? userName;
  final bool isMine;

  const Discussion({
    required this.id,
    required this.clubId,
    required this.userId,
    this.chapterNumber,
    required this.content,
    this.moderationFlag = ModerationFlag.none,
    this.messageType = MessageType.text,
    this.imageUrl,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.isMine = false,
  });

  bool get isSpoiler => moderationFlag == ModerationFlag.spoiler;
  bool get isBlocked => moderationFlag == ModerationFlag.blocked;
  bool get isImage => messageType == MessageType.image && imageUrl != null;

  Discussion copyWith({
    String? content,
    ModerationFlag? moderationFlag,
    String? userName,
    bool? isMine,
    bool? isPinned,
  }) {
    return Discussion(
      id: id,
      clubId: clubId,
      userId: userId,
      chapterNumber: chapterNumber,
      content: content ?? this.content,
      moderationFlag: moderationFlag ?? this.moderationFlag,
      messageType: messageType,
      imageUrl: imageUrl,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userName: userName ?? this.userName,
      isMine: isMine ?? this.isMine,
    );
  }
}

/// Resultado paginado de discusiones.
class DiscussionPage {
  final List<Discussion> items;
  final int total;
  final int page;
  final int pageSize;

  const DiscussionPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < total;
}
