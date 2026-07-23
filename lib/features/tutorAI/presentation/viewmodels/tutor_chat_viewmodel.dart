import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/services/in_memory_rag_service.dart';
import '../../../knowledge_base/data/services/pdf_text_extractor.dart' show PageText;
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import '../../domain/repositories/tutor_repository.dart';

/// Mensaje que se muestra cuando la pregunta no tiene relación con el
/// documento (ningún chunk supera el umbral de similitud). Igual que
/// OUT_OF_SCOPE_MESSAGE en el backend remoto, evita que el LLM local
/// alucine una respuesta ajena al PDF.
const _kOutOfScopeMessage =
    'Esa pregunta no parece estar relacionada con el documento que estás '
    'leyendo. Intenta preguntarme algo sobre su contenido, o si quieres '
    'ayuda con otro tema, dímelo explícitamente.';

/// Umbral de similitud coseno para TF-IDF. Es más bajo que el usado con
/// embeddings densos (MiniLM ~0.38) porque los vectores TF-IDF son
/// sparse y basados en solapamiento literal de vocabulario — valores
/// "altos" en este esquema rondan 0.15-0.3 incluso para textos muy
/// relacionados. Es un punto de partida empírico, no un valor exacto;
/// ajustar si se ve que rechaza preguntas válidas o deja pasar ajenas.
const double _kMinSimilarity = 0.08;

/// ViewModel del chat con el tutor IA local (Gemma on-device).
///
/// Mantiene el historial de mensajes, el estado de descarga del modelo,
/// y — cuando hay un documento asociado — un índice RAG en memoria
/// (TF-IDF, sin persistencia en disco) para evitar que el modelo
/// responda con conocimiento general cuando la pregunta no tiene
/// relación con el PDF que el usuario está leyendo.
class TutorChatViewModel extends ChangeNotifier {
  final TutorRepository _repository;
  final InMemoryRagService _ragService;

  String? documentContext;
  String? _documentFilePath;

  TutorChatViewModel(this._repository, this._ragService) {
    _listenToModelStatus();
  }

  /// Actualiza el contexto del documento actual sin borrar el historial.
  void setContext(String? ctx) {
    if (documentContext != ctx) {
      documentContext = ctx;
      notifyListeners();
    }
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

  // ── Estado de indexación (RAG local en memoria) ────────────────────
  bool _isIndexing = false;
  bool get isIndexing => _isIndexing;

  bool _isDocumentIndexed = false;
  bool get isDocumentIndexed => _isDocumentIndexed;

  String? _activeDocumentHash;
  String? get activeDocumentHash => _activeDocumentHash;

  // ── Suscripciones internas ─────────────────────────────────────────
  StreamSubscription<ModelDownloadStatus>? _statusSub;
  StreamSubscription<String>? _generationSub;

  void _listenToModelStatus() {
    _statusSub = _repository.downloadStatus.listen((status) {
      _modelStatus = status;
      notifyListeners();
    });
  }

  Future<void> initializeModel() async {
    try {
      _error = null;
      await _repository.ensureModelReady();
    } catch (e) {
      _error = 'No se pudo cargar el tutor IA: $e';
      notifyListeners();
    }
  }

  /// Indexa el PDF actual en memoria (extracción + chunking + TF-IDF),
  /// sin tocar SQLite. Seguro de llamar varias veces: si el documento ya
  /// fue indexado en esta sesión, no repite el trabajo.
  /// Indexa el PDF actual en memoria (extracción + chunking + TF-IDF),
  /// sin tocar SQLite. Si el documento es DISTINTO al que estaba activo,
  /// limpia el historial de mensajes — evita que el LLM mezcle contexto
  /// de conversaciones sobre libros distintos.
  Future<void> indexCurrentDocument(String filePath) async {
    if (_isIndexing) return;

    final hash = await InMemoryRagService.computeFileHash(filePath);

    // Documento distinto al que estaba activo → conversación nueva.
    if (_activeDocumentHash != null && _activeDocumentHash != hash) {
      _messages.clear();
      _isDocumentIndexed = false;
    }

    _isIndexing = true;
    notifyListeners();

    try {
      _documentFilePath = filePath;
      _activeDocumentHash = hash;

      final chunks = await _ragService.ensureIndexed(
        filePath: filePath,
        documentHash: hash,
      );

      _isDocumentIndexed = chunks.isNotEmpty;
    } catch (e) {
      _error = 'Error al indexar documento: $e';
      _isDocumentIndexed = false;
    } finally {
      _isIndexing = false;
      notifyListeners();
    }
  }

  /// Igual que [indexCurrentDocument], pero para EPUB.
  Future<void> indexCurrentDocumentFromEpub({
    required String bookTitle,
    required List<String> chapterHtmlContents,
  }) async {
    if (_isIndexing) return;

    final hash = InMemoryRagService.computeTextHash(
      '$bookTitle-${chapterHtmlContents.length}',
    );

    // Documento distinto al que estaba activo → conversación nueva.
    if (_activeDocumentHash != null && _activeDocumentHash != hash) {
      _messages.clear();
      _isDocumentIndexed = false;
    }

    _isIndexing = true;
    notifyListeners();

    try {
      _activeDocumentHash = hash;

      final pages = <PageText>[];
      for (var i = 0; i < chapterHtmlContents.length; i++) {
        final plainText = InMemoryRagService.stripHtml(chapterHtmlContents[i]);
        if (plainText.isNotEmpty) {
          pages.add(PageText(pageNumber: i + 1, text: plainText));
        }
      }

      final chunks = await _ragService.ensureIndexedFromPages(
        pages: pages,
        documentHash: hash,
      );

      _isDocumentIndexed = chunks.isNotEmpty;
    } catch (e) {
      _error = 'Error al indexar el libro: $e';
      _isDocumentIndexed = false;
    } finally {
      _isIndexing = false;
      notifyListeners();
    }
  }

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

    // ── RAG local: buscar chunks relevantes si hay documento indexado ──
    List<String>? relevantChunks;
    bool outOfScope = false;

    if (_isDocumentIndexed && _activeDocumentHash != null) {
      try {
        final isBroad = InMemoryRagService.isBroadQuestion(clean);
        final chunks = _ragService.search(
          query: clean,
          documentHash: _activeDocumentHash!,
          topK: isBroad ? 6 : 3,
          // Preguntas amplias (resumen, tema central) no se parecen a
          // ningún chunk puntual — se ignora el umbral para ellas.
          minSimilarity: isBroad ? 0.0 : _kMinSimilarity,
        );

        if (chunks.isNotEmpty) {
          relevantChunks = chunks.map((c) => c.content).toList();
        } else if (!isBroad) {
          // Documento indexado, pregunta puntual, CERO chunks relevantes
          // → la pregunta no tiene relación con el documento.
          outOfScope = true;
        }
      } catch (_) {
        // Si el RAG local falla, seguimos sin contexto (fallback graceful)
        // en vez de romper la conversación completa.
      }
    }

    // ── Corte temprano: pregunta fuera de alcance del documento ────────
    if (outOfScope) {
      final idx = _messages.length - 1;
      _messages[idx] = _messages[idx].copyWith(
        content: _kOutOfScopeMessage,
        isStreaming: false,
      );
      _isGenerating = false;
      notifyListeners();
      return;
    }

    // ── Batching de tokens cada 60ms ────────────────────────────────
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

    _generationSub = _repository
        .generateResponse(
      history: recentHistory,
      documentContext: documentContext,
      relevantChunks: relevantChunks,
    )
        .listen(
          (token) {
        buffer.write(token);
        hasNewTokens = true;
      },
      onDone: () {
        batchTimer?.cancel();
        flushBuffer();

        final idx = _messages.length - 1;
        _messages[idx] = _messages[idx].copyWith(
          content: buffer.toString(),
          isStreaming: false,
        );
        _isGenerating = false;
        notifyListeners();
      },
      onError: (err) {
        batchTimer?.cancel();
        _error = 'Error al generar respuesta: $err';
        _isGenerating = false;
        if (_messages.isNotEmpty &&
            _messages.last.isAssistant &&
            _messages.last.content.isEmpty) {
          _messages.removeLast();
        }
        notifyListeners();
      },
    );
  }

  Future<void> retryDownload() async {
    _error = null;
    notifyListeners();
    await initializeModel();
  }

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
