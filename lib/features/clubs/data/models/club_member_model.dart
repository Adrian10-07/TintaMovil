import '../../domain/entities/club_member.dart';

/// Modelo de datos para [ClubMember] con serialización JSON.
class ClubMemberModel extends ClubMember {
  const ClubMemberModel({
    required super.id,
    required super.clubId,
    required super.userId,
    required super.role,
    required super.joinedAt,
  });

  factory ClubMemberModel.fromJson(Map<String, dynamic> json) {
    return ClubMemberModel(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      userId: json['user_id'] as String,
      role: ClubRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'club_id': clubId,
      'user_id': userId,
      'role': role.name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
