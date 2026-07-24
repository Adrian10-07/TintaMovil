import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/club_repository.dart';

/// Servicio de notificaciones in-app para clubes.
///
/// Expone:
/// - [unreadCount]: total de clubes con mensajes nuevos (para el badge global).
/// - [unreadClubIds]: set de club IDs con mensajes nuevos (para badges por club).
/// - Mute/unmute por club.
class ClubNotificationService extends ChangeNotifier {
  final ClubRepository _repository;

  Timer? _pollingTimer;
  String? _currentUserId;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// IDs de clubes que tienen mensajes no leídos.
  final Set<String> _unreadClubIds = {};
  Set<String> get unreadClubIds => Set.unmodifiable(_unreadClubIds);

  /// Verifica si un club específico tiene mensajes no leídos.
  bool hasUnread(String clubId) => _unreadClubIds.contains(clubId);

  static const _lastSeenPrefix = 'club_last_seen_';
  static const _mutedPrefix = 'club_muted_';

  ClubNotificationService(this._repository);

  void initialize(String userId) {
    _currentUserId = userId;
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _checkForNewMessages();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _checkForNewMessages(),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkForNewMessages() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final myClubs = await _repository.listMyClubs();
      final newUnreadIds = <String>{};

      // Ejecutar checks en paralelo (máximo 5 concurrentes) para no bloquear.
      final futures = <Future<void>>[];
      for (final membership in myClubs) {
        futures.add(_checkClub(membership.clubId, prefs, newUnreadIds));
      }
      await Future.wait(futures);

      final newCount = newUnreadIds.length;
      if (newCount != _unreadCount || !setEquals(_unreadClubIds, newUnreadIds)) {
        _unreadClubIds
          ..clear()
          ..addAll(newUnreadIds);
        _unreadCount = newCount;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _checkClub(
      String clubId,
      SharedPreferences prefs,
      Set<String> unreadIds,
      ) async {
    if (prefs.getBool('$_mutedPrefix$clubId') == true) return;
    final lastSeen = prefs.getString('$_lastSeenPrefix$clubId');

    try {
      final page = await _repository.listDiscussions(
        clubId: clubId, page: 1, pageSize: 1,
      );
      if (page.items.isEmpty) return;
      final latest = page.items.first;

      if (lastSeen == null) {
        await prefs.setString(
            '$_lastSeenPrefix$clubId', latest.createdAt.toIso8601String());
        return;
      }

      if (latest.userId != _currentUserId &&
          latest.createdAt.isAfter(DateTime.parse(lastSeen))) {
        unreadIds.add(clubId);
      }
    } catch (_) {}
  }

  Future<void> markClubAsSeen(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$_lastSeenPrefix$clubId', DateTime.now().toIso8601String());
    if (_unreadClubIds.remove(clubId)) {
      _unreadCount = _unreadClubIds.length;
      notifyListeners();
    }
  }

  Future<bool> isClubMuted(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_mutedPrefix$clubId') ?? false;
  }

  Future<void> setClubMuted(String clubId, bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_mutedPrefix$clubId', muted);
    await _checkForNewMessages();
  }

  Future<void> refresh() => _checkForNewMessages();

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
