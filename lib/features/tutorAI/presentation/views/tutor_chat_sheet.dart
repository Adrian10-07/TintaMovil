import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tinta/core/di/service_locator.dart';


import '../components/chat_input_bar.dart';
import '../components/chat_message_bubble.dart';
import '../components/model_download_progress.dart';
import '../components/tutor_header.dart';
import '../viewmodels/tutor_chat_viewmodel.dart';

class TutorChatSheet extends StatelessWidget {
  final String? documentContext;
  final String? pdfFilePath; // ← NUEVO
  final List<String>? epubChapterHtmlContents; // ← NUEVO, para libros EPUB


  const TutorChatSheet({
    super.key,
    this.documentContext,
    this.pdfFilePath,
    this.epubChapterHtmlContents, // ← NUEVO
  });

  static Future<void> show(
      BuildContext context, {
        String? documentContext,
        String? pdfFilePath,
        List<String>? epubChapterHtmlContents, // ← NUEVO
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              return TutorChatSheet(
                documentContext: documentContext,
                pdfFilePath: pdfFilePath,
                epubChapterHtmlContents: epubChapterHtmlContents, // ← NUEVO
              );
            },
          ),
        );
      },
    );
  }

  // ── 2. build(): indexar el documento si se pasó una ruta ──────────

  @override
  Widget build(BuildContext context) {
    final vm = sl<TutorChatViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      vm.setContext(documentContext);
      if (pdfFilePath != null) {
        vm.indexCurrentDocument(pdfFilePath!);
      } else if (epubChapterHtmlContents != null &&
          epubChapterHtmlContents!.isNotEmpty) {
        vm.indexCurrentDocumentFromEpub(
          bookTitle: documentContext ?? 'libro',
          chapterHtmlContents: epubChapterHtmlContents!,
        );
      }
      vm.initializeModel();
    });

    return ChangeNotifierProvider<TutorChatViewModel>.value(
      value: vm,
      child: _TutorChatSheetContent(documentContext: documentContext),
    );
  }
}

// El resto del archivo (_TutorChatSheetContent, _MessagesList, _EmptyState,
// etc.) NO cambia — se queda exactamente igual a como ya lo tienes.


class _TutorChatSheetContent extends StatelessWidget {
  final String? documentContext;
  const _TutorChatSheetContent({this.documentContext});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TutorChatViewModel>();

    return Column(
      children: [
        TutorHeader(
          modeChipLabel: documentContext != null ? 'Modo Documento' : null,
          connectionLabel: 'Offline',
        ),
        Expanded(child: _buildBody(context, vm)),
        if (vm.modelStatus.isReady)
          ChatInputBar(
            enabled: vm.canSend,
            onSend: vm.sendMessage,
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, TutorChatViewModel vm) {
    // 1) Modelo aún no está listo → pantalla de descarga/carga.
    if (!vm.modelStatus.isReady) {
      return ModelDownloadProgress(
        status: vm.modelStatus,
        onRetry: vm.retryDownload,
      );
    }

    // 2) Modelo listo pero sin mensajes → pantalla de bienvenida.
    if (vm.messages.isEmpty) {
      return _EmptyState(documentContext: documentContext);
    }

    // 3) Chat normal.
    return _MessagesList(messages: vm.messages, error: vm.error);
  }
}

class _MessagesList extends StatefulWidget {
  final List messages;
  final String? error;
  const _MessagesList({required this.messages, this.error});

  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll al final cuando llega un mensaje nuevo o token.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: widget.messages.length + (widget.error != null ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == widget.messages.length && widget.error != null) {
          return _ErrorBanner(error: widget.error!);
        }
        final msg = widget.messages[i];
        // RepaintBoundary aísla cada burbuja en su propia capa de pintura.
        // Cuando solo cambia el ÚLTIMO mensaje (streaming), las anteriores
        // NO se repintan. Reduce paint time del ListView drásticamente.
        return RepaintBoundary(
          key: ValueKey(msg.id),
          child: ChatMessageBubble(message: msg),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? documentContext;
  const _EmptyState({this.documentContext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final suggestions = documentContext != null
        ? [
            'Resume las ideas principales',
            'Explícame el tema central',
            'Dame ejemplos del concepto',
          ]
        : [
            'Explícame la recursión en Python',
            '¿Qué causó la Revolución Mexicana?',
            'Dame un ejemplo de algoritmo de búsqueda',
          ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 56,
            color: cs.primary,
          ),
          const SizedBox(height: 16),
          Text(
            documentContext != null
                ? 'Pregúntame sobre este documento'
                : 'Hola, soy Tinta AI',
            style: tt.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            documentContext != null
                ? 'Estoy aquí para ayudarte a entender mejor lo que estás leyendo.'
                : 'Pregúntame de programación o historia. Funciono 100% en tu dispositivo.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...suggestions.map((s) => _SuggestionChip(text: s)),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  const _SuggestionChip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.read<TutorChatViewModel>().sendMessage(text);
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        error,
        style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
      ),
    );
  }
}
