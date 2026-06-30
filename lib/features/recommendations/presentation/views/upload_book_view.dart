import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:tinta/core/ui/theme3material/theme.dart';
import 'package:tinta/core/presentation/components/tinta_background.dart';

import '../../data/datasources/recommendation_upload_datasource.dart';
import '../viewmodels/upload_book_viewmodel.dart';
import 'pdf_results_view.dart';

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
                _Header(onBack: () => Navigator.maybePop(context)),
                Expanded(
                  child: Consumer<UploadBookViewModel>(
                    builder: (context, vm, _) => SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PdfPicker(vm: vm, onPick: _pickPdf),
                          const SizedBox(height: 20),
                          _QuestionField(controller: _questionController),
                          const SizedBox(height: 24),
                          _GenerateButton(vm: vm, onTap: _generate),
                          const SizedBox(height: 20),
                          _ResultArea(vm: vm, onDone: widget.onDone),
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
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sube un libro', style: textTheme.titleLarge),
              Text(
                'Te recomendamos lecturas afines',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selector de PDF
// ─────────────────────────────────────────────────────────────────────────────

class _PdfPicker extends StatelessWidget {
  final UploadBookViewModel vm;
  final VoidCallback onPick;
  const _PdfPicker({required this.vm, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final file = vm.selectedFile;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                file != null
                    ? Icons.picture_as_pdf_rounded
                    : Icons.upload_file_rounded,
                size: 40,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                file != null ? file.path.split('/').last : 'Toca para elegir un PDF',
                style: textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (file == null) ...[
                const SizedBox(height: 4),
                Text(
                  'El libro o capítulo que quieras explorar',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.50),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
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
        hintText: 'Ej. cuantos huesos tiene el craneo',
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
      // Navega automáticamente a la vista de resultados (PDF + recomendaciones)
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