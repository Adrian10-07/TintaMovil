import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tinta/core/di/service_locator.dart';

import '../../domain/repositories/tutor_repository.dart';
import '../components/chat_input_bar.dart';
import '../components/chat_message_bubble.dart';
import '../components/model_download_progress.dart';
import '../components/tutor_header.dart';
import '../viewmodels/tutor_chat_viewmodel.dart';

/// Chat con Tinta AI que se monta como bottom sheet desde `PdfResultsView`
/// (o desde cualquier otra vista que pase un `documentContext`).
///
/// Estructura:
///   - Header con avatar + estado.
///   - Cuerpo: pantalla de descarga si el modelo no está listo, o
///     lista de mensajes si lo está.
///   - Input al fondo.
class TutorChatSheet extends StatelessWidget {
  final String? documentContext;

  const TutorChatSheet({super.key, this.documentContext});

  /// Helper para abrir el sheet desde cualquier vista. Centraliza la
  /// configuración (drag handle, tamaños min/max, etc.).
  static Future<void> show(
    BuildContext context, {
    String? documentContext,
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
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return TutorChatSheet(documentContext: documentContext);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TutorChatViewModel>(
      create: (_) {
        final vm = TutorChatViewModel(
          sl<TutorRepository>(),
          documentContext: documentContext,
        );
        // Iniciar la descarga/carga del modelo de inmediato.
        vm.initializeModel();
        return vm;
      },
      child: _TutorChatSheetContent(documentContext: documentContext),
    );
  }
}

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
