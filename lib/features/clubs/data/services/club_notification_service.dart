import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/club_repository.dart';

/// Servicio de notificaciones in-app para mensajes de clubes.
///
/// No usa notificaciones nativas del sistema — solo gestiona:
/// - Un badge numérico en el tab de clubes (cuántos clubes tienen mensajes nuevos).
/// - Estado de "silenciado" por club.
/// - Polling periódico para detectar mensajes nuevos.
///
/// Esto evita la dependencia de flutter_local_notifications y los
/// problemas de desugaring en Android.
class ClubNotificationService extends ChangeNotifier {
  final ClubRepository _repository;

  Timer? _pollingTimer;
  String? _currentUserId;

  /// Cantidad de clubes con mensajes no leídos.
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  static const _lastSeenPrefix = 'club_last_seen_';
  static const _mutedPrefix = 'club_muted_';

  ClubNotificationService(this._repository);

  /// Inicializa con el userId actual.
  void initialize(String userId) {
    _currentUserId = userId;
  }

  /// Inicia el polling de mensajes nuevos cada 30 segundos.
  void startPolling() {
    _pollingTimer?.cancel();
    // Chequear inmediatamente y luego cada 30s.
    _checkForNewMessages();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _checkForNewMessages(),
    );
  }

  /// Detiene el polling.
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Verifica cuántos clubes tienen mensajes nuevos.
  Future<void> _checkForNewMessages() async {
    if (_currentUserId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final myClubs = await _repository.listMyClubs();
      int newUnread = 0;

      for (final membership in myClubs) {
        final clubId = membership.clubId;

        // Saltear clubes silenciados.
        if (prefs.getBool('$_mutedPrefix$clubId') == true) continue;

        final lastSeen = prefs.getString('$_lastSeenPrefix$clubId');

        try {
          final page = await _repository.listDiscussions(
            clubId: clubId,
            page: 1,
            pageSize: 1,
          );

          if (page.items.isEmpty) continue;

          final latestMsg = page.items.first;

          // Si no hay lastSeen, marcar como visto (primera vez).
          if (lastSeen == null) {
            await prefs.setString(
              '$_lastSeenPrefix$clubId',
              latestMsg.createdAt.toIso8601String(),
            );
            continue;
          }

          // Si el mensaje más reciente es de otro usuario y es más nuevo
          // que el último visto → hay no leídos.
          if (latestMsg.userId != _currentUserId &&
              latestMsg.createdAt.isAfter(DateTime.parse(lastSeen))) {
            newUnread++;
          }
        } catch (_) {
          // Error en un club — ignorar y seguir con los demás.
        }
      }

      if (newUnread != _unreadCount) {
        _unreadCount = newUnread;
        notifyListeners();
      }
    } catch (_) {
      // Error general — reintentar en el próximo ciclo.
    }
  }

  /// Marca un club como "visto" (el usuario entró al chat).
  Future<void> markClubAsSeen(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_lastSeenPrefix$clubId',
      DateTime.now().toIso8601String(),
    );
    // Recalcular el badge.
    await _checkForNewMessages();
  }

  /// Verifica si un club está silenciado.
  Future<bool> isClubMuted(String clubId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_mutedPrefix$clubId') ?? false;
  }

  /// Silencia o desilencia un club.
  Future<void> setClubMuted(String clubId, bool muted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_mutedPrefix$clubId', muted);
    // Recalcular porque un club silenciado se quita del badge.
    await _checkForNewMessages();
  }

  /// Fuerza un recheck inmediato (por ejemplo al volver de background).
  Future<void> refresh() async {
    await _checkForNewMessages();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
