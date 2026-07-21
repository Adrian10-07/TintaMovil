import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';
import 'package:tinta/core/network/connectivity_checker.dart';

import '../../../recommendations/data/datasources/recommendation_remote_datasource.dart';
import '../../../recommendations/domain/entities/recommendation.dart';
import '../../../tutorAI/data/datasources/remote_tutor_datasource.dart';
import '../../../tutorAI/domain/entities/remote_document.dart';
import '../../../tutorAI/domain/repositories/document_registry.dart';
import '../../../tutorAI/presentation/components/document_indexing_screen.dart';
import '../../../tutorAI/presentation/views/remote_tutor_chat_sheet.dart';
import '../../../tutorAI/presentation/views/tutor_chat_sheet.dart';

// ── NUEVO (de Gael): racha, logros y documentos recientes ────────────
import '../../../home/data/services/streak_service.dart';
import '../../../achievements/data/services/achievement_service.dart';
import '../../../recommendations/data/services/recent_documents_service.dart';
import '../../../user/presentation/viewmodels/user_viewmodel.dart';

final _connectivityChecker = ConnectivityChecker();

/// Vista del visor de documentos (feature: document_viewer).
///
/// Muestra un PDF a pantalla completa con:
///   - Botón ✨ en el AppBar → abre el chat con Tinta AI en modo híbrido
///     (remoto con RAG si hay internet, local con Gemma si no).
///   - FAB → abre el panel de recomendaciones relacionadas.
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

  // ── Tutor IA remoto ────────────────────────────────────────
  RemoteDocument? _remoteDocument;
  String? _tutorError;
  Timer? _pollingTimer;
  bool _uploadInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _initializeTutorForDocument();
    _registerReadingActivity();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String get _fileName =>
      widget.pdfFile.path.split(RegExp(r'[/\\]')).last;

  // ══════════════════════════════════════════════════════════════════
  // RACHA / LOGROS / DOCUMENTOS RECIENTES (de Gael)
  // ══════════════════════════════════════════════════════════════════

  /// El visor de PDF también cuenta como "leer" para la racha — antes
  /// solo se contaba con abrir sesión, ahora se cuenta al entrar de
  /// verdad a un documento (EPUB o PDF).
  Future<void> _registerReadingActivity() async {
    final userVm = sl<UserViewModel>();
    if (userVm.profile == null) {
      await userVm.loadProfile();
    }
    final userId = userVm.profile?.id;
    if (userId == null) return;

    await StreakService.registerVisit(userId);

    final uploads = await RecentDocumentsService.getAll(userId);
    await AchievementService.checkUploads(userId, uploads.length);
  }

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
  // UI — Tutor híbrido
  // ══════════════════════════════════════════════════════════════════

  void _openTutorChat() async {
    // Mostrar feedback inmediato mientras se verifica conectividad, para que
    // el usuario no sienta que el botón no respondió (la verificación puede
    // tardar hasta 2 segundos si no hay red).
    _showLoadingSnackbar('Abriendo tutor…');

    final hasInternet = await _connectivityChecker.hasInternet();

    if (!mounted) return;

    if (hasInternet) {
      _openRemoteTutorChatFlow();
    } else {
      _openLocalTutorChatFlow();
    }
  }

  void _openLocalTutorChatFlow() {
    TutorChatSheet.show(
      context,
      documentContext: _fileName,
    );
  }

  void _openRemoteTutorChatFlow() {
    final doc = _remoteDocument;

    // Sin documento subido aún (o falló la subida) → cae a local en vez de
    // dejar al usuario esperando indefinidamente. Es preferible una
    // respuesta sin RAG del documento a no responder nada.
    if (doc == null) {
      _openLocalTutorChatFlow();
      return;
    }

    if (doc.isReady) {
      RemoteTutorChatSheet.show(
        context,
        documentContext: _fileName,
        remoteDocumentId: doc.id,
      );
      return;
    }

    // Documento aún procesando o falló → sheet de espera (ya existente).
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
    final cs = Theme.of(context).colorScheme;

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
        backgroundColor: cs.primary,
        icon: Icon(Icons.menu_book_rounded, color: cs.onPrimary),
        label: Text(
          count == null ? 'Te puede interesar' : 'Te puede interesar ($count)',
          style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.w700),
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
          initialChildSize: 0.55,
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Te puede interesar',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $error',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    if (items == null) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (items!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                color: cs.primary.withOpacity(0.6),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No encontramos recomendaciones para este libro.\n'
                    'Prueba subiendo otro con un tema distinto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = items![i];
        return _SheetRecommendationTile(recommendation: r);
      },
    );
  }
}

class _SheetRecommendationTile extends StatelessWidget {
  final Recommendation recommendation;

  const _SheetRecommendationTile({required this.recommendation});

  Color _matchColor(ColorScheme cs) {
    final p = recommendation.matchPercent;
    if (p >= 70) return cs.primary;
    if (p >= 40) return cs.tertiary;
    return cs.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = recommendation;
    final matchColor = _matchColor(cs);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 46,
              height: 64,
              child: r.thumbnailUrl != null
                  ? Image.network(
                r.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: cs.primaryContainer,
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: cs.onPrimaryContainer,
                    size: 20,
                  ),
                ),
              )
                  : Container(
                color: cs.primaryContainer,
                child: Icon(
                  Icons.menu_book_rounded,
                  color: cs.onPrimaryContainer,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: matchColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${r.matchPercent}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: matchColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  r.authors.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (r.matchReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    r.matchReason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: cs.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}