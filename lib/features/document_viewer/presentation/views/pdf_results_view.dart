import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../recommendations/data/datasources/recommendation_remote_datasource.dart';
import '../../../recommendations/domain/entities/recommendation.dart';
import '../../../tutorAI/presentation/views/tutor_chat_sheet.dart';
import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';

/// Vista del visor de documentos (feature: document_viewer).
///
/// Muestra un PDF a pantalla completa con:
///   - Botón ✨ en el AppBar → abre el chat con Tinta AI (modo documento).
///   - FAB → abre el panel de recomendaciones relacionadas.
class PdfResultsView extends StatefulWidget {
  final File pdfFile;

  const PdfResultsView({Key? key, required this.pdfFile}) : super(key: key);

  @override
  State<PdfResultsView> createState() => _PdfResultsViewState();
}

class _PdfResultsViewState extends State<PdfResultsView> {
  final _dataSource = RecommendationRemoteDataSource(sl<ApiClient>());

  List<Recommendation>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final result = await _dataSource.fetchRecommendations();
      if (mounted) setState(() => _items = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  /// Nombre del archivo sin la ruta, para pasarlo al tutor como contexto.
  String get _fileName =>
      widget.pdfFile.path.split('/').last.split('\\').last;

  void _openTutorChat() {
    TutorChatSheet.show(
      context,
      documentContext: _fileName,
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
      // ── El PDF ocupa toda la pantalla ──────────────────────────
      body: PDFView(
        filePath: widget.pdfFile.path,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
      ),
      // ── Botón flotante para abrir el panel de recomendaciones ──
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
              error: _error,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

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
