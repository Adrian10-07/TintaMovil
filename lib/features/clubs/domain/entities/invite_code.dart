/// Código de invitación para un club privado.
class InviteCode {
  final String id;
  final String clubId;
  final String code;
  final String createdBy;
  final int? maxUses;
  final int useCount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;

  const InviteCode({
    required this.id,
    required this.clubId,
    required this.code,
    required this.createdBy,
    this.maxUses,
    this.useCount = 0,
    this.expiresAt,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isUsable =>
      isActive && !isExpired && (maxUses == null || useCount < maxUses!);

  /// Link para compartir (deep link).
  String get shareLink => 'https://tinta.app/club/join/$code';
}
