import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import '../../domain/repositories/tutor_repository.dart';

/// ViewModel del chat con el tutor IA.
///
/// Mantiene:
///   - El historial de mensajes en memoria.
///   - El estado de la descarga/carga del modelo.
///   - El estado de "generando respuesta" para mostrar typing indicator.
///
/// Convive con el patrón usado en `home_viewmodel.dart` y demás:
/// extiende [ChangeNotifier], expone getters de solo lectura, y mutaciones
/// vía métodos públicos que terminan con `notifyListeners()`.
class TutorChatViewModel extends ChangeNotifier {
  final TutorRepository _repository;
  final String? documentContext;

  TutorChatViewModel(this._repository, {this.documentContext}) {
    _listenToModelStatus();
  }

  // ── Estado expuesto a la UI ────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  ModelDownloadStatus _modelStatus =
      const ModelDownloadStatus(stage: ModelDownloadStage.idle);
  ModelDownloadStatus get modelStatus => _modelStatus;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _error;
  String? get error => _error;

  bool get canSend => _modelStatus.isReady && !_isGenerating;

  // ── Suscripciones internas ─────────────────────────────────────────
  StreamSubscription<ModelDownloadStatus>? _statusSub;
  StreamSubscription<String>? _generationSub;

  void _listenToModelStatus() {
    _statusSub = _repository.downloadStatus.listen((status) {
      _modelStatus = status;
      notifyListeners();
    });
  }

  /// Inicia la descarga/carga del modelo si aún no está listo.
  /// Se llama desde la pantalla al abrir el chat por primera vez.
  Future<void> initializeModel() async {
    try {
      _error = null;
      await _repository.ensureModelReady();
    } catch (e) {
      _error = 'No se pudo cargar el tutor IA: $e';
      notifyListeners();
    }
  }

  /// Envía un mensaje del usuario y dispara la generación de respuesta.
  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || !canSend) return;

    // 1. Agregar el mensaje del usuario al historial.
    final userMsg = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: clean,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // 2. Crear placeholder vacío del asistente que iremos llenando con tokens.
    final assistantMsg = ChatMessage(
      id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(assistantMsg);

    _isGenerating = true;
    _error = null;
    notifyListeners();

    // 3. Suscribirnos al stream de tokens y actualizar el mensaje en cada uno.
    final buffer = StringBuffer();

    _generationSub = _repository
        .generateResponse(
          history: _messages.where((m) => !m.isStreaming).toList(),
          documentContext: documentContext,
        )
        .listen(
          (token) {
            buffer.write(token);
            // Reemplazar el último mensaje (que es el placeholder del asistente)
            // con uno nuevo que tiene el texto acumulado.
            final idx = _messages.length - 1;
            _messages[idx] = _messages[idx].copyWith(
              content: buffer.toString(),
            );
            notifyListeners();
          },
          onDone: () {
            // Marcar el mensaje como completo (sin streaming).
            final idx = _messages.length - 1;
            _messages[idx] = _messages[idx].copyWith(isStreaming: false);
            _isGenerating = false;
            notifyListeners();
          },
          onError: (err) {
            _error = 'Error al generar respuesta: $err';
            _isGenerating = false;
            // Quitar el placeholder vacío.
            if (_messages.isNotEmpty &&
                _messages.last.isAssistant &&
                _messages.last.content.isEmpty) {
              _messages.removeLast();
            }
            notifyListeners();
          },
        );
  }

  /// Reintenta la descarga después de un fallo.
  Future<void> retryDownload() async {
    _error = null;
    notifyListeners();
    await initializeModel();
  }

  /// Limpia el historial del chat (no afecta al modelo).
  void clearChat() {
    _messages.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _generationSub?.cancel();
    super.dispose();
  }
}
