import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/datasources/remote_tutor_datasource.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/tutor_source.dart';

/// ViewModel del chat en MODO REMOTO.
///
/// A diferencia del `TutorChatViewModel` original (que usa el LLM local +
/// TF-IDF), este ViewModel llama directamente al microservicio tutor-ai en
/// Railway. El backend hace su propio RAG con embeddings y responde por SSE.
///
/// Este ViewModel se usa cuando el usuario abre el chat DESDE un PDF y el
/// backend ya tiene ese PDF indexado (status = ready). En cualquier otro
/// caso se cae al ViewModel local.
class RemoteTutorChatViewModel extends ChangeNotifier {
  final RemoteTutorDatasource _datasource;

  /// Nombre del PDF actual (mostrar en la UI).
  final String? documentContext;

  /// ID del documento indexado en el backend. Requerido para RAG.
  final String remoteDocumentId;

  RemoteTutorChatViewModel(
    this._datasource, {
    required this.remoteDocumentId,
    this.documentContext,
  });

  // ══════════════════════════════════════════════════════════════════
  // ESTADO EXPUESTO A LA UI
  // ══════════════════════════════════════════════════════════════════

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Mapa messageId → sources citadas.
  final Map<String, List<TutorSource>> _sourcesByMessageId = {};
  List<TutorSource> sourcesFor(String messageId) =>
      _sourcesByMessageId[messageId] ?? const [];

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _error;
  String? get error => _error;

  bool get canSend => !_isGenerating;

  StreamSubscription<RemoteChatEvent>? _generationSub;

  // ══════════════════════════════════════════════════════════════════
  // ENVIAR MENSAJE
  // ══════════════════════════════════════════════════════════════════

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || !canSend) return;

    // 1. Mensaje del usuario
    final userMsg = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: clean,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

    // 2. Placeholder del asistente
    final assistantMsgId =
        'assistant-${DateTime.now().millisecondsSinceEpoch}';
    final assistantMsg = ChatMessage(
      id: assistantMsgId,
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    _messages.add(assistantMsg);

    _isGenerating = true;
    _error = null;
    notifyListeners();

    // 3. Batching de tokens cada 60ms para no saturar el UI thread
    final buffer = StringBuffer();
    Timer? batchTimer;
    bool hasNewTokens = false;

    void flushBuffer() {
      if (!hasNewTokens) return;
      final idx = _messages.length - 1;
      _messages[idx] = _messages[idx].copyWith(content: buffer.toString());
      notifyListeners();
      hasNewTokens = false;
    }

    batchTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      flushBuffer();
    });

    // 4. Truncar historial a los últimos 6 mensajes para no exceder el contexto
    final recentHistory = _messages
        .where((m) => !m.isStreaming)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .toList();

    // 5. Suscribirse al stream remoto
    _generationSub = _datasource
        .chat(
      question: clean,
      documentId: remoteDocumentId,
      history: recentHistory,
    )
        .listen(
      (event) {
        switch (event) {
          case RemoteTokenEvent(:final token):
            buffer.write(token);
            hasNewTokens = true;
          case RemoteDoneEvent(:final sources):
            batchTimer?.cancel();
            flushBuffer();

            final idx = _messages.length - 1;
            _messages[idx] = _messages[idx].copyWith(
              content: buffer.toString(),
              isStreaming: false,
            );
            if (sources.isNotEmpty) {
              _sourcesByMessageId[assistantMsgId] = sources;
            }
            _isGenerating = false;
            notifyListeners();
          case RemoteErrorEvent(:final message):
            batchTimer?.cancel();
            _handleError(message);
        }
      },
      onError: (err) {
        batchTimer?.cancel();
        _handleError('$err');
      },
    );
  }

  void _handleError(String message) {
    _error = message;
    _isGenerating = false;
    if (_messages.isNotEmpty &&
        _messages.last.isAssistant &&
        _messages.last.content.isEmpty) {
      _messages.removeLast();
    }
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _sourcesByMessageId.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _generationSub?.cancel();
    super.dispose();
  }
}
