import 'package:flutter/foundation.dart';

import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/entities/invite_code.dart';
import '../../domain/repositories/club_repository.dart';

/// ViewModel para la pantalla de detalle de un club.
///
/// Gestiona la información del club, lista de miembros, membresía del
/// usuario actual, y las operaciones de administración.
class ClubDetailViewModel extends ChangeNotifier {
  final ClubRepository _repository;
  final String clubId;

  ClubDetailViewModel({
    required ClubRepository repository,
    required this.clubId,
  }) : _repository = repository;

  // ── Estado ──────────────────────────────────────────────────────────────

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Club? _club;
  Club? get club => _club;

  List<ClubMember> _members = [];
  List<ClubMember> get members => _members;

  MembershipStatus? _myMembership;
  MembershipStatus? get myMembership => _myMembership;

  bool get isMember => _myMembership?.isMember ?? false;
  ClubRole? get myRole => _myMembership?.membership?.role;
  bool get canModerate => myRole?.canModerate ?? false;
  bool get canManage => myRole?.canManage ?? false;

  InviteCode? _inviteCode;
  InviteCode? get inviteCode => _inviteCode;

  // ── Carga inicial ─────────────────────────────────────────────────────

  /// Carga toda la información del club en paralelo.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cargar club, membresía y miembros en paralelo.
      final results = await Future.wait([
        _repository.getClub(clubId),
        _repository.checkMembership(clubId),
        _repository.listMembers(clubId),
      ]);

      _club = results[0] as Club;
      _myMembership = results[1] as MembershipStatus;
      _members = results[2] as List<ClubMember>;
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Acciones de membresía ─────────────────────────────────────────────

  /// Unirse al club.
  Future<bool> join({String? inviteCode}) async {
    try {
      await _repository.joinClub(clubId, inviteCode: inviteCode);
      // Recargar membresía y miembros.
      _myMembership = await _repository.checkMembership(clubId);
      _members = await _repository.listMembers(clubId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Abandonar el club.
  Future<bool> leave() async {
    try {
      await _repository.leaveClub(clubId);
      _myMembership =
          const MembershipStatus(isMember: false, membership: null);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Administración ────────────────────────────────────────────────────

  /// Genera un código de invitación.
  Future<InviteCode?> generateInvite({
    int? maxUses,
    Duration? ttl,
  }) async {
    try {
      _inviteCode = await _repository.createInvite(
        clubId,
        maxUses: maxUses,
        ttl: ttl,
      );
      notifyListeners();
      return _inviteCode;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Actualiza la configuración del club.
  Future<bool> updateClub({
    String? name,
    String? description,
    bool? isPrivate,
  }) async {
    try {
      _club = await _repository.updateClub(
        clubId,
        name: name,
        description: description,
        isPrivate: isPrivate,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Elimina el club (solo owner).
  Future<bool> deleteClub() async {
    try {
      await _repository.deleteClub(clubId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Vacía todo el chat del club (solo owner/moderator).
  Future<bool> clearChat() async {
    try {
      await _repository.clearDiscussions(clubId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Limpia el error actual.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
