import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../user/presentation/viewmodels/user_viewmodel.dart';
import '../../../auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/repositories/club_repository.dart';
import '../../data/services/moderation_service.dart';
import '../../data/services/websocket_service.dart';
import '../../data/services/club_notification_service.dart';
import '../../data/services/user_cache_service.dart';
import '../viewmodels/club_chat_viewmodel.dart';
import '../components/chat_bubble.dart';
import '../components/chat_input_bar.dart';
import '../components/spoiler_block.dart';
import 'club_detail_view.dart';

/// Pantalla de chat dentro de un club.
class ClubChatView extends StatefulWidget {
  final String clubId;
  final String clubName;
  final int memberCount;

  /// Si el usuario acaba de crear este club, ya sabemos que es owner.
  final bool isCreator;

  const ClubChatView({
    super.key,
    required this.clubId,
    required this.clubName,
    this.memberCount = 0,
    this.isCreator = false,
  });

  @override
  State<ClubChatView> createState() => _ClubChatViewState();
}

class _ClubChatViewState extends State<ClubChatView>
    with WidgetsBindingObserver {
  late final ClubChatViewModel _vm;
  final _scrollController = ScrollController();
  ClubRole? _myRole;

  @override
  void initState() {
    super.initState();

    // Obtener userId: intentar UserViewModel primero, luego AuthViewModel.
    final userVm = sl<UserViewModel>();
    final authVm = sl<AuthViewModel>();
    final currentUserId =
        userVm.profile?.id ?? authVm.currentUser?.id ?? '';

    // Si el profile no está cargado, cargarlo en background.
    if (userVm.profile == null) {
      userVm.loadProfile();
    }

    _vm = ClubChatViewModel(
      repository: sl<ClubRepository>(),
      moderation: sl<ModerationService>(),
      ws: sl<WebSocketService>(),
      userCache: sl<UserCacheService>(),
      clubId: widget.clubId,
      currentUserId: currentUserId,
    );

    _scrollController.addListener(_onScroll);
    _vm.initialize();

    // Registrar observer de ciclo de vida de la app para pausar/reanudar
    // el realtime cuando la app pase a background y vuelva.
    WidgetsBinding.instance.addObserver(this);

    // Marcar club como visto para el badge de notificaciones.
    sl<ClubNotificationService>().markClubAsSeen(widget.clubId);

    // Si es el creador, ya sabemos que es owner — no esperar al backend.
    if (widget.isCreator) {
      _myRole = ClubRole.owner;
    } else {
      _loadMyRole();
    }
  }

  Future<void> _loadMyRole() async {
    try {
      final repo = sl<ClubRepository>();
      final status = await repo.checkMembership(widget.clubId);
      if (mounted && status.isMember) {
        setState(() => _myRole = status.membership?.role);
      }
    } catch (_) {}
  }

  bool get _isAdmin => _myRole == ClubRole.owner;
  bool get _canModerate => _myRole?.canModerate ?? false;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _vm.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _vm.pauseRealtime();
        break;
      case AppLifecycleState.resumed:
        _vm.resumeRealtime();
        break;
      case AppLifecycleState.detached:
      // no-op: la app se está cerrando; dispose() ya limpia todo.
        break;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _vm.loadOlderMessages();
    }
  }

  void _openClubDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailView(clubId: widget.clubId)),
    );
  }

  Future<void> _onSend(String content) async {
    final error = await _vm.sendMessage(content);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showMessageActions(Discussion message) {
    final isMine = message.isMine;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Editar mensaje'),
                onTap: () { Navigator.pop(context); _editMessage(message); },
              ),
            if (_canModerate)
              ListTile(
                leading: Icon(message.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined),
                title: Text(message.isPinned ? 'Desfijar mensaje' : 'Fijar mensaje'),
                onTap: () { Navigator.pop(context); _togglePin(message); },
              ),
            if (isMine || _canModerate)
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Theme.of(context).colorScheme.error),
                title: Text(isMine ? 'Eliminar mensaje' : 'Eliminar (moderador)',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () { Navigator.pop(context); _deleteMessage(message); },
              ),
          ],
        ),
      ),
    );
  }

  void _editMessage(Discussion message) {
    final controller = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(controller: controller, maxLines: 4, autofocus: true,
            decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            final t = controller.text.trim();
            if (t.isNotEmpty) await _vm.editMessage(message.id, t);
            if (mounted) Navigator.pop(context);
          }, child: const Text('Guardar')),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(Discussion message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text('¿Eliminar este mensaje? No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _vm.deleteMessage(message.id);
  }

  Future<void> _togglePin(Discussion message) async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message.isPinned ? 'Mensaje desfijado' : 'Mensaje fijado'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _openClubDetail,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  widget.clubName.isNotEmpty ? widget.clubName[0].toUpperCase() : '?',
                  style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.clubName, style: textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  Text('Toca para ver info del club',
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              )),
            ]),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              switch (v) {
                case 'filter': _showChapterFilter(); break;
                case 'clear': _confirmClearChat(); break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'filter', child: ListTile(
                  leading: Icon(Icons.filter_list_rounded), title: Text('Filtrar por capítulo'),
                  dense: true, contentPadding: EdgeInsets.zero)),
              // Vaciar chat visible para owner y moderator.
              if (_canModerate)
                const PopupMenuItem(value: 'clear', child: ListTile(
                    leading: Icon(Icons.delete_sweep_rounded), title: Text('Vaciar chat'),
                    dense: true, contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Pinned + filter (rebuild solo con mensajes).
          ListenableBuilder(
            listenable: _vm,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ..._buildPinnedMessages(colorScheme, textTheme),
                if (_vm.filterChapter != null)
                  Material(
                    color: colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(children: [
                        Icon(Icons.filter_alt_rounded, size: 16, color: colorScheme.onSecondaryContainer),
                        const SizedBox(width: 8),
                        Text('Capítulo ${_vm.filterChapter}',
                            style: textTheme.labelMedium?.copyWith(color: colorScheme.onSecondaryContainer)),
                        const Spacer(),
                        InkWell(
                          onTap: () => _vm.setChapterFilter(null),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(padding: const EdgeInsets.all(4),
                              child: Icon(Icons.close_rounded, size: 16, color: colorScheme.onSecondaryContainer)),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),

          // Lista de mensajes (rebuild aislado).
          Expanded(
            child: ListenableBuilder(
              listenable: _vm,
              builder: (context, _) => _buildMessageList(),
            ),
          ),

          // Input bar (NO se reconstruye con cada mensaje nuevo).
          ChatInputBar(onSend: _onSend, isSending: _vm.isSending),
        ],
      ),
    );
  }

  void _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar chat'),
        content: const Text('¿Eliminar todos los mensajes del chat? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _vm.clearChat();
  }

  List<Widget> _buildPinnedMessages(ColorScheme cs, TextTheme tt) {
    final pinned = _vm.messages.where((m) => m.isPinned).toList();
    if (pinned.isEmpty) return [];
    return [
      Material(
        color: cs.tertiaryContainer.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Icon(Icons.push_pin_rounded, size: 14, color: cs.tertiary),
            const SizedBox(width: 8),
            Expanded(child: Text(pinned.first.content, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onTertiaryContainer))),
          ]),
        ),
      ),
    ];
  }

  void _showChapterFilter() {
    showModalBottomSheet(
      context: context, showDragHandle: true,
      builder: (_) => SafeArea(child: ListView(shrinkWrap: true, children: [
        ListTile(leading: const Icon(Icons.all_inclusive_rounded), title: const Text('Todos'),
            selected: _vm.filterChapter == null,
            onTap: () { _vm.setChapterFilter(null); Navigator.pop(context); }),
        ...List.generate(20, (i) => i + 1).map((n) => ListTile(
            leading: const Icon(Icons.bookmark_border_rounded), title: Text('Capítulo $n'),
            selected: _vm.filterChapter == n,
            onTap: () { _vm.setChapterFilter(n); Navigator.pop(context); })),
      ])),
    );
  }

  Widget _buildMessageList() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_vm.state) {
      case ChatState.initial:
      case ChatState.loading:
        return const Center(child: CircularProgressIndicator());
      case ChatState.error:
        return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: colorScheme.primaryContainer),
          const SizedBox(height: 12),
          Text(_vm.errorMessage ?? 'Error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _vm.refresh, child: const Text('Reintentar')),
        ],
        )));
      case ChatState.empty:
        return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 56, color: colorScheme.primaryContainer),
          const SizedBox(height: 12),
          Text('Sé el primero en escribir.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
        ));
      case ChatState.loaded:
        return ListView.builder(
          controller: _scrollController, reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: _vm.messages.length + (_vm.hasMoreOlder ? 1 : 0),
          itemBuilder: (_, index) {
            if (index == _vm.messages.length) {
              return const Padding(padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            }
            final message = _vm.messages[index];
            final showSender = !message.isMine && _shouldShowSender(index);
            final dateSep = _buildDateSeparator(index);

            return Column(children: [
              if (dateSep != null) dateSep,
              if (message.isSpoiler)
                SpoilerBlock(message: message, isMine: message.isMine)
              else if (message.isBlocked && !message.isMine)
                const SizedBox.shrink()
              else
                ChatBubble(
                  message: message, isMine: message.isMine, isBlocked: message.isBlocked,
                  showSenderName: showSender,
                  onEdit: (message.isMine || _canModerate)
                      ? () => _showMessageActions(message) : null,
                  onDelete: null,
                ),
            ]);
          },
        );
    }
  }

  bool _shouldShowSender(int index) {
    if (index + 1 >= _vm.messages.length) return true;
    return _vm.messages[index].userId != _vm.messages[index + 1].userId;
  }

  Widget? _buildDateSeparator(int index) {
    if (index + 1 >= _vm.messages.length) return null;
    final cur = _vm.messages[index].createdAt;
    final prev = _vm.messages[index + 1].createdAt;
    if (cur.day == prev.day && cur.month == prev.month && cur.year == prev.year) return null;
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    String label;
    if (cur.day == now.day && cur.month == now.month && cur.year == now.year) label = 'Hoy';
    else if (cur.day == now.day - 1 && cur.month == now.month && cur.year == now.year) label = 'Ayer';
    else label = '${cur.day}/${cur.month}/${cur.year}';
    return Padding(padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        )));
  }
}