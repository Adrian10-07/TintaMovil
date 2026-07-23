import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tinta/core/di/service_locator.dart';

import '../../data/datasources/remote_tutor_datasource.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/tutor_source.dart';
import '../components/sources_footer.dart';
import '../viewmodels/remote_tutor_chat_viewmodel.dart';

class RemoteTutorChatSheet extends StatelessWidget {
  final String documentContext;
  final String remoteDocumentId;

  const RemoteTutorChatSheet({
    super.key,
    required this.documentContext,
    required this.remoteDocumentId,
  });

  static Future<void> show(
    BuildContext context, {
    required String documentContext,
    required String remoteDocumentId,
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
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => RemoteTutorChatSheet(
          documentContext: documentContext,
          remoteDocumentId: remoteDocumentId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RemoteTutorChatViewModel>(
      create: (_) => RemoteTutorChatViewModel(
        sl<RemoteTutorDatasource>(),
        remoteDocumentId: remoteDocumentId,
        documentContext: documentContext,
      ),
      child: _RemoteChatContent(documentContext: documentContext),
    );
  }
}

class _RemoteChatContent extends StatelessWidget {
  final String documentContext;

  const _RemoteChatContent({required this.documentContext});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RemoteTutorChatViewModel>();

    return Column(
      children: [
        _Header(documentContext: documentContext),
        Expanded(child: _Body(vm: vm, documentContext: documentContext)),
        _InputBar(
          enabled: vm.canSend,
          onSend: vm.sendMessage,
        ),
      ],
    );
  }
}

// HEADER

class _Header extends StatelessWidget {
  final String documentContext;
  const _Header({required this.documentContext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: cs.onPrimaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tinta AI',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Activo',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Modo Documento',
              style: tt.labelSmall?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// BODY

class _Body extends StatelessWidget {
  final RemoteTutorChatViewModel vm;
  final String documentContext;

  const _Body({required this.vm, required this.documentContext});

  @override
  Widget build(BuildContext context) {
    if (vm.messages.isEmpty) {
      return _EmptyState(documentContext: documentContext);
    }
    return _MessagesList(vm: vm);
  }
}

class _EmptyState extends StatelessWidget {
  final String documentContext;
  const _EmptyState({required this.documentContext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final suggestions = const [
      'Resume las ideas principales',
      'Explícame el tema central',
      '¿Cuáles son los conceptos clave?',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Icon(Icons.auto_awesome_rounded, size: 56, color: cs.primary),
          const SizedBox(height: 16),
          Text(
            'Pregúntame sobre este documento',
            style: tt.titleLarge?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Puedo ayudarte a entender el contenido, resumirlo o profundizar en cualquier parte.',
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
          context.read<RemoteTutorChatViewModel>().sendMessage(text);
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

// LISTA DE MENSAJES

class _MessagesList extends StatefulWidget {
  final RemoteTutorChatViewModel vm;
  const _MessagesList({required this.vm});

  @override
  State<_MessagesList> createState() => _MessagesListState();
}

class _MessagesListState extends State<_MessagesList> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _MessagesList oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final messages = widget.vm.messages;
    final error = widget.vm.error;
    final itemCount = messages.length + (error != null ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (i == messages.length && error != null) {
          return _ErrorBanner(error: error);
        }
        final msg = messages[i];
        final sources = msg.isAssistant
            ? widget.vm.sourcesFor(msg.id)
            : const <TutorSource>[];

        return RepaintBoundary(
          key: ValueKey(msg.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageBubble(message: msg),
              if (sources.isNotEmpty && !msg.isStreaming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SourcesFooter(sources: sources),
                ),
            ],
          ),
        );
      },
    );
  }
}

// BURBUJA DE MENSAJE

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? cs.primary : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.content.isEmpty && message.isStreaming
                      ? '…'
                      : message.content,
                  style: tt.bodyMedium?.copyWith(
                    color: isUser ? cs.onPrimary : cs.onSurface,
                    height: 1.4,
                  ),
                ),
                if (message.isStreaming && message.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: SizedBox(
                      height: 8,
                      width: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: isUser ? cs.onPrimary : cs.primary,
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

// INPUT BAR

class _InputBar extends StatefulWidget {
  final bool enabled;
  final Future<void> Function(String text) onSend;

  const _InputBar({required this.enabled, required this.onSend});

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    _controller.clear();
    await widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Pregunta al tutor…',
                  filled: true,
                  fillColor: cs.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: widget.enabled ? cs.primary : cs.surfaceContainerHigh,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: widget.enabled ? _submit : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: widget.enabled ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
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
