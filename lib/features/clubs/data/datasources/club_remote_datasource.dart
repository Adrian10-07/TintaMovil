import '../../../../core/network/http_client.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/invite_code.dart';
import '../../domain/repositories/club_repository.dart';
import '../models/club_model.dart';
import '../models/club_member_model.dart';
import '../models/discussion_model.dart';
import '../models/invite_code_model.dart';

/// DataSource remoto para el servicio Community de Tinta.
///
/// ⚠️  Cambia [_baseUrl] a la URL real de tu servicio community en Railway.
///     Localmente con docker-compose sería: http://10.0.2.2:8002/api/v1
///     (10.0.2.2 es el localhost del host desde el emulador Android).
class ClubRemoteDataSource {
  final ApiClient _api;

  // ┌─────────────────────────────────────────────────────────────────────┐
  // │  CAMBIAR ESTA URL SEGÚN TU ENTORNO:                                │
  // │  • Railway:  https://tinta-community-production.up.railway.app/api/v1
  // │  • Local Android emulator: http://10.0.2.2:8002/api/v1             │
  // │  • Local iOS simulator:    http://localhost:8002/api/v1             │
  // │  • Dispositivo físico:     http://<IP-DE-TU-PC>:8002/api/v1        │
  // └─────────────────────────────────────────────────────────────────────┘
  static const String _baseUrl =
      'https://tinta-communities.up.railway.app/api/v1';

  ClubRemoteDataSource(this._api);

  // ── Clubes ────────────────────────────────────────────────────────────

  /// GET /clubs?page=&page_size=&creator_id=&book_id=
  Future<ClubPage> listClubs({
    int page = 1,
    int pageSize = 20,
    String? creatorId,
    String? bookId,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (creatorId != null) 'creator_id': creatorId,
      if (bookId != null) 'book_id': bookId,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _api.get('$_baseUrl/clubs?$query', auth: true);
    final map = data as Map<String, dynamic>;
    final items = (map['items'] as List<dynamic>)
        .map((e) => ClubModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return ClubPage(
      items: items,
      total: (map['total'] as num).toInt(),
      page: (map['page'] as num).toInt(),
      pageSize: (map['page_size'] as num).toInt(),
    );
  }

  /// GET /clubs/{id}
  Future<Club> getClub(String clubId) async {
    final data = await _api.get('$_baseUrl/clubs/$clubId', auth: true);
    return ClubModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /clubs
  Future<Club> createClub({
    required String name,
    String description = '',
    String? bookId,
    bool isPrivate = false,
  }) async {
    final data = await _api.post(
      '$_baseUrl/clubs',
      body: {
        'name': name,
        'description': description,
        if (bookId != null) 'book_id': bookId,
        'is_private': isPrivate,
      },
      auth: true,
    );
    return ClubModel.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /clubs/{id}
  Future<Club> updateClub(
      String clubId, {
        String? name,
        String? description,
        String? bookId,
        bool? isPrivate,
      }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (bookId != null) 'book_id': bookId,
      if (isPrivate != null) 'is_private': isPrivate,
    };
    final data = await _api.patch(
      '$_baseUrl/clubs/$clubId',
      body: body,
      auth: true,
    );
    return ClubModel.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /clubs/{id}
  Future<void> deleteClub(String clubId) async {
    await _api.delete('$_baseUrl/clubs/$clubId', auth: true);
  }

  // ── Membresía ─────────────────────────────────────────────────────────

  /// POST /clubs/{club_id}/join
  Future<ClubMember> joinClub(String clubId, {String? inviteCode}) async {
    final code = inviteCode != null ? '?invite_code=$inviteCode' : '';
    final data = await _api.post(
      '$_baseUrl/clubs/$clubId/join$code',
      body: {},
      auth: true,
    );
    return ClubMemberModel.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /clubs/{club_id}/leave
  Future<void> leaveClub(String clubId) async {
    await _api.delete('$_baseUrl/clubs/$clubId/leave', auth: true);
  }

  /// GET /clubs/{club_id}/membership
  Future<MembershipStatus> checkMembership(String clubId) async {
    final data =
    await _api.get('$_baseUrl/clubs/$clubId/membership', auth: true);
    final map = data as Map<String, dynamic>;
    final isMember = map['is_member'] as bool;
    return MembershipStatus(
      isMember: isMember,
      membership: isMember && map['membership'] != null
          ? ClubMemberModel.fromJson(
          map['membership'] as Map<String, dynamic>)
          : null,
    );
  }

  /// GET /clubs/{club_id}/members
  Future<List<ClubMember>> listMembers(String clubId) async {
    final data =
    await _api.get('$_baseUrl/clubs/$clubId/members', auth: true);
    final map = data as Map<String, dynamic>;
    return (map['items'] as List<dynamic>)
        .map((e) => ClubMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /me/clubs
  Future<List<ClubMember>> listMyClubs() async {
    final data = await _api.get('$_baseUrl/me/clubs', auth: true);
    final map = data as Map<String, dynamic>;
    return (map['items'] as List<dynamic>)
        .map((e) => ClubMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Discusiones ───────────────────────────────────────────────────────

  /// POST /clubs/{club_id}/discussions
  Future<Discussion> postDiscussion({
    required String clubId,
    required String content,
    int? chapterNumber,
  }) async {
    final data = await _api.post(
      '$_baseUrl/clubs/$clubId/discussions',
      body: {
        'content': content,
        if (chapterNumber != null) 'chapter_number': chapterNumber,
      },
      auth: true,
    );
    return DiscussionModel.fromJson(data as Map<String, dynamic>);
  }

  /// GET /clubs/{club_id}/discussions?page=&page_size=&chapter_number=
  Future<DiscussionPage> listDiscussions({
    required String clubId,
    int page = 1,
    int pageSize = 50,
    int? chapterNumber,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'page_size': '$pageSize',
      if (chapterNumber != null) 'chapter_number': '$chapterNumber',
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final data = await _api.get(
      '$_baseUrl/clubs/$clubId/discussions?$query',
      auth: true,
    );
    final map = data as Map<String, dynamic>;
    final items = (map['items'] as List<dynamic>)
        .map((e) => DiscussionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return DiscussionPage(
      items: items,
      total: (map['total'] as num).toInt(),
      page: (map['page'] as num).toInt(),
      pageSize: (map['page_size'] as num).toInt(),
    );
  }

  /// PATCH /discussions/{id}
  Future<Discussion> updateDiscussion(
      String discussionId, String content) async {
    final data = await _api.patch(
      '$_baseUrl/discussions/$discussionId',
      body: {'content': content},
      auth: true,
    );
    return DiscussionModel.fromJson(data as Map<String, dynamic>);
  }

  /// DELETE /discussions/{id}
  Future<void> deleteDiscussion(String discussionId) async {
    await _api.delete('$_baseUrl/discussions/$discussionId', auth: true);
  }

  /// POST /clubs/{club_id}/discussions/clear
  /// (Endpoint propuesto — requiere implementación en backend)
  Future<void> clearDiscussions(String clubId) async {
    await _api.post(
      '$_baseUrl/clubs/$clubId/discussions/clear',
      body: {},
      auth: true,
    );
  }

  // ── Invitaciones ──────────────────────────────────────────────────────
  // (Endpoints propuestos — requieren implementación en backend)

  /// POST /clubs/{club_id}/invite
  Future<InviteCode> createInvite(
      String clubId, {
        int? maxUses,
        int? ttlMinutes,
      }) async {
    final data = await _api.post(
      '$_baseUrl/clubs/$clubId/invite',
      body: {
        if (maxUses != null) 'max_uses': maxUses,
        if (ttlMinutes != null) 'ttl_minutes': ttlMinutes,
      },
      auth: true,
    );
    return InviteCodeModel.fromJson(data as Map<String, dynamic>);
  }

  /// POST /invite/redeem
  Future<ClubMember> redeemInvite(String code) async {
    final data = await _api.post(
      '$_baseUrl/invite/redeem',
      body: {'code': code},
      auth: true,
    );
    return ClubMemberModel.fromJson(data as Map<String, dynamic>);
  }
}
