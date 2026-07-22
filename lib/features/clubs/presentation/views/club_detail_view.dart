import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/club_member.dart';
import '../../domain/repositories/club_repository.dart';
import '../viewmodels/club_detail_viewmodel.dart';
import '../components/member_list_tile.dart';
import 'club_chat_view.dart';

/// Pantalla de detalle de un club.
class ClubDetailView extends StatefulWidget {
  final String clubId;
  const ClubDetailView({super.key, required this.clubId});

  @override
  State<ClubDetailView> createState() => _ClubDetailViewState();
}

class _ClubDetailViewState extends State<ClubDetailView> {
  late final ClubDetailViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ClubDetailViewModel(
      repository: sl<ClubRepository>(),
      clubId: widget.clubId,
    );
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClubChatView(
          clubId: widget.clubId,
          clubName: _vm.club?.name ?? 'Chat',
          memberCount: _vm.club?.memberCount ?? _vm.members.length,
        ),
      ),
    );
  }

  Future<void> _onJoin() async {
    final success = await _vm.join();
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Te uniste al club!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Abandonar club'),
        content:
        const Text('¿Estás seguro de que quieres abandonar este club?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await _vm.leave();
      if (mounted && success) Navigator.pop(context);
    }
  }

  Future<void> _generateInvite() async {
    final invite = await _vm.generateInvite(ttl: const Duration(days: 7));
    if (invite != null && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Código de invitación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                invite.code,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('Comparte este código para invitar personas.',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: invite.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              },
              child: const Text('Copiar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_vm.club?.name ?? 'Club'),
            actions: [
              if (_vm.canModerate)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'invite':    _generateInvite(); break;
                      case 'clear_chat': _vm.clearChat(); break;
                      case 'delete':
                        _vm.deleteClub().then((ok) {
                          if (ok && mounted) Navigator.pop(context);
                        });
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'invite',
                      child: ListTile(
                        leading: Icon(Icons.link),
                        title: Text('Generar invitación'),
                        dense: true, contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_chat',
                      child: ListTile(
                        leading: Icon(Icons.delete_sweep_rounded),
                        title: Text('Vaciar chat'),
                        dense: true, contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_vm.canManage)
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_forever_rounded,
                              color: colorScheme.error),
                          title: Text('Eliminar club',
                              style: TextStyle(color: colorScheme.error)),
                          dense: true, contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
            ],
          ),
          body: _vm.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _vm.errorMessage != null && _vm.club == null
              ? Center(child: Text(_vm.errorMessage!))
              : _buildContent(colorScheme, textTheme),
          floatingActionButton: _buildFab(),
        );
      },
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    final club = _vm.club;
    if (club == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        club.name.isNotEmpty ? club.name[0].toUpperCase() : '?',
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(club.name, style: textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                club.isPrivate
                                    ? Icons.lock_rounded
                                    : Icons.public_rounded,
                                size: 16, color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                club.isPrivate ? 'Privado' : 'Público',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.group_rounded,
                                  size: 16, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                '${_vm.members.length} miembros',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (club.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(club.description, style: textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Rol actual
        if (_vm.isMember && _vm.myRole != null)
          Card(
            child: ListTile(
              leading: Icon(
                _vm.myRole == ClubRole.owner
                    ? Icons.star_rounded
                    : _vm.myRole == ClubRole.moderator
                    ? Icons.shield_rounded
                    : Icons.person_rounded,
                color: colorScheme.primary,
              ),
              title: Text('Tu rol: ${_vm.myRole!.name}'),
              trailing: _vm.myRole != ClubRole.owner
                  ? TextButton(
                onPressed: _onLeave,
                child: const Text('Abandonar'),
              )
                  : null,
            ),
          ),

        const SizedBox(height: 16),

        // Miembros
        Text('Miembros', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        ..._vm.members.map((m) => MemberListTile(member: m)),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget? _buildFab() {
    if (_vm.isLoading) return null;
    if (!_vm.isMember) {
      return FloatingActionButton.extended(
        onPressed: _onJoin,
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('Unirse'),
      );
    }
    return FloatingActionButton.extended(
      onPressed: _navigateToChat,
      icon: const Icon(Icons.chat_rounded),
      label: const Text('Entrar al chat'),
    );
  }
}
