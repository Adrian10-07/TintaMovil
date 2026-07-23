import '../../domain/entities/invite_code.dart';

/// Modelo de datos para [InviteCode] con serialización JSON.
class InviteCodeModel extends InviteCode {
  const InviteCodeModel({
    required super.id,
    required super.clubId,
    required super.code,
    required super.createdBy,
    super.maxUses,
    super.useCount,
    super.expiresAt,
    super.isActive,
    required super.createdAt,
  });

  factory InviteCodeModel.fromJson(Map<String, dynamic> json) {
    return InviteCodeModel(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      code: json['code'] as String,
      createdBy: json['created_by'] as String,
      maxUses: json['max_uses'] as int?,
      useCount: (json['use_count'] as int?) ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      isActive: (json['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
