import 'package:flutter/material.dart';
import '../../domain/entities/club_member.dart';

/// Tile de miembro con acciones de admin (expulsar).
class MemberListTile extends StatelessWidget {
  final ClubMember member;
  final bool canManage;
  final VoidCallback? onRemove;

  const MemberListTile({
    super.key,
    required this.member,
    this.canManage = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (IconData roleIcon, Color roleColor, String roleLabel) = switch (member.role) {
      ClubRole.owner => (Icons.star_rounded, colorScheme.tertiary, 'Admin'),
      ClubRole.moderator => (Icons.shield_rounded, colorScheme.secondary, 'Mod'),
      ClubRole.member => (Icons.person_rounded, colorScheme.onSurfaceVariant, 'Miembro'),
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(Icons.person_rounded, color: colorScheme.onSurfaceVariant),
        ),
        title: Text(
          member.userId.length > 8 ? member.userId.substring(0, 8) : member.userId,
          style: textTheme.bodyMedium,
        ),
        subtitle: Text(
          'Se unió ${_formatDate(member.joinedAt)}',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(roleIcon, size: 14, color: roleColor),
                const SizedBox(width: 4),
                Text(roleLabel, style: textTheme.labelSmall?.copyWith(color: roleColor, fontWeight: FontWeight.w600)),
              ]),
            ),
            // Botón de expulsar (solo admin, no a sí mismo, no al owner)
            if (canManage && member.role != ClubRole.owner && onRemove != null)
              IconButton(
                icon: Icon(Icons.person_remove_rounded, size: 18, color: colorScheme.error),
                onPressed: onRemove,
                tooltip: 'Expulsar',
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
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
