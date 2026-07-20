import 'package:flutter/foundation.dart';

import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/repositories/club_repository.dart';

/// Estados posibles de la pantalla de clubes.
enum ClubsState { initial, loading, loaded, error, empty }

/// Tabs de la pantalla de clubes.
enum ClubsTab { explore, myClubs }

/// ViewModel para la pantalla principal de clubes.
///
/// Gestiona dos listas: clubes públicos (explorar) y mis clubes.
/// Sigue el mismo patrón que [HomeViewModel].
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

  // ── Clubes públicos (explorar) ─────────────────────────────────────────

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

  // Clubes completos correspondientes a mis membresías (cargados bajo demanda).
  final Map<String, Club> _myClubsCache = {};
  Club? getMyClub(String clubId) => _myClubsCache[clubId];

  // ── Búsqueda ───────────────────────────────────────────────────────────

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // ── Acciones ────────────────────────────────────────────────────────────

  /// Cambia el tab activo.
  void switchTab(ClubsTab tab) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();

    // Cargar datos del tab si aún no se han cargado.
    if (tab == ClubsTab.explore && _publicClubs.isEmpty) {
      loadPublicClubs();
    } else if (tab == ClubsTab.myClubs && _myMemberships.isEmpty) {
      loadMyClubs();
    }
  }

  /// Carga inicial de clubes públicos.
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

  /// Carga la siguiente página de clubes públicos (scroll infinito).
  Future<void> loadNextPage() async {
    if (_isLoadingMore || !_hasMorePublic) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      _publicPage++;
      final result =
          await _repository.listClubs(page: _publicPage, pageSize: 20);
      _publicClubs.addAll(result.items);
      _hasMorePublic = result.hasMore;
    } catch (e) {
      _publicPage--; // Revertir para reintentar.
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Carga los clubes del usuario actual.
  Future<void> loadMyClubs() async {
    _state = ClubsState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _myMemberships = await _repository.listMyClubs();
      _state =
          _myMemberships.isEmpty ? ClubsState.empty : ClubsState.loaded;

      // Cargar detalles de cada club en paralelo.
      _loadMyClubDetails();
    } catch (e) {
      _state = ClubsState.error;
      _errorMessage = e.toString();
    }

    notifyListeners();
  }

  /// Carga los detalles de cada club al que pertenezco.
  Future<void> _loadMyClubDetails() async {
    for (final membership in _myMemberships) {
      if (_myClubsCache.containsKey(membership.clubId)) continue;
      try {
        final club = await _repository.getClub(membership.clubId);
        _myClubsCache[membership.clubId] = club;
        notifyListeners();
      } catch (_) {
        // Si falla uno, seguir con los demás.
      }
    }
  }

  /// Actualiza el query de búsqueda (filtra localmente por nombre).
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clubes filtrados por búsqueda.
  List<Club> get filteredPublicClubs {
    if (_searchQuery.isEmpty) return _publicClubs;
    final q = _searchQuery.toLowerCase();
    return _publicClubs.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          (c.category?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ── Crear club ─────────────────────────────────────────────────────────

  bool _isCreating = false;
  bool get isCreating => _isCreating;

  /// Crea un nuevo club.
  Future<Club?> createClub({
    required String name,
    String description = '',
    String? bookId,
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

      // Agregar a la lista de mis clubes.
      await loadMyClubs();

      // Si es público, agregarlo al inicio de la lista de explorar.
      if (!isPrivate) {
        _publicClubs.insert(0, club);
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

  // ── Unirse a un club ───────────────────────────────────────────────────

  /// Unirse a un club público.
  Future<bool> joinClub(String clubId) async {
    try {
      await _repository.joinClub(clubId);
      await loadMyClubs();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Unirse a un club privado usando un código de invitación.
  Future<bool> joinWithCode(String code) async {
    try {
      await _repository.redeemInvite(code);
      await loadMyClubs();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Refresca ambas listas.
  Future<void> refresh() async {
    if (_currentTab == ClubsTab.explore) {
      await loadPublicClubs();
    } else {
      await loadMyClubs();
    }
  }
}
