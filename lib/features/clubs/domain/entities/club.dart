/// Club aggregate — entidad principal del módulo de comunidad.
class Club {
  final String id;
  final String creatorId;
  final String? bookId;
  final String name;
  final String description;
  final bool isPrivate;
  final String? category;
  final List<String> tags;
  final int maxMembers;
  final int memberCount;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Club({
    required this.id,
    required this.creatorId,
    this.bookId,
    required this.name,
    this.description = '',
    this.isPrivate = false,
    this.category,
    this.tags = const [],
    this.maxMembers = 50,
    this.memberCount = 0,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isFull => memberCount >= maxMembers;

  bool isOwnedBy(String userId) => creatorId == userId;

  Club copyWith({
    String? name,
    String? description,
    bool? isPrivate,
    String? category,
    List<String>? tags,
    int? memberCount,
    String? avatarUrl,
  }) {
    return Club(
      id: id,
      creatorId: creatorId,
      bookId: bookId,
      name: name ?? this.name,
      description: description ?? this.description,
      isPrivate: isPrivate ?? this.isPrivate,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      maxMembers: maxMembers,
      memberCount: memberCount ?? this.memberCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
