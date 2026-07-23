import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:tinta/core/ui/theme3material/theme.dart';
import 'package:tinta/core/presentation/components/tinta_background.dart';

import '../../data/datasources/recommendation_upload_datasource.dart';
import '../../data/services/recent_documents_service.dart';
import '../viewmodels/upload_book_viewmodel.dart';

import '../../../document_viewer/presentation/views/pdf_results_view.dart';

import '../components/recommendations_header.dart';
import '../components/upload_dropzone.dart';
import '../components/recent_document.dart';
import '../components/recent_documents_section.dart';

/// Vista "Sube un libro" — el usuario elige un PDF y, al subirlo, el motor
/// ML (Go) genera recomendaciones basadas en su contenido.
class UploadBookView extends StatefulWidget {
  final String userId;
  final VoidCallback? onDone;

  /// Cuando es true, se usa como pestaña dentro de MainTabShell — sin
  /// botón de regreso en el header (no aplica: no hay a dónde "volver",
  /// es una pestaña, no una pantalla apilada).
  final bool embedded;

  const UploadBookView({
    Key? key,
    required this.userId,
    this.onDone,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<UploadBookView> createState() => _UploadBookViewState();
}

class _UploadBookViewState extends State<UploadBookView> {
  late final UploadBookViewModel _viewModel;
  final TextEditingController _questionController = TextEditingController();

  List<RecentDocumentRecord>? _recentDocs;

  @override
  void initState() {
    super.initState();
    _viewModel = UploadBookViewModel(RecommendationUploadDataSource());
    _viewModel.addListener(_onViewModelChanged);
    _loadRecentDocuments();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _questionController.dispose();
    super.dispose();
  }

  UploadState? _lastKnownState;

  void _onViewModelChanged() {
    if (_viewModel.state == UploadState.success &&
        _lastKnownState != UploadState.success) {
      _loadRecentDocuments();

      // Navegar UNA sola vez, exactamente en la transición hacia success.
      final file = _viewModel.selectedFile;
      if (file != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PdfResultsView(pdfFile: file)),
            );
          }
        });
      }
    }
    _lastKnownState = _viewModel.state;
  }

  Future<void> _loadRecentDocuments() async {
    final docs = await RecentDocumentsService.getAll(widget.userId);
    if (mounted) setState(() => _recentDocs = docs);
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      _viewModel.setSelectedFile(File(result.files.single.path!));
    }
  }

  Future<void> _generate() async {
    final preguntas = _questionController.text.trim().isEmpty
        ? <String>[]
        : [_questionController.text.trim()];
    await _viewModel.generate(userId: widget.userId, questions: preguntas);
  }

  void _openDocument(RecentDocumentRecord record) {
    final file = File(record.path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese archivo ya no está disponible en el dispositivo.')),
      );
      _loadRecentDocuments();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfResultsView(pdfFile: file)),
    ).then((_) => _loadRecentDocuments());
  }

  Future<void> _removeDocument(RecentDocumentRecord record) async {
    await RecentDocumentsService.remove(widget.userId, record.path);
    _loadRecentDocuments();
  }

  void _showPrivacyInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacidad de tus documentos'),
        content: const Text(
          'Tu PDF se sube por conexión segura (HTTPS) únicamente al '
              'servidor de análisis de Tinta para generar el resumen y las '
              'recomendaciones — no se comparte con nadie más. '
              'El archivo también se guarda en tu dispositivo para que '
              'puedas volver a abrirlo sin conexión, y puedes borrarlo de '
              '"Recientes" cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        body: TintaBackground(
          blobs: [
            BlobConfig(
              top: -120, right: -80,
              color: colorScheme.primary, size: 320, opacity: 0.10,
            ),
            BlobConfig(
              top: 320, left: -60,
              color: MaterialTheme.warmGold, size: 220, opacity: 0.08,
            ),
          ],
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RecommendationsHeader(
                  onBack: () => Navigator.maybePop(context),
                  onPrivacyTap: _showPrivacyInfo,
                  showBackButton: !widget.embedded,
                ),
                Expanded(
                  child: Consumer<UploadBookViewModel>(
                    builder: (context, vm, _) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UploadDropzone(
                            onTap: _pickPdf,
                            hasSelection: vm.selectedFile != null,
                            selectedFileName: vm.selectedFile != null
                                ? vm.selectedFile!.path.split('/').last
                                : '',
                          ),
                          const SizedBox(height: 20),
                          _QuestionField(controller: _questionController),
                          const SizedBox(height: 16),
                          _GenerateButton(vm: vm, onTap: _generate),
                          const SizedBox(height: 12),
                          _ResultArea(vm: vm, onDone: widget.onDone),
                          const SizedBox(height: 28),
                          if (_recentDocs == null)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          else
                            RecentDocumentsSection(
                              documents: _recentDocs!
                                  .map(_toDisplayDocument)
                                  .toList(),
                              onTap: (doc) => _openDocument(
                                  _recentDocs!.firstWhere((r) => r.path == doc.path)),
                              onChatTap: (doc) => _openDocument(
                                  _recentDocs!.firstWhere((r) => r.path == doc.path)),
                              onDeleteTap: (doc) => _removeDocument(
                                  _recentDocs!.firstWhere((r) => r.path == doc.path)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  RecentDocument _toDisplayDocument(RecentDocumentRecord r) {
    return RecentDocument(
      path: r.path,
      title: r.title,
      pages: r.pages,
      sizeMb: r.sizeMb,
      type: DocumentType.pdf,
      progress: (r.recommendationsCount / 5).clamp(0.0, 1.0),
    );
  }
}

class _QuestionField extends StatelessWidget {
  final TextEditingController controller;
  const _QuestionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '¿Qué te interesa de este libro? (opcional)',
            hintText: 'Ej. cuántos huesos tiene el cráneo',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Se envía a la IA junto con tu documento para enfocar las recomendaciones.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final UploadBookViewModel vm;
  final VoidCallback onTap;
  const _GenerateButton({required this.vm, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cargando = vm.state == UploadState.uploading;
    final habilitado = vm.selectedFile != null && !cargando;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: habilitado ? onTap : null,
        child: cargando
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Text('Analizar y ver'),
      ),
    );
  }
}

class _ResultArea extends StatelessWidget {
  final UploadBookViewModel vm;
  final VoidCallback? onDone;
  const _ResultArea({required this.vm, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    switch (vm.state) {
      case UploadState.success:
      // La navegación ahora ocurre en _onViewModelChanged() del widget
      // padre
        return const Center(child: CircularProgressIndicator());

      case UploadState.error:
        final esOffline = vm.isOfflineError;
        return Card(
          color: esOffline
              ? colorScheme.tertiaryContainer.withOpacity(0.5)
              : colorScheme.errorContainer.withOpacity(0.4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      esOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                      color: esOffline ? colorScheme.onTertiaryContainer : colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vm.errorMessage ?? 'Ocurrió un error',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                if (esOffline && vm.selectedFile != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfResultsView(pdfFile: vm.selectedFile!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('Ver PDF sin recomendaciones'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}