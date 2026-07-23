/// Roles posibles dentro de un club.
enum ClubRole {
  member,
  moderator,
  owner;

  bool get canModerate => this == moderator || this == owner;
  bool get canManage => this == owner;

  static ClubRole fromString(String value) {
    return ClubRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => ClubRole.member,
    );
  }
}

/// Membresía de un usuario en un club.
class ClubMember {
  final String id;
  final String clubId;
  final String userId;
  final ClubRole role;
  final DateTime joinedAt;

  const ClubMember({
    required this.id,
    required this.clubId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });
}

/// Resultado de verificación de membresía.
class MembershipStatus {
  final bool isMember;
  final ClubMember? membership;

  const MembershipStatus({required this.isMember, this.membership});
}
