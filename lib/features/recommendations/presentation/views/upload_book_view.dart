import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:tinta/core/ui/theme3material/theme.dart';
import 'package:tinta/core/presentation/components/tinta_background.dart';

import '../../data/datasources/recommendation_upload_datasource.dart';
import '../viewmodels/upload_book_viewmodel.dart';

import '../../../document_viewer/presentation/views/pdf_results_view.dart';

import '../components/recommendations_header.dart';
import '../components/upload_dropzone.dart';
import '../components/recent_document.dart';
import '../components/recent_documents_section.dart';

/// Vista "Sube un libro" — el usuario elige un PDF y, al subirlo, el motor
/// ML (Go) genera recomendaciones basadas en su contenido.
///
/// Es AUTOCONTENIDA: crea su propio ViewModel. Para mostrarla:
///
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => UploadBookView(userId: currentUser.id),
///   ));
class UploadBookView extends StatefulWidget {
  final String userId;
  final VoidCallback? onDone;

  const UploadBookView({Key? key, required this.userId, this.onDone})
      : super(key: key);

  @override
  State<UploadBookView> createState() => _UploadBookViewState();
}

class _UploadBookViewState extends State<UploadBookView> {
  late final UploadBookViewModel _viewModel;
  final TextEditingController _questionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = UploadBookViewModel(RecommendationUploadDataSource());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _questionController.dispose();
    super.dispose();
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

  void _onChatTap(RecentDocument document) {
    // Placeholder: navegación a chat por documento, pendiente de
    // implementar cuando exista persistencia real de documentos.
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
                          RecentDocumentsSection(
                            documents: mockRecentDocuments,
                            onChatTap: _onChatTap,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo de pregunta opcional
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionField extends StatelessWidget {
  final TextEditingController controller;
  const _QuestionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: '¿Qué te interesa de este libro? (opcional)',
        hintText: 'Ej. cuántos huesos tiene el cráneo',
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón de generar
// ─────────────────────────────────────────────────────────────────────────────

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
            : const Text('Generar recomendaciones'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Resultado / error
// ─────────────────────────────────────────────────────────────────────────────

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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted && vm.selectedFile != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PdfResultsView(pdfFile: vm.selectedFile!),
              ),
            );
          }
        });
        return const Center(child: CircularProgressIndicator());

      case UploadState.error:
        return Card(
          color: colorScheme.errorContainer.withOpacity(0.4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vm.errorMessage ?? 'Ocurrió un error',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}