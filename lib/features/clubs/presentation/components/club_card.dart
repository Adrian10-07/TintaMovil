import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../../data/services/club_notification_service.dart';

/// Tarjeta visual para un club en el listado.
///
/// Muestra un badge de "nuevo mensaje" si el club tiene unread.
/// Usa [RepaintBoundary] para aislar repaint del card individual.
class ClubCard extends StatelessWidget {
  final Club club;
  final ClubRole? memberRole;
  final VoidCallback? onTap;

  const ClubCard({
    super.key,
    required this.club,
    this.memberRole,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar: badge de unread solo si es miembro.
                _Avatar(
                  club: club,
                  showBadge: memberRole != null,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(club.name, style: textTheme.titleSmall,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        if (club.isPrivate)
                          Icon(Icons.lock_rounded, size: 14,
                              color: colorScheme.onSurfaceVariant),
                      ]),
                      if (club.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(club.description,
                            style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.group_rounded, size: 14,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${club.memberCount}',
                            style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
                        if (memberRole != null) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(memberRole!.name,
                                style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer)),
                          ),
                        ],
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar del club con indicador de mensaje no leído.
class _Avatar extends StatelessWidget {
  final Club club;
  final bool showBadge;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _Avatar({
    required this.club,
    required this.showBadge,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    // Sin badge → solo el avatar, sin listener.
    if (!showBadge) {
      return _buildAvatar(false);
    }
    return ListenableBuilder(
      listenable: sl<ClubNotificationService>(),
      builder: (_, __) {
        final hasUnread = sl<ClubNotificationService>().hasUnread(club.id);
        return _buildAvatar(hasUnread);
      },
    );
  }

  Widget _buildAvatar(bool hasUnread) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            club.name.isNotEmpty ? club.name[0].toUpperCase() : '?',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (hasUnread)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: colorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}