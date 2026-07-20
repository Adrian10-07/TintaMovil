import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/repositories/club_repository.dart';
import '../../data/services/moderation_service.dart';
import '../../data/services/websocket_service.dart';
import '../viewmodels/club_chat_viewmodel.dart';
import '../components/chat_bubble.dart';
import '../components/chat_input_bar.dart';
import '../components/spoiler_block.dart';

/// Pantalla de chat dentro de un club.
///
/// Implementa: mensajes en tiempo real, scroll infinito hacia arriba,
/// moderación client-side, spoilers colapsables, y acciones contextuales.
class ClubChatView extends StatefulWidget {
  final String clubId;
  final String clubName;

  const ClubChatView({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubChatView> createState() => _ClubChatViewState();
}

class _ClubChatViewState extends State<ClubChatView> {
  late final ClubChatViewModel _vm;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // TODO: obtener el userId real del AuthViewModel/UserViewModel.
    const currentUserId = '';

    _vm = ClubChatViewModel(
      repository: sl<ClubRepository>(),
      moderation: sl<ModerationService>(),
      ws: sl<WebSocketService>(),
      clubId: widget.clubId,
      currentUserId: currentUserId,
    );

    _scrollController.addListener(_onScroll);
    _vm.initialize();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Scroll infinito hacia arriba: cargar mensajes más antiguos.
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _vm.loadOlderMessages();
    }
  }

  Future<void> _onSend(String content) async {
    final error = await _vm.sendMessage(content);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  void _onEditMessage(Discussion message) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Escribe tu mensaje...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                await _vm.editMessage(message.id, newContent);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onDeleteMessage(Discussion message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Eliminar este mensaje? No se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _vm.deleteMessage(message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clubName),
        actions: [
          // Selector de capítulo (placeholder).
          PopupMenuButton<int?>(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filtrar por capítulo',
            onSelected: _vm.setChapterFilter,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: null,
                child: Text('Todos los capítulos'),
              ),
              ...List.generate(20, (i) => i + 1).map(
                (n) => PopupMenuItem(
                  value: n,
                  child: Text('Capítulo $n'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return Column(
            children: [
              // Indicador de filtro activo.
              if (_vm.filterChapter != null)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.5),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_rounded, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Capítulo ${_vm.filterChapter}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => _vm.setChapterFilter(null),
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),

              // Lista de mensajes.
              Expanded(child: _buildMessageList()),

              // Barra de envío.
              ChatInputBar(
                onSend: _onSend,
                isSending: _vm.isSending,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    switch (_vm.state) {
      case ChatState.initial:
      case ChatState.loading:
        return const Center(child: CircularProgressIndicator());

      case ChatState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_vm.errorMessage ?? 'Error al cargar mensajes'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _vm.refresh,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );

      case ChatState.empty:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primaryContainer),
              const SizedBox(height: 12),
              Text(
                'Sé el primero en escribir.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.45),
                    ),
              ),
            ],
          ),
        );

      case ChatState.loaded:
        return RefreshIndicator(
          onRefresh: _vm.refresh,
          child: ListView.builder(
            controller: _scrollController,
            reverse: true, // Mensajes más nuevos abajo.
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount:
                _vm.messages.length + (_vm.hasMoreOlder ? 1 : 0),
            itemBuilder: (_, index) {
              // Indicador de carga de mensajes antiguos (al final de la lista invertida).
              if (index == _vm.messages.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final message = _vm.messages[index];

              // Spoiler → widget especial.
              if (message.isSpoiler) {
                return SpoilerBlock(
                  message: message,
                  isMine: message.isMine,
                );
              }

              // Mensaje bloqueado → aviso.
              if (message.isBlocked && message.isMine) {
                return ChatBubble(
                  message: message,
                  isMine: true,
                  isBlocked: true,
                  onEdit: null,
                  onDelete: null,
                );
              }

              // Mensaje bloqueado de otro → no mostrar.
              if (message.isBlocked) {
                return const SizedBox.shrink();
              }

              return ChatBubble(
                message: message,
                isMine: message.isMine,
                onEdit: message.isMine
                    ? () => _onEditMessage(message)
                    : null,
                onDelete: message.isMine
                    ? () => _onDeleteMessage(message)
                    : null,
              );
            },
          ),
        );
    }
  }
}
