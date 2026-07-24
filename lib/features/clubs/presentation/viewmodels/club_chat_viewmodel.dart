import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/discussion.dart';
import '../../domain/repositories/club_repository.dart';
import '../../data/services/moderation_service.dart';
import '../../data/services/websocket_service.dart';
import '../../data/services/user_cache_service.dart';

/// Estados del chat.
enum ChatState { initial, loading, loaded, error, empty }

/// ViewModel para el chat dentro de un club.
class ClubChatViewModel extends ChangeNotifier {
  final ClubRepository _repository;
  final ModerationService _moderation;
  final WebSocketService _ws;
  final UserCacheService _userCache;
  final String clubId;
  final String currentUserId;

  ClubChatViewModel({
    required ClubRepository repository,
    required ModerationService moderation,
    required WebSocketService ws,
    required UserCacheService userCache,
    required this.clubId,
    required this.currentUserId,
  })  : _repository = repository,
        _moderation = moderation,
        _ws = ws,
        _userCache = userCache;

  // ── Estado ──────────────────────────────────────────────────────────────

  ChatState _state = ChatState.initial;
  ChatState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Discussion> _messages = [];
  List<Discussion> get messages => _messages;

  int? _filterChapter;
  int? get filterChapter => _filterChapter;

  int _currentPage = 1;
  bool _hasMoreOlder = true;
  bool get hasMoreOlder => _hasMoreOlder;
  bool _isLoadingOlder = false;
  bool get isLoadingOlder => _isLoadingOlder;

  bool _isSending = false;
  bool get isSending => _isSending;

  StreamSubscription<Discussion>? _wsSub;

  // ── Ciclo de vida ─────────────────────────────────────────────────────

  /// Inicializa el chat: carga caché → sync con servidor → conecta WS.
  Future<void> initialize() async {
    _state = ChatState.loading;
    notifyListeners();

    try {
      // 1. Cargar mensajes del caché local (respuesta inmediata).
      final cached = await _repository.getCachedDiscussions(clubId);
      if (cached.isNotEmpty) {
        _messages = await _enrichMessages(cached);
        _state = ChatState.loaded;
        notifyListeners();
      }

      // 2. Sincronizar con el servidor (mensajes nuevos).
      await _syncFromServer();

      // 3. Conectar al stream de tiempo real.
      _connectRealTime();

      _state = _messages.isEmpty ? ChatState.empty : ChatState.loaded;
    } catch (e) {
      // Si falla la red pero hay caché, seguir mostrando mensajes.
      // Si no hay nada, mostrar estado vacío (no error) para que pueda escribir.
      if (_messages.isEmpty) {
        _state = ChatState.empty;
        _errorMessage = null; // No bloquear la UI — el usuario puede intentar enviar.
      }
    }

    notifyListeners();
  }

  /// Limpia recursos al cerrar el chat.
  void dispose() {
    _wsSub?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  // ── Envío de mensajes ─────────────────────────────────────────────────

  /// Envía un mensaje al chat.
  ///
  /// Flujo: validar → moderar client-side → enviar al server → actualizar UI.
  /// Retorna null si OK, o un mensaje de error.
  Future<String?> sendMessage(String content) async {
    // 1. Validación básica.
    final validationError = _moderation.validate(content);
    if (validationError != null) return validationError;

    // 2. Moderación client-side.
    final modResult = _moderation.moderate(content, currentChapter: _filterChapter);
    if (modResult.isBlocked) {
      return modResult.reason ?? 'Mensaje no permitido.';
    }

    // 3. Enviar al servidor.
    _isSending = true;
    notifyListeners();

    try {
      var discussion = await _repository.postDiscussion(
        clubId: clubId,
        content: content.trim(),
        chapterNumber: _filterChapter,
      );

      // 4. Aplicar flag de spoiler si lo detectó el client.
      if (modResult.isSpoiler) {
        discussion = discussion.copyWith(
          moderationFlag: ModerationFlag.spoiler,
        );
      }

      // 5. Agregar al inicio de la lista (más nuevo primero).
      discussion = discussion.copyWith(isMine: true);
      _messages.insert(0, discussion);

      if (_state == ChatState.empty) _state = ChatState.loaded;

      _isSending = false;
      notifyListeners();
      return null; // Éxito
    } catch (e) {
      _isSending = false;
      notifyListeners();
      return e.toString();
    }
  }

  // ── Carga de mensajes antiguos (scroll infinito) ──────────────────────

  /// Carga la siguiente página de mensajes más antiguos.
  Future<void> loadOlderMessages() async {
    if (_isLoadingOlder || !_hasMoreOlder) return;
    _isLoadingOlder = true;
    notifyListeners();

    try {
      _currentPage++;
      final page = await _repository.listDiscussions(
        clubId: clubId,
        page: _currentPage,
        pageSize: 50,
        chapterNumber: _filterChapter,
      );

      final enriched = _enrichMessages(page.items);
      _messages.addAll(await enriched);
      _hasMoreOlder = page.hasMore;
    } catch (e) {
      _currentPage--; // Revertir para reintentar.
    }

    _isLoadingOlder = false;
    notifyListeners();
  }

  // ── Filtro por capítulo ───────────────────────────────────────────────

  /// Cambia el filtro de capítulo y recarga mensajes.
  Future<void> setChapterFilter(int? chapter) async {
    if (_filterChapter == chapter) return;
    _filterChapter = chapter;
    _messages = [];
    _currentPage = 1;
    _hasMoreOlder = true;
    notifyListeners();
    await initialize();
  }

  // ── Edición y eliminación ─────────────────────────────────────────────

  /// Edita un mensaje propio.
  Future<bool> editMessage(String discussionId, String newContent) async {
    final validationError = _moderation.validate(newContent);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    try {
      final updated =
      await _repository.updateDiscussion(discussionId, newContent.trim());
      final index = _messages.indexWhere((m) => m.id == discussionId);
      if (index != -1) {
        _messages[index] = updated.copyWith(isMine: true);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Elimina un mensaje propio.
  Future<bool> deleteMessage(String discussionId) async {
    try {
      await _repository.deleteDiscussion(discussionId);
      _messages.removeWhere((m) => m.id == discussionId);
      if (_messages.isEmpty) _state = ChatState.empty;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Vaciar chat ───────────────────────────────────────────────────────

  /// Vacía todo el historial del chat (solo owner/moderator).
  Future<bool> clearChat() async {
    try {
      await _repository.clearDiscussions(clubId);
      _messages = [];
      _state = ChatState.empty;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Refresh ───────────────────────────────────────────────────────────

  /// Pull-to-refresh: recarga desde el servidor.
  Future<void> refresh() async {
    _currentPage = 1;
    _hasMoreOlder = true;
    await _syncFromServer();
    if (_messages.isEmpty) {
      _state = ChatState.empty;
    } else {
      _state = ChatState.loaded;
    }
    notifyListeners();
  }

  /// Limpia el error actual.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Internos ──────────────────────────────────────────────────────────

  /// Sincroniza mensajes desde el servidor.
  Future<void> _syncFromServer() async {
    try {
      final page = await _repository.listDiscussions(
        clubId: clubId,
        page: 1,
        pageSize: 50,
        chapterNumber: _filterChapter,
      );

      final enriched = await _enrichMessages(page.items);
      _mergeMessages(enriched);
      _hasMoreOlder = page.hasMore;
    } catch (_) {
      // Auth o red falla — no bloquear, el usuario puede seguir con caché o enviar.
    }
  }

  /// Conecta al stream de mensajes en tiempo real.
  void _connectRealTime() {
    _ws.setFetchCallback((clubId, {int page = 1, int pageSize = 20}) {
      return _repository
          .listDiscussions(
          clubId: clubId, page: page, pageSize: pageSize)
          .then((p) => p.items);
    });

    _wsSub = _ws.messages.listen(_onRealtimeMessage);
    _ws.connect(clubId);
  }

  /// Maneja un mensaje recibido en tiempo real.
  void _onRealtimeMessage(Discussion message) async {
    if (_messages.any((m) => m.id == message.id)) return;
    if (_filterChapter != null && message.chapterNumber != _filterChapter) return;

    final isMine = message.userId == currentUserId;
    String? userName;
    if (!isMine) {
      userName = await _userCache.getUserName(message.userId);
    }

    final enriched = message.copyWith(isMine: isMine, userName: userName);
    _messages.insert(0, enriched);
    _repository.cacheDiscussions([message]);

    if (_state == ChatState.empty) _state = ChatState.loaded;
    notifyListeners();
  }

  /// Enriquece los mensajes con nombre de usuario real y flag isMine.
  Future<List<Discussion>> _enrichMessages(List<Discussion> messages) async {
    // Resolver nombres de usuarios únicos en paralelo.
    final userIds = messages
        .where((m) => m.userId != currentUserId)
        .map((m) => m.userId)
        .toSet();
    final names = await _userCache.resolveNames(userIds);

    return messages.map((m) {
      return m.copyWith(
        isMine: m.userId == currentUserId,
        userName: m.userId == currentUserId ? null : names[m.userId],
      );
    }).toList();
  }

  /// Mezcla mensajes nuevos con los existentes sin duplicados.
  void _mergeMessages(List<Discussion> incoming) {
    final existingIds = _messages.map((m) => m.id).toSet();
    final newMessages =
    incoming.where((m) => !existingIds.contains(m.id)).toList();

    if (newMessages.isEmpty) return;

    _messages.insertAll(0, newMessages);
    // Reordenar por fecha (más nuevo primero).
    _messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}