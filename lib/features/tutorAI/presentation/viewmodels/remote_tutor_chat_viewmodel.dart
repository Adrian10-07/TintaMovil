import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/friendly_error.dart';
import '../../data/datasources/remote_tutor_datasource.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/tutor_source.dart';

/// ViewModel del chat en MODO REMOTO.
///
/// `remoteDocumentId` ahora es OPCIONAL: si es null, el chat funciona en
/// modo "conversación general" contra el backend (sin RAG de un
/// documento específico) — usado por ejemplo desde ReaderView, donde
/// los libros son EPUB y el backend solo indexa PDF por ahora.
class RemoteTutorChatViewModel extends ChangeNotifier {
  final RemoteTutorDatasource _datasource;

  final String? documentContext;

  /// Null = chat general sin RAG de documento (ej. desde ReaderView).
  final String? remoteDocumentId;

  RemoteTutorChatViewModel(
      this._datasource, {
        this.remoteDocumentId,
        this.documentContext,
      });

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  final Map<String, List<TutorSource>> _sourcesByMessageId = {};
  List<TutorSource> sourcesFor(String messageId) =>
      _sourcesByMessageId[messageId] ?? const [];

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String? _error;
  String? get error => _error;

  /// True si el último error parece ser de conectividad (sin internet,
  /// timeout). La UI usa esto para ofrecer el botón "Cambiar a modo sin
  /// conexión" en vez de un botón genérico de reintentar.
  bool _isConnectivityIssue = false;
  bool get isConnectivityIssue => _isConnectivityIssue;

  bool get canSend => !_isGenerating;

  StreamSubscription<RemoteChatEvent>? _generationSub;

  Future<void> sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || !canSend) return;

    final userMsg = ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: clean,
      timestamp: DateTime.now(),
    );
    _messages.add(userMsg);

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
    _isConnectivityIssue = false;
    notifyListeners();

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

    final recentHistory = _messages
        .where((m) => !m.isStreaming)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .toList();

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
        _handleError(err);
      },
    );
  }

  void _handleError(Object rawError) {
    _error = friendlyErrorMessage(rawError);
    _isConnectivityIssue = isConnectivityError(rawError);
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
