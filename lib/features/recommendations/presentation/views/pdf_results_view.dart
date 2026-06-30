import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../domain/entities/recommendation.dart';
import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';

/// Vista de resultados tras subir un PDF:
///   - Mitad superior: visor nativo del PDF (flutter_pdfview)
///   - Mitad inferior: recomendaciones generadas de ese PDF
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
      setState(() => _items = result);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final fileName = widget.pdfFile.path.split('/').last.split('\\').last;

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          // ── Visor nativo del PDF ─────────────────────────────
          Expanded(
            flex: 1,
            child: PDFView(
              filePath: widget.pdfFile.path,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant),

          // ── Recomendaciones ──────────────────────────────────
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Te puede interesar', style: textTheme.titleMedium),
                ),
                Expanded(child: _buildRecommendations()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items!.isEmpty) {
      return const Center(child: Text('Aún no hay recomendaciones.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _items!.length,
      itemBuilder: (_, i) {
        final r = _items![i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${i + 1}. ${r.title} — ${r.authors.join(', ')}',
            style: const TextStyle(fontSize: 15),
          ),
        );
      },
    );
  }
}