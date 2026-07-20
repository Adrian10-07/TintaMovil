import '../entities/club.dart';
import '../entities/club_member.dart';
import '../entities/discussion.dart';
import '../entities/invite_code.dart';

/// Resultado paginado genérico para clubes.
class ClubPage {
  final List<Club> items;
  final int total;
  final int page;
  final int pageSize;

  const ClubPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => (page * pageSize) < total;
}

/// Contrato del repositorio de clubes.
///
/// Sigue el mismo patrón que [BookRepository], [UserRepository], etc.
abstract class ClubRepository {
  // ── Clubes ──────────────────────────────────────────────────────────────

  /// Lista clubes públicos con paginación y filtros opcionales.
  Future<ClubPage> listClubs({
    int page = 1,
    int pageSize = 20,
    String? creatorId,
    String? bookId,
  });

  /// Obtiene un club por su ID.
  Future<Club> getClub(String clubId);

  /// Crea un nuevo club. El usuario actual se vuelve owner automáticamente.
  Future<Club> createClub({
    required String name,
    String description = '',
    String? bookId,
    bool isPrivate = false,
  });

  /// Actualiza un club existente (solo owner).
  Future<Club> updateClub(
    String clubId, {
    String? name,
    String? description,
    String? bookId,
    bool? isPrivate,
  });

  /// Soft-delete de un club (solo owner).
  Future<void> deleteClub(String clubId);

  // ── Membresía ───────────────────────────────────────────────────────────

  /// Unirse a un club público, o privado con código de invitación.
  Future<ClubMember> joinClub(String clubId, {String? inviteCode});

  /// Abandonar un club (no permitido para owners).
  Future<void> leaveClub(String clubId);

  /// Verificar si el usuario actual es miembro de un club.
  Future<MembershipStatus> checkMembership(String clubId);

  /// Listar miembros de un club.
  Future<List<ClubMember>> listMembers(String clubId);

  /// Listar los clubes del usuario actual (mis clubes).
  Future<List<ClubMember>> listMyClubs();

  // ── Discusiones / Chat ──────────────────────────────────────────────────

  /// Enviar un mensaje al chat del club.
  Future<Discussion> postDiscussion({
    required String clubId,
    required String content,
    int? chapterNumber,
  });

  /// Listar mensajes del chat con paginación.
  Future<DiscussionPage> listDiscussions({
    required String clubId,
    int page = 1,
    int pageSize = 50,
    int? chapterNumber,
  });

  /// Editar un mensaje propio.
  Future<Discussion> updateDiscussion(String discussionId, String content);

  /// Eliminar un mensaje propio.
  Future<void> deleteDiscussion(String discussionId);

  /// Vaciar todo el chat de un club (solo owner/moderator).
  Future<void> clearDiscussions(String clubId);

  // ── Invitaciones ────────────────────────────────────────────────────────

  /// Generar un código de invitación (solo owner/moderator).
  Future<InviteCode> createInvite(String clubId, {int? maxUses, Duration? ttl});

  /// Unirse a un club usando un código de invitación (sin conocer el club_id).
  Future<ClubMember> redeemInvite(String code);

  // ── Caché ───────────────────────────────────────────────────────────────

  /// Obtener mensajes cacheados localmente.
  Future<List<Discussion>> getCachedDiscussions(String clubId, {int limit = 50});

  /// Guardar mensajes en caché local.
  Future<void> cacheDiscussions(List<Discussion> discussions);

  /// Limpiar caché local de un club.
  Future<void> clearLocalCache(String clubId);
}
