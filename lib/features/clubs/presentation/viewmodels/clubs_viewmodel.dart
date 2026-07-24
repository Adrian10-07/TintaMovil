import 'package:flutter/foundation.dart';

import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/repositories/club_repository.dart';
import '../../data/services/club_notification_service.dart';

enum ClubsState { initial, loading, loaded, error, empty }
enum ClubsTab { explore, myClubs }

/// ViewModel para la pantalla principal de clubes.
///
/// Optimizaciones vs versión anterior:
/// - _loadMyClubDetails usa Future.wait en batches para paralelizar.
/// - notifyListeners() se llama una sola vez al final del batch, no por cada club.
/// - filteredPublicClubs se cachea para evitar recomputar en cada build.
class ClubsViewModel extends ChangeNotifier {
  final ClubRepository _repository;
  final ClubNotificationService _notifService;

  ClubsViewModel(this._repository, this._notifService);

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

  /// Membresías ordenadas: clubes con mensajes no leídos primero.
  List<ClubMember> get sortedMemberships {
    final unread = _notifService.unreadClubIds;
    if (unread.isEmpty) return _myMemberships;
    final sorted = List<ClubMember>.from(_myMemberships);
    sorted.sort((a, b) {
      final aUnread = unread.contains(a.clubId) ? 0 : 1;
      final bUnread = unread.contains(b.clubId) ? 0 : 1;
      return aUnread.compareTo(bUnread);
    });
    return sorted;
  }

  final Map<String, Club> _myClubsCache = {};
  Club? getMyClub(String clubId) => _myClubsCache[clubId];

  // ── Búsqueda (con caché) ───────────────────────────────────────────────

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  List<Club>? _filteredCache;

  List<Club> get filteredPublicClubs {
    if (_filteredCache != null) return _filteredCache!;

    // IDs de clubes donde ya soy miembro → no mostrar en Explorar.
    final myClubIds = _myMemberships.map((m) => m.clubId).toSet();

    var result = _publicClubs.where((c) => !myClubIds.contains(c.id));

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q) ||
            (c.category?.toLowerCase().contains(q) ?? false);
      });
    }

    _filteredCache = result.toList();
    return _filteredCache!;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _filteredCache = null; // Invalidar caché.
    notifyListeners();
  }

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
      _filteredCache = null;
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
      _filteredCache = null;
      _hasMorePublic = result.hasMore;
    } catch (_) {
      _publicPage--;
    }
    _isLoadingMore = false;
    notifyListeners();
  }

  // ── Mis clubes (optimizado: batch paralelo + single notify) ────────────

  Future<void> loadMyClubs() async {
    _state = ClubsState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _myMemberships = await _repository.listMyClubs();
      _filteredCache = null; // Invalidar: la lista de Explorar debe excluir mis clubes nuevos.
      _state = _myMemberships.isEmpty ? ClubsState.empty : ClubsState.loaded;
      notifyListeners();
      // Cargar detalles en background sin bloquear la UI.
      _loadMyClubDetails();
    } catch (e) {
      _state = ClubsState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _loadMyClubDetails() async {
    final pending = _myMemberships
        .where((m) => !_myClubsCache.containsKey(m.clubId))
        .toList();
    if (pending.isEmpty) return;

    // Cargar en paralelo (todas a la vez — son requests livianos).
    await Future.wait(pending.map((m) async {
      try {
        final club = await _repository.getClub(m.clubId);
        _myClubsCache[m.clubId] = club;
      } catch (_) {}
    }));

    // Un solo notifyListeners para todo el batch.
    notifyListeners();
  }

  // ── Crear club ─────────────────────────────────────────────────────────

  bool _isCreating = false;
  bool get isCreating => _isCreating;

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
        name: name, description: description,
        bookId: bookId, isPrivate: isPrivate,
      );
      await loadMyClubs();
      if (!isPrivate) {
        _publicClubs.insert(0, club);
        _filteredCache = null;
      }
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