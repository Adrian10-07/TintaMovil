import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/invite_code.dart';
import '../../domain/repositories/club_repository.dart';
import '../datasources/club_remote_datasource.dart';
import '../datasources/club_local_datasource.dart';

/// Implementación del repositorio de clubes.
///
/// Estrategia de caché: cache-first para discusiones (chat), network-first
/// para clubes y membresía (datos que cambian frecuentemente y son ligeros).
///
/// Sigue el mismo patrón que [BookRepositoryImpl], [UserRepositoryImpl], etc.
class ClubRepositoryImpl implements ClubRepository {
  final ClubRemoteDataSource _remote;
  final ClubLocalDataSource _local;

  ClubRepositoryImpl({
    required ClubRemoteDataSource remote,
    required ClubLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  // ── Clubes (network-first) ────────────────────────────────────────────

  @override
  Future<ClubPage> listClubs({
    int page = 1,
    int pageSize = 20,
    String? creatorId,
    String? bookId,
  }) {
    return _remote.listClubs(
      page: page,
      pageSize: pageSize,
      creatorId: creatorId,
      bookId: bookId,
    );
  }

  @override
  Future<Club> getClub(String clubId) {
    return _remote.getClub(clubId);
  }

  @override
  Future<Club> createClub({
    required String name,
    String description = '',
    String? bookId,
    bool isPrivate = false,
  }) {
    return _remote.createClub(
      name: name,
      description: description,
      bookId: bookId,
      isPrivate: isPrivate,
    );
  }

  @override
  Future<Club> updateClub(
    String clubId, {
    String? name,
    String? description,
    String? bookId,
    bool? isPrivate,
  }) {
    return _remote.updateClub(
      clubId,
      name: name,
      description: description,
      bookId: bookId,
      isPrivate: isPrivate,
    );
  }

  @override
  Future<void> deleteClub(String clubId) {
    return _remote.deleteClub(clubId);
  }

  // ── Membresía (network-first) ─────────────────────────────────────────

  @override
  Future<ClubMember> joinClub(String clubId, {String? inviteCode}) {
    return _remote.joinClub(clubId, inviteCode: inviteCode);
  }

  @override
  Future<void> leaveClub(String clubId) async {
    await _remote.leaveClub(clubId);
    // Limpiar caché local del club que abandonamos.
    await _local.clearClub(clubId);
  }

  @override
  Future<MembershipStatus> checkMembership(String clubId) {
    return _remote.checkMembership(clubId);
  }

  @override
  Future<List<ClubMember>> listMembers(String clubId) {
    return _remote.listMembers(clubId);
  }

  @override
  Future<List<ClubMember>> listMyClubs() {
    return _remote.listMyClubs();
  }

  // ── Discusiones (cache-first + sync incremental) ──────────────────────

  @override
  Future<Discussion> postDiscussion({
    required String clubId,
    required String content,
    int? chapterNumber,
  }) async {
    final discussion = await _remote.postDiscussion(
      clubId: clubId,
      content: content,
      chapterNumber: chapterNumber,
    );
    // Cachear el mensaje enviado inmediatamente.
    await _local.upsertDiscussions([discussion]);
    return discussion;
  }

  @override
  Future<DiscussionPage> listDiscussions({
    required String clubId,
    int page = 1,
    int pageSize = 50,
    int? chapterNumber,
  }) async {
    // Intentar obtener de la red.
    final remotePage = await _remote.listDiscussions(
      clubId: clubId,
      page: page,
      pageSize: pageSize,
      chapterNumber: chapterNumber,
    );

    // Cachear los resultados.
    if (remotePage.items.isNotEmpty) {
      await _local.upsertDiscussions(remotePage.items);

      // Actualizar el timestamp de sincronización.
      final latest = remotePage.items
          .map((d) => d.createdAt)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      await _local.setLastSyncedAt(clubId, latest.toIso8601String());
    }

    return remotePage;
  }

  @override
  Future<Discussion> updateDiscussion(
      String discussionId, String content) async {
    final updated = await _remote.updateDiscussion(discussionId, content);
    await _local.upsertDiscussions([updated]);
    return updated;
  }

  @override
  Future<void> deleteDiscussion(String discussionId) async {
    await _remote.deleteDiscussion(discussionId);
    await _local.deleteDiscussion(discussionId);
  }

  @override
  Future<void> clearDiscussions(String clubId) async {
    await _remote.clearDiscussions(clubId);
    await _local.clearClub(clubId);
  }

  // ── Invitaciones ──────────────────────────────────────────────────────

  @override
  Future<InviteCode> createInvite(
    String clubId, {
    int? maxUses,
    Duration? ttl,
  }) {
    return _remote.createInvite(
      clubId,
      maxUses: maxUses,
      ttlMinutes: ttl?.inMinutes,
    );
  }

  @override
  Future<ClubMember> redeemInvite(String code) {
    return _remote.redeemInvite(code);
  }

  // ── Caché ─────────────────────────────────────────────────────────────

  @override
  Future<List<Discussion>> getCachedDiscussions(
    String clubId, {
    int limit = 50,
  }) {
    return _local.getDiscussions(clubId, limit: limit);
  }

  @override
  Future<void> cacheDiscussions(List<Discussion> discussions) {
    return _local.upsertDiscussions(discussions);
  }

  @override
  Future<void> clearLocalCache(String clubId) {
    return _local.clearClub(clubId);
  }
}
