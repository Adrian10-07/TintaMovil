import 'package:flutter/foundation.dart';

import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/repositories/club_repository.dart';

enum ClubsState { initial, loading, loaded, error, empty }
enum ClubsTab { explore, myClubs }

/// ViewModel para la pantalla principal de clubes.
class ClubsViewModel extends ChangeNotifier {
  final ClubRepository _repository;

  ClubsViewModel(this._repository);

  // ── Estado ──────────────────────────────────────────────────────────────

  ClubsState _state = ClubsState.initial;
  ClubsState get state => _state;

  ClubsTab _currentTab = ClubsTab.explore;
  ClubsTab get currentTab => _currentTab;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Clubes públicos ────────────────────────────────────────────────────

  List<Club> _publicClubs = [];
  List<Club> get publicClubs => _publicClubs;

  int _publicPage = 1;
  bool _hasMorePublic = true;
  bool get hasMorePublic => _hasMorePublic;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  // ── Mis clubes ─────────────────────────────────────────────────────────

  List<ClubMember> _myMemberships = [];
  List<ClubMember> get myMemberships => _myMemberships;

  final Map<String, Club> _myClubsCache = {};
  Club? getMyClub(String clubId) => _myClubsCache[clubId];

  // ── Búsqueda ───────────────────────────────────────────────────────────

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ── Tabs ────────────────────────────────────────────────────────────────

  void switchTab(ClubsTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
    if (tab == ClubsTab.explore && _publicClubs.isEmpty) loadPublicClubs();
    if (tab == ClubsTab.myClubs && _myMemberships.isEmpty) loadMyClubs();
  }

  // ── Cargar clubes públicos ─────────────────────────────────────────────

  Future<void> loadPublicClubs() async {
    _state = ClubsState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _publicPage = 1;
      final result = await _repository.listClubs(page: 1, pageSize: 20);
      _publicClubs = result.items;
      _hasMorePublic = result.hasMore;
      _state = _publicClubs.isEmpty ? ClubsState.empty : ClubsState.loaded;
    } catch (e) {
      _state = ClubsState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMorePublic) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      _publicPage++;
      final result = await _repository.listClubs(page: _publicPage, pageSize: 20);
      _publicClubs.addAll(result.items);
      _hasMorePublic = result.hasMore;
    } catch (_) {
      _publicPage--;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Mis clubes ─────────────────────────────────────────────────────────

  Future<void> loadMyClubs() async {
    _state = ClubsState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _myMemberships = await _repository.listMyClubs();
      _state = _myMemberships.isEmpty ? ClubsState.empty : ClubsState.loaded;
      _loadMyClubDetails();
    } catch (e) {
      _state = ClubsState.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> _loadMyClubDetails() async {
    for (final m in _myMemberships) {
      if (_myClubsCache.containsKey(m.clubId)) continue;
      try {
        final club = await _repository.getClub(m.clubId);
        // Usar members.length real como contador si member_count viene en 0.
        if (club.memberCount == 0) {
          final members = await _repository.listMembers(m.clubId);
          _myClubsCache[m.clubId] = club.copyWith(memberCount: members.length);
        } else {
          _myClubsCache[m.clubId] = club;
        }
        notifyListeners();
      } catch (_) {}
    }
  }

  // ── Búsqueda ───────────────────────────────────────────────────────────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Club> get filteredPublicClubs {
    if (_searchQuery.isEmpty) return _publicClubs;
    final q = _searchQuery.toLowerCase();
    return _publicClubs.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          (c.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ── Crear club (auto-join como owner) ──────────────────────────────────

  bool _isCreating = false;
  bool get isCreating => _isCreating;

  /// Crea un club. El backend asigna al creador como owner automáticamente.
  /// Después recargamos "Mis Clubes" para reflejar la nueva membresía.
  Future<Club?> createClub({
    required String name,
    String description = '',
    String? bookId,
    String? category,
    bool isPrivate = false,
  }) async {
    _isCreating = true;
    notifyListeners();
    try {
      final club = await _repository.createClub(
        name: name,
        description: description,
        bookId: bookId,
        isPrivate: isPrivate,
      );

      // El backend ya registra al creador como owner, solo refrescamos.
      await loadMyClubs();

      if (!isPrivate) _publicClubs.insert(0, club);

      _isCreating = false;
      notifyListeners();
      return club;
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── Unirse ─────────────────────────────────────────────────────────────

  Future<bool> joinClub(String clubId) async {
    try {
      await _repository.joinClub(clubId);
      await loadMyClubs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinWithCode(String code) async {
    try {
      await _repository.redeemInvite(code);
      await loadMyClubs();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    if (_currentTab == ClubsTab.explore) {
      await loadPublicClubs();
    } else {
      await loadMyClubs();
    }
  }
}
