import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';
import 'package:tinta/core/network/connectivity_checker.dart';

import '../../../recommendations/data/datasources/recommendation_remote_datasource.dart';
import '../../../tutorAI/data/datasources/remote_tutor_datasource.dart';
import '../../../tutorAI/domain/entities/remote_document.dart';
import '../../../tutorAI/domain/repositories/document_registry.dart';
import '../../../tutorAI/presentation/views/remote_tutor_chat_sheet.dart';
import '../../../tutorAI/presentation/views/tutor_chat_sheet.dart';
import '../../../user/presentation/viewmodels/user_viewmodel.dart';

import '../../domain/usecases/register_reading_activity_usecase.dart';
import '../controllers/recommendations_controller.dart';
import '../controllers/tutor_upload_controller.dart';
import '../components/indexing_sheet_host.dart';
import '../components/recommendations_sheet.dart';

/// Vista del visor de documentos (feature: document_viewer).

class PdfResultsView extends StatefulWidget {
  final File pdfFile;

  const PdfResultsView({super.key, required this.pdfFile});

  @override
  State<PdfResultsView> createState() => _PdfResultsViewState();
}

class _PdfResultsViewState extends State<PdfResultsView> {
  final _connectivityChecker = ConnectivityChecker();

  late final TutorUploadController _tutorController;
  late final RecommendationsController _recommendationsController;

  String get _fileName => widget.pdfFile.path.split(RegExp(r'[/\\]')).last;

  @override
  void initState() {
    super.initState();

    _tutorController = TutorUploadController(
      datasource: sl<RemoteTutorDatasource>(),
      registry: sl<DocumentRegistry>(),
    )..initialize(file: widget.pdfFile, fileName: _fileName);

    _recommendationsController = RecommendationsController(
      dataSource: RecommendationRemoteDataSource(sl<ApiClient>()),
    )..load();

    RegisterReadingActivityUseCase(userViewModel: sl<UserViewModel>()).call();
  }

  @override
  void dispose() {
    _tutorController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  // ======================================================================
  // Tutor híbrido -- decisión online/offline
  // ======================================================================

  Future<void> _openTutorChat() async {
    _showSnack('Abriendo tutor…');

    final hasInternet = await _connectivityChecker.hasInternet();
    if (!mounted) return;

    hasInternet ? _openRemoteTutorChatFlow() : _openLocalTutorChatFlow();
  }

  void _openLocalTutorChatFlow() {
    TutorChatSheet.show(
      context,
      documentContext: _fileName,
      pdfFilePath: widget.pdfFile.path,
    );
  }

  void _openRemoteTutorChatFlow() {
    final doc = _tutorController.remoteDocument;

    if (doc == null) {
      _openLocalTutorChatFlow();
      return;
    }

    if (doc.isReady) {
      RemoteTutorChatSheet.show(
        context,
        documentContext: _fileName,
        remoteDocumentId: doc.id,
        onSwitchToOffline: () {
          Navigator.of(context).pop();
          _openLocalTutorChatFlow();
        },
      );
      return;
    }

    _showIndexingSheet(doc);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
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
        builder: (_, __) => IndexingSheetHost(
          initialDoc: doc,
          onReady: (readyDoc) {
            Navigator.of(sheetCtx).pop();
            RemoteTutorChatSheet.show(
              context,
              documentContext: _fileName,
              remoteDocumentId: readyDoc.id,
            );
          },
          onRetryUpload: () => _tutorController.retryUpload(),
        ),
      ),
    );
  }

  // ======================================================================
  // Recomendaciones
  // ======================================================================

  void _openRecommendationsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => AnimatedBuilder(
          animation: _recommendationsController,
          builder: (_, __) => RecommendationsSheet(
            items: _recommendationsController.items,
            error: _recommendationsController.error,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  // ======================================================================
  // UI
  // ======================================================================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _PdfAppBar(
        fileName: _fileName,
        onOpenTutor: _openTutorChat,
      ),
      body: SafeArea(
        top: false,
        child: PDFView(
          filePath: widget.pdfFile.path,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _recommendationsController,
        builder: (_, __) => FloatingActionButton.extended(
          onPressed: _openRecommendationsSheet,
          backgroundColor: cs.primary,
          icon: Icon(Icons.menu_book_rounded, color: cs.onPrimary),
          label: Text(
            _recommendationsController.items == null
                ? 'Te puede interesar'
                : 'Te puede interesar (${_recommendationsController.items!.length})',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// AppBar con botón de regreso explícito a Home.
///
/// Extraído como widget propio en vez de construirse inline dentro de
/// `build()`: mantiene el método principal corto y legible.
class _PdfAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String fileName;
  final VoidCallback onOpenTutor;

  const _PdfAppBar({required this.fileName, required this.onOpenTutor});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Reemplaza toda la pila de navegación en vez de solo hacer pop():
      // así siempre vuelve a Home, sin importar cómo se llegó aquí (push
      // normal, pushReplacement desde el análisis de subida, o si por
      // algún bug quedaran varias copias apiladas).
      leading: IconButton(
        tooltip: 'Volver al inicio',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
              (route) => false,
        ),
      ),
      title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: 'Pregunta a Tinta AI',
          icon: const Icon(Icons.auto_awesome_rounded),
          onPressed: onOpenTutor,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}