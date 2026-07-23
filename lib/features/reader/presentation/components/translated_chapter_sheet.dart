import 'package:flutter/material.dart';
import '../../data/services/translation_service.dart';

/// Muestra el capítulo actual traducido al español dentro de un panel
/// deslizable, sin alterar el lector original (el usuario puede cerrar
/// el panel y seguir leyendo el EPUB tal cual). Solo aplica a libros de
/// dominio público (Standard Ebooks / Gutendex), que es todo lo que
/// ofrece el catálogo de Tinta.
class TranslatedChapterSheet extends StatefulWidget {
  final String chapterTitle;
  final String chapterHtml;

  const TranslatedChapterSheet({
    Key? key,
    required this.chapterTitle,
    required this.chapterHtml,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, {
        required String chapterTitle,
        required String chapterHtml,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => TranslatedChapterSheet(
          chapterTitle: chapterTitle,
          chapterHtml: chapterHtml,
        ),
      ),
    );
  }

  @override
  State<TranslatedChapterSheet> createState() => _TranslatedChapterSheetState();
}

class _TranslatedChapterSheetState extends State<TranslatedChapterSheet> {
  String? _translated;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _translate();
  }

  Future<void> _translate() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final plainText = TranslationService.htmlToPlainText(widget.chapterHtml);
      if (plainText.trim().isEmpty) {
        throw Exception('Este capítulo no tiene texto para traducir.');
      }
      final result = await TranslationService.translateToSpanish(plainText);
      if (mounted) setState(() => _translated = result);
    } catch (e) {
      if (mounted) {
        setState(() => _error =
        'No se pudo traducir en este momento. ${e.toString().replaceAll('Exception: ', '')}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Icon(Icons.translate_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.chapterTitle.isNotEmpty
                      ? widget.chapterTitle
                      : 'Capítulo traducido',
                  style: textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: colorScheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Traducción automática, puede tener errores. Esto no reemplaza el capítulo original.',
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, color: colorScheme.error, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _translate,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SelectableText(
        _translated ?? '',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
    );
  }
}