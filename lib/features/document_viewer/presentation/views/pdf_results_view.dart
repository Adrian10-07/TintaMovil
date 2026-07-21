import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../../recommendations/data/datasources/recommendation_remote_datasource.dart';
import '../../../recommendations/domain/entities/recommendation.dart';
import '../../../tutorAI/presentation/views/tutor_chat_sheet.dart';
import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';
import '../../../home/data/services/streak_service.dart';
import '../../../achievements/data/services/achievement_service.dart';
import '../../../recommendations/data/services/recent_documents_service.dart';
import '../../../user/presentation/viewmodels/user_viewmodel.dart';

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
  // ── Paleta Tinta ──────────────────────────────────────────────
  static const _mintPrimary = Color(0xFF3DBF7A);
  static const _deepGreen = Color(0xFF1A4D2E);
  static const _warmGold = Color(0xFFF5C842);
  static const _peach = Color(0xFFFFBF9B);
  static const _darkText = Color(0xFF1A2B1F);

  final _dataSource = RecommendationRemoteDataSource(sl<ApiClient>());

  List<Recommendation>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _registerReadingActivity();
  }

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
        backgroundColor: _mintPrimary,
        icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
        label: Text(
          count == null ? 'Te puede interesar' : 'Te puede interesar ($count)',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
              error: _error,
              scrollController: scrollController,
              mintPrimary: _mintPrimary,
              deepGreen: _deepGreen,
              warmGold: _warmGold,
              peach: _peach,
              darkText: _darkText,
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
  final Color mintPrimary;
  final Color deepGreen;
  final Color warmGold;
  final Color peach;
  final Color darkText;

  const _RecommendationsSheetContent({
    required this.items,
    required this.error,
    required this.scrollController,
    required this.mintPrimary,
    required this.deepGreen,
    required this.warmGold,
    required this.peach,
    required this.darkText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Te puede interesar',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: deepGreen,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $error',
              style: TextStyle(color: darkText.withOpacity(0.6))),
        ),
      );
    }
    if (items == null) {
      return Center(child: CircularProgressIndicator(color: mintPrimary));
    }
    if (items!.isEmpty) {
      // Mensaje amigable: no es un error, es que no se encontraron
      // coincidencias para el tema de este libro en particular.
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_stories_outlined,
                  color: mintPrimary.withOpacity(0.6), size: 40),
              const SizedBox(height: 12),
              Text(
                'No encontramos recomendaciones para este libro.\n'
                    'Prueba subiendo otro con un tema distinto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 13.5,
                  color: darkText.withOpacity(0.55),
                ),
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
        return _SheetRecommendationTile(
          recommendation: r,
          mintPrimary: mintPrimary,
          deepGreen: deepGreen,
          warmGold: warmGold,
          peach: peach,
          darkText: darkText,
        );
      },
    );
  }
}

class _SheetRecommendationTile extends StatelessWidget {
  final Recommendation recommendation;
  final Color mintPrimary;
  final Color deepGreen;
  final Color warmGold;
  final Color peach;
  final Color darkText;

  const _SheetRecommendationTile({
    required this.recommendation,
    required this.mintPrimary,
    required this.deepGreen,
    required this.warmGold,
    required this.peach,
    required this.darkText,
  });

  Color get _matchColor {
    final p = recommendation.matchPercent;
    if (p >= 70) return mintPrimary;
    if (p >= 40) return warmGold;
    return peach;
  }

  @override
  Widget build(BuildContext context) {
    final r = recommendation;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkText.withOpacity(0.03),
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
                  color: mintPrimary.withOpacity(0.15),
                  child: Icon(Icons.menu_book_rounded,
                      color: mintPrimary, size: 20),
                ),
              )
                  : Container(
                color: mintPrimary.withOpacity(0.15),
                child: Icon(Icons.menu_book_rounded,
                    color: mintPrimary, size: 20),
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
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: deepGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _matchColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${r.matchPercent}%',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _matchColor,
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
                    fontFamily: 'DMSans',
                    fontSize: 11.5,
                    color: darkText.withOpacity(0.5),
                  ),
                ),
                if (r.matchReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    r.matchReason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: deepGreen.withOpacity(0.6),
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