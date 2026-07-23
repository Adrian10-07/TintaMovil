import 'dart:async';
import 'dart:convert';

import '../../domain/entities/discussion.dart';
import '../models/discussion_model.dart';

/// Estado de la conexión WebSocket.
enum WsConnectionState { disconnected, connecting, connected, reconnecting }

/// Servicio de WebSocket para chat en tiempo real.
///
/// Gestiona la conexión a un único club a la vez, con reconexión automática
/// y parsing de mensajes entrantes.
///
/// Actualmente usa polling como fallback ya que el backend puede no tener
/// WebSocket implementado aún. En ese caso, el ViewModel usa el REST API
/// con un Timer periódico. Esta clase está preparada para cuando el
/// backend soporte WS.
class WebSocketService {
  static const String _wsBaseUrl =
      'wss://tinta-community.up.railway.app/api/v1';

  /// Club al que estamos conectados actualmente.
  String? _currentClubId;

  /// Token JWT para autenticación WS.
  String? _authToken;

  /// Stream controller para mensajes entrantes.
  final _messageController = StreamController<Discussion>.broadcast();

  /// Stream controller para el estado de conexión.
  final _stateController =
  StreamController<WsConnectionState>.broadcast();

  /// Estado actual de la conexión.
  WsConnectionState _state = WsConnectionState.disconnected;

  /// Timer para reconnect con exponential backoff.
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  /// Timer para polling fallback.
  Timer? _pollingTimer;

  /// Callback para obtener mensajes vía REST (polling fallback).
  Future<List<Discussion>> Function(String clubId, {int page, int pageSize})?
  _fetchMessages;

  /// Último timestamp recibido para polling incremental.
  DateTime? _lastReceivedAt;

  // ── API Pública ─────────────────────────────────────────────────────────

  /// Stream de mensajes entrantes en tiempo real.
  Stream<Discussion> get messages => _messageController.stream;

  /// Stream del estado de conexión.
  Stream<WsConnectionState> get connectionState => _stateController.stream;

  /// Estado actual.
  WsConnectionState get state => _state;

  /// Si estamos conectados a algún club.
  bool get isConnected => _state == WsConnectionState.connected;

  /// Configura el token de autenticación.
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Configura el callback de polling fallback.
  void setFetchCallback(
      Future<List<Discussion>> Function(String clubId,
          {int page, int pageSize})
      callback,
      ) {
    _fetchMessages = callback;
  }

  /// Conecta al chat de un club.
  ///
  /// Si ya estaba conectado a otro club, desconecta primero.
  Future<void> connect(String clubId) async {
    if (_currentClubId == clubId && isConnected) return;

    await disconnect();
    _currentClubId = clubId;
    _reconnectAttempts = 0;

    // Por ahora, usar polling como implementación principal.
    // Cuando el backend soporte WebSocket, se activará _connectWebSocket.
    _startPolling(clubId);
  }

  /// Desconecta del club actual.
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _currentClubId = null;
    _lastReceivedAt = null;
    _reconnectAttempts = 0;
    _setState(WsConnectionState.disconnected);
  }

  /// Envía un mensaje por WebSocket.
  ///
  /// En modo polling, este método no hace nada — el envío se hace por REST
  /// y el polling se encarga de recoger el mensaje.
  void sendMessage(Map<String, dynamic> payload) {
    // Reservado para cuando se implemente WebSocket real.
    // En modo polling, el ViewModel envía por REST directamente.
  }

  /// Limpia recursos al destruir el servicio.
  void dispose() {
    disconnect();
    _messageController.close();
    _stateController.close();
  }

  // ── Polling fallback ──────────────────────────────────────────────────

  void _startPolling(String clubId) {
    _setState(WsConnectionState.connected);
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _pollMessages(clubId),
    );
  }

  int _consecutiveErrors = 0;

  Future<void> _pollMessages(String clubId) async {
    if (_fetchMessages == null || clubId != _currentClubId) return;

    // Detener polling después de 3 errores consecutivos (evita spam de logs).
    if (_consecutiveErrors >= 3) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      _setState(WsConnectionState.disconnected);
      return;
    }

    try {
      final messages =
      await _fetchMessages!(clubId, page: 1, pageSize: 20);

      for (final msg in messages) {
        // Solo emitir mensajes más nuevos que el último recibido.
        if (_lastReceivedAt == null ||
            msg.createdAt.isAfter(_lastReceivedAt!)) {
          _messageController.add(msg);
        }
      }

      if (messages.isNotEmpty) {
        _lastReceivedAt = messages
            .map((m) => m.createdAt)
            .reduce((a, b) => a.isAfter(b) ? a : b);
      }

      _consecutiveErrors = 0; // Reset en éxito.
    } catch (_) {
      _consecutiveErrors++;
    }
  }

  // ── WebSocket real (preparado para futuro) ─────────────────────────────

  // ignore: unused_element
  void _handleWsMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json['type'] as String?;

      switch (type) {
        case 'new_message':
          final data = json['data'] as Map<String, dynamic>;
          _messageController.add(DiscussionModel.fromJson(data));
          break;
        case 'message_deleted':
        // El ViewModel se encargará de remover del estado local.
          break;
        case 'chat_cleared':
        // El ViewModel limpiará el historial.
          break;
      }
    } catch (_) {
      // Mensaje malformado — ignorar.
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _setState(WsConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
  }

  String _buildWsUrl(String clubId) {
    final token = _authToken ?? '';
    return '$_wsBaseUrl/clubs/$clubId/ws?token=$token';
  }
}