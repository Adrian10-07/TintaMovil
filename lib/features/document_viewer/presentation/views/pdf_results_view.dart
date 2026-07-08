import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';

import '../../../recommendations/data/datasources/recommendation_remote_datasource.dart';
import '../../../recommendations/domain/entities/recommendation.dart';
import '../../../tutorAI/data/datasources/remote_tutor_datasource.dart';
import '../../../tutorAI/domain/entities/remote_document.dart';
import '../../../tutorAI/domain/repositories/document_registry.dart';
import '../../../tutorAI/presentation/components/document_indexing_screen.dart';
import '../../../tutorAI/presentation/views/remote_tutor_chat_sheet.dart';

/// Visor de PDF con integración al tutor IA en modo REMOTO.
///
/// Flujo:
///   1. Al abrir el PDF, calcula su hash SHA-256.
///   2. Consulta el DocumentRegistry local:
///      - Si el hash ya existe: usa el document_id guardado.
///      - Si no: sube el PDF al backend en background y guarda hash→id.
///   3. Hace polling cada 3 seg hasta que el backend termine de indexarlo.
///   4. Cuando el usuario toca ✨:
///      - Si está `ready`: abre RemoteTutorChatSheet con RAG.
///      - Si está `processing`: abre sheet con pantalla de espera.
///      - Si está `failed`: opción de reintentar.
class PdfResultsView extends StatefulWidget {
  final File pdfFile;

  const PdfResultsView({Key? key, required this.pdfFile}) : super(key: key);

  @override
  State<PdfResultsView> createState() => _PdfResultsViewState();
}

class _PdfResultsViewState extends State<PdfResultsView> {
  final _dataSource = RecommendationRemoteDataSource(sl<ApiClient>());

  // ── Recomendaciones (feature existente, sin cambios) ──────
  List<Recommendation>? _items;
  String? _recommendationsError;

  // ── Tutor IA remoto (nuevo) ───────────────────────────────
  RemoteDocument? _remoteDocument;
  String? _tutorError;
  Timer? _pollingTimer;
  bool _uploadInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _initializeTutorForDocument();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String get _fileName =>
      widget.pdfFile.path.split(RegExp(r'[/\\]')).last;

  // ══════════════════════════════════════════════════════════════════
  // RECOMENDACIONES (existente)
  // ══════════════════════════════════════════════════════════════════

  Future<void> _loadRecommendations() async {
    try {
      final result = await _dataSource.fetchRecommendations();
      if (mounted) setState(() => _items = result);
    } catch (e) {
      if (mounted) setState(() => _recommendationsError = e.toString());
    }
  }

  // ══════════════════════════════════════════════════════════════════
  // TUTOR IA — subida proactiva al backend
  // ══════════════════════════════════════════════════════════════════

  Future<void> _initializeTutorForDocument() async {
    try {
      // 1. Hash del PDF para identificarlo unívocamente
      final hash = await _computeSha256(widget.pdfFile);
      final registry = sl<DocumentRegistry>();
      final existingId = await registry.getDocumentIdByHash(hash);

      if (existingId != null) {
        // Ya lo subimos en una sesión anterior; consultar estado
        await _refreshRemoteDocument(existingId);
        _startPollingIfNeeded();
        return;
      }

      // 2. Subir por primera vez (background, no bloquea la UI)
      await _uploadDocument(hash);
    } catch (e) {
      if (mounted) setState(() => _tutorError = e.toString());
    }
  }

  Future<void> _uploadDocument(String hash) async {
    if (_uploadInProgress) return;
    _uploadInProgress = true;

    try {
      final datasource = sl<RemoteTutorDatasource>();
      final registry = sl<DocumentRegistry>();

      final doc = await datasource.uploadDocument(widget.pdfFile);
      await registry.saveMapping(
        hash: hash,
        documentId: doc.id,
        filename: _fileName,
      );

      if (mounted) setState(() => _remoteDocument = doc);
      _startPollingIfNeeded();
    } catch (e) {
      if (mounted) setState(() => _tutorError = e.toString());
    } finally {
      _uploadInProgress = false;
    }
  }

  Future<void> _refreshRemoteDocument(String documentId) async {
    try {
      final datasource = sl<RemoteTutorDatasource>();
      final doc = await datasource.getDocumentStatus(documentId);
      if (mounted) {
        setState(() {
          _remoteDocument = doc;
          _tutorError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _tutorError = e.toString());
    }
  }

  void _startPollingIfNeeded() {
    _pollingTimer?.cancel();
    final doc = _remoteDocument;
    if (doc == null || doc.status.isTerminal) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      await _refreshRemoteDocument(doc.id);
      final updated = _remoteDocument;
      if (updated == null || updated.status.isTerminal) {
        timer.cancel();
      }
    });
  }

  Future<String> _computeSha256(File file) async {
    // Streaming hash: no cargamos el PDF entero a memoria
    final stream = file.openRead();
    final digest = await stream.transform(sha256).single;
    return digest.toString();
  }

  // ══════════════════════════════════════════════════════════════════
  // UI
  // ══════════════════════════════════════════════════════════════════

  void _openTutorChat() {
    final doc = _remoteDocument;

    // Sin doc → mostrar mensaje: aún subiendo
    if (doc == null) {
      _showLoadingSnackbar('El tutor se está preparando…');
      return;
    }

    // Doc listo → abrir chat con RAG
    if (doc.isReady) {
      RemoteTutorChatSheet.show(
        context,
        documentContext: _fileName,
        remoteDocumentId: doc.id,
      );
      return;
    }

    // Doc procesando o fallido → abrir sheet de espera
    _showIndexingSheet(doc);
  }

  void _showLoadingSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showIndexingSheet(RemoteDocument doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, __) => _IndexingSheetHost(
          initialDoc: doc,
          onReady: (readyDoc) {
            Navigator.of(sheetCtx).pop();
            RemoteTutorChatSheet.show(
              context,
              documentContext: _fileName,
              remoteDocumentId: readyDoc.id,
            );
          },
          onRetryUpload: () async {
            Navigator.of(sheetCtx).pop();
            final hash = await _computeSha256(widget.pdfFile);
            final registry = sl<DocumentRegistry>();
            await registry.removeByHash(hash);
            setState(() => _remoteDocument = null);
            await _uploadDocument(hash);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _items?.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Pregunta a Tinta AI',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: _openTutorChat,
          ),
        ],
      ),
      body: PDFView(
        filePath: widget.pdfFile.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openRecommendationsSheet(context),
        icon: const Icon(Icons.menu_book_rounded),
        label: Text(
          count == null ? 'Te puede interesar' : 'Te puede interesar ($count)',
        ),
      ),
    );
  }

  void _openRecommendationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return _RecommendationsSheetContent(
              items: _items,
              error: _recommendationsError,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Sheet de espera con polling interno
// ══════════════════════════════════════════════════════════════════════

class _IndexingSheetHost extends StatefulWidget {
  final RemoteDocument initialDoc;
  final void Function(RemoteDocument ready) onReady;
  final VoidCallback onRetryUpload;

  const _IndexingSheetHost({
    required this.initialDoc,
    required this.onReady,
    required this.onRetryUpload,
  });

  @override
  State<_IndexingSheetHost> createState() => _IndexingSheetHostState();
}

class _IndexingSheetHostState extends State<_IndexingSheetHost> {
  late RemoteDocument _doc;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _doc = widget.initialDoc;
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (_doc.status.isTerminal) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      try {
        final updated =
        await sl<RemoteTutorDatasource>().getDocumentStatus(_doc.id);
        if (!mounted) return;
        setState(() => _doc = updated);
        if (updated.isReady) {
          t.cancel();
          widget.onReady(updated);
        } else if (updated.isFailed) {
          t.cancel();
        }
      } catch (_) {
        // Errores transitorios: seguimos intentando
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DocumentIndexingScreen(
      document: _doc,
      onCancel: () => Navigator.of(context).pop(),
      onRetry: widget.onRetryUpload,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// Recomendaciones (existente, sin cambios)
// ══════════════════════════════════════════════════════════════════════

class _RecommendationsSheetContent extends StatelessWidget {
  final List<Recommendation>? items;
  final String? error;
  final ScrollController scrollController;

  const _RecommendationsSheetContent({
    required this.items,
    required this.error,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('Te puede interesar', style: textTheme.titleMedium),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (error != null) {
      return Center(child: Text('Error: $error'));
    }
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items!.isEmpty) {
      return const Center(child: Text('Aún no hay recomendaciones.'));
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items!.length,
      itemBuilder: (_, i) {
        final r = items![i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            '${i + 1}. ${r.title} — ${r.authors.join(', ')}',
            style: const TextStyle(fontSize: 15),
          ),
        );
      },
    );
  }
}
