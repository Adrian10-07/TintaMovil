import 'package:flutter/material.dart';

import '../../domain/entities/club_member.dart';

/// Tile para mostrar un miembro del club en la lista de miembros.
class MemberListTile extends StatelessWidget {
  final ClubMember member;

  const MemberListTile({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final IconData roleIcon;
    final Color roleColor;
    final String roleLabel;

    switch (member.role) {
      case ClubRole.owner:
        roleIcon = Icons.star_rounded;
        roleColor = colorScheme.tertiary;
        roleLabel = 'Creador';
        break;
      case ClubRole.moderator:
        roleIcon = Icons.shield_rounded;
        roleColor = colorScheme.secondary;
        roleLabel = 'Moderador';
        break;
      case ClubRole.member:
        roleIcon = Icons.person_rounded;
        roleColor = colorScheme.onSurfaceVariant;
        roleLabel = 'Miembro';
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.person_rounded,
              color: colorScheme.onSurfaceVariant),
        ),
        title: Text(
          // En producción se haría un lookup del nombre por userId.
          member.userId.substring(0, 8),
          style: textTheme.bodyMedium,
        ),
        subtitle: Text(
          'Se unió ${_formatDate(member.joinedAt)}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(roleIcon, size: 16, color: roleColor),
            const SizedBox(width: 4),
            Text(
              roleLabel,
              style: textTheme.labelSmall?.copyWith(color: roleColor),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays < 1) return 'hoy';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';
    if (diff.inDays < 30) return 'hace ${diff.inDays ~/ 7} sem';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
